#!/usr/bin/env python3

from pathlib import Path
import argparse
import contextlib
import ctypes
import dataclasses
import io
import json
import os
import stat
import struct
import sys
import tempfile
import textwrap
import urllib

from tqdm import tqdm
import libarchive
import urllib3
import zstd


BLOCK_SIZE = 16 * 1024


def naturalsize(size, delta=False):
    for chunk, suffix, precision in (
        (10**9, 'GB', 1),
        (10**6, 'MB', 1),
        (10**3, 'KB', 1),
    ):
        if abs(size) >= chunk:
            break
    else:
        chunk, suffix, precision = 1, '  B ', 0
    fmt = '%'
    if delta:
        fmt += '+'
    fmt += '.*f %s'
    return fmt % (precision, size / chunk, suffix)


class XXH3:

    class State(ctypes.c_void_p): # pylint: disable=too-few-public-methods
        pass

    class Hash(ctypes.c_uint64): # pylint: disable=too-few-public-methods
        pass

    @staticmethod
    def _check_error(e):
        if e != 0:
            raise RuntimeError("xxHash error %s" % str(e))

    _lib = ctypes.cdll.LoadLibrary('libxxhash.so.0')
    _create = _lib.XXH3_createState
    _create.restype = State
    _free = _lib.XXH3_freeState
    _free.argtypes = [State]
    _free.restype = _check_error
    _digest = _lib.XXH3_64bits_digest
    _digest.argtypes = [State]
    _digest.restype = Hash
    _reset = _lib.XXH3_64bits_reset
    _reset.argtypes = [State]
    _reset.restype = _check_error
    _update = _lib.XXH3_64bits_update
    _update.argtypes = [State, ctypes.c_void_p, ctypes.c_size_t]
    _update.restype = _check_error

    _Py_buffer = ctypes.ARRAY(ctypes.c_void_p, 120 // ctypes.sizeof(ctypes.c_void_p))

    def __init__(self):
        self._buffer = XXH3._Py_buffer()
        self._state = XXH3._create()
        assert self._state is not None
        self.reset()

    def __del__(self):
        XXH3._free(self._state)

    def hexdigest(self):
        return '%016x' % XXH3._digest(self._state).value

    def update(self, b):
        ctypes.pythonapi.PyObject_GetBuffer(ctypes.py_object(b), self._buffer, 0)
        try:
            XXH3._update(self._state, self._buffer[0], len(b))
        finally:
            ctypes.pythonapi.PyBuffer_Release(self._buffer)

    def reset(self):
        XXH3._reset(self._state)


class U32(int):
    PACKFMT = 'I'

class U16(int):
    PACKFMT = 'H'


class PackClass:

    PACKCOUNT, PACKFMT, PACKSIZE, PACKEXTRAS = 0, '', 0, ()

    def pack(self):
        b = struct.pack(self.PACKFMT, *dataclasses.astuple(self)[:self.PACKCOUNT])
        for name in self.PACKEXTRAS:
            b += getattr(self, name)
        return b

    @property
    def size(self):
        s = self.PACKSIZE
        for name in self.PACKEXTRAS:
            s += len(getattr(self, name))
        return s

def packclass(cls):
    formats = [
        field.type.PACKFMT
        for field in cls.__dataclass_fields__.values()
        if field.default is dataclasses.MISSING
    ]
    cls.PACKCOUNT = len(formats)
    cls.PACKFMT = '<' + ''.join(formats)
    cls.PACKSIZE = struct.calcsize(cls.PACKFMT)
    return cls


@packclass
@dataclasses.dataclass(slots=True)
class ZipLFH(PackClass): # pylint: disable=too-many-instance-attributes

    PACKEXTRAS = ('filename', 'extra_field')

    SIGNATURE = 0x04034b50

    signature      : U32
    min_ver        : U16
    flags          : U16
    compression    : U16
    mtime          : U16
    mdate          : U16
    crc32          : U32
    packed_size    : U32
    unpacked_size  : U32
    filename_len   : U16
    extra_field_len: U16
    filename       : bytes = None
    extra_field    : bytes = None


@packclass
@dataclasses.dataclass(slots=True)
class ZipCDFH(PackClass): # pylint: disable=too-many-instance-attributes

    PACKEXTRAS = ('filename', 'extra_field', 'comment')

    SIGNATURE = 0x02014b50

    signature      : U32
    version        : U16
    min_ver        : U16
    flags          : U16
    compression    : U16
    mtime          : U16
    mdate          : U16
    crc32          : U32
    packed_size    : U32
    unpacked_size  : U32
    filename_len   : U16
    extra_field_len: U16
    comment_len    : U16
    disk_num       : U16
    internal_fattrs: U16
    external_fattrs: U32
    offset         : U32
    filename       : bytes  = None
    extra_field    : bytes  = None
    comment        : bytes  = None
    stop_offset    : int    = None


@packclass
@dataclasses.dataclass(slots=True)
class ZipEOCD(PackClass): # pylint: disable=too-many-instance-attributes

    PACKEXTRAS = ('comment',)

    SIGNATURE = 0x06054b50

    signature  : U32
    nb_disks   : U16
    disk_num   : U16
    disk_recs  : U16
    total_recs : U16
    cdir_size  : U32
    cdir_offset: U32
    comment_len: U16
    comment    : bytes = None
    offset     : int = None

    @property
    def cdir_stop_offset(self):
        return self.cdir_offset + self.cdir_size - 1


class ZipRawReader: # pylint: disable=too-many-instance-attributes

    def __init__(self, filename):
        self.filename = Path(filename)
        self.fp = None
        self.eocd = None
        self.entries = None
        self.by_path = []
        self.stream_start = None
        self.stream_offset = None
        self.stream_size = None

    def __enter__(self):
        self.fp = self.filename.open('rb')
        # End of central directory.
        eocd_offset = self.fp.seek(-ZipEOCD.PACKSIZE, os.SEEK_END)
        raw_eocd = self.fp.read(ZipEOCD.PACKSIZE)
        eocd = ZipEOCD(*struct.unpack(ZipEOCD.PACKFMT, raw_eocd), b'', eocd_offset)
        assert eocd.signature == ZipEOCD.SIGNATURE, eocd
        assert eocd.nb_disks == 0, eocd
        assert eocd.disk_num == 0, eocd
        assert eocd.disk_recs == eocd.total_recs, eocd
        assert eocd.comment_len == 0, eocd
        self.fp.seek(eocd.cdir_offset)
        # Central directory.
        raw_cdir = self.fp.read(eocd.cdir_size)
        assert len(raw_cdir) == eocd.cdir_size
        offset = 0
        cdir = []
        while offset < len(raw_cdir):
            cdfh = ZipCDFH(*struct.unpack_from(ZipCDFH.PACKFMT, raw_cdir, offset))
            assert cdfh.signature == ZipCDFH.SIGNATURE, cdfh
            offset += ZipCDFH.PACKSIZE
            cdfh.filename = raw_cdir[offset:offset+cdfh.filename_len]
            offset += cdfh.filename_len
            cdfh.extra_field = raw_cdir[offset:offset+cdfh.extra_field_len]
            offset += cdfh.extra_field_len
            cdfh.comment = raw_cdir[offset:offset+cdfh.comment_len]
            offset += cdfh.comment_len
            cdir.append(cdfh)
        assert self.fp.tell() == eocd_offset
        assert len(cdir) == eocd.disk_recs, (len(cdir), eocd)
        for n in range(len(cdir) - 1):
            cdir[n].stop_offset = cdir[n+1].offset - 1
        cdir[-1].stop_offset = eocd.cdir_offset - 1
        # Local directory.
        entries = []
        by_path = {}
        for cdfh in cdir:
            self.fp.seek(cdfh.offset)
            raw_lfh = self.fp.read(ZipLFH.PACKSIZE)
            lfh = ZipLFH(*struct.unpack(ZipLFH.PACKFMT, raw_lfh))
            lfh.filename = self.fp.read(lfh.filename_len)
            lfh.extra_field = self.fp.read(lfh.extra_field_len)
            assert lfh.min_ver == cdfh.min_ver
            assert lfh.flags == cdfh.flags, (lfh, cdfh)
            assert lfh.filename == cdfh.filename, (lfh, )
            assert ((lfh.packed_size, lfh.unpacked_size) == (cdfh.packed_size, cdfh.unpacked_size) or
                    (lfh.packed_size, lfh.unpacked_size, lfh.crc32, lfh.flags & 8) == (0, 0, 0, 8)), (lfh, cdfh)
            ze = ZipEntry(cdfh, lfh, self)
            assert ze.path not in by_path, (ze, by_path[ze.path])
            by_path[ze.path] = ze
            entries.append(ze)
        # Finalize.
        self.eocd = eocd
        self.entries = entries
        self.by_path = by_path
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.fp.close()
        self.fp = None

    def __getitem__(self, key):
        if isinstance(key, str):
            return self.by_path[key]
        return self.entries[key]

    def __iter__(self):
        assert self.fp is not None
        yield from self.entries

    def __len__(self):
        return len(self.entries)

    def get(self, key, default=None):
        return self.by_path.get(key, default)

    def hash(self, start, stop):
        xh = XXH3()
        for block in self.read_blocks_into(bytearray(BLOCK_SIZE), start, stop):
            xh.update(block)
        return xh.hexdigest()

    def hash_unpacked(self, ze):
        if ze.size == 0:
            raise ValueError(ze)
        if ze.cdfh.compression:
            # Compressed data: we can actually unpack just the one
            # entry by feeding it to a libarchive' stream reader.
            def blocks_iterator():
                with libarchive.stream_reader(self.stream(ze.zip_start, ze.zip_stop)) as archive:
                    ae = next(iter(archive), None)
                    assert ae is not None, ze
                    # Older version of python-libarchive-c may not fill in
                    # the name correctly (e.g. on Jammy)… Not sure why.
                    assert ze.path == ae.name or ae.name is None, (ze, ae.name)
                    # Note: libarchive relies on the local file header, whose unpacked
                    # size may be zero if it was not known when written (streaming
                    # compression).
                    assert ze.size == ae.size or ae.size is None, (ze, ae.size)
                    yield from ae.get_blocks()
        else:
            # Stored data.
            start = ze.cdfh.offset + ze.lfh.size
            stop = start + ze.cdfh.unpacked_size - 1
            def blocks_iterator():
                yield from self.read_blocks_into(bytearray(BLOCK_SIZE), start, stop)
        xh = XXH3()
        for block in blocks_iterator():
            xh.update(block)
        return xh.hexdigest()

    def read_blocks_into(self, buffer, start, stop):
        assert self.fp is not None
        offset = self.fp.seek(start)
        assert offset == start, (offset, start)
        left = stop - start + 1
        assert left >= 0, left
        while left:
            size = min(left, len(buffer))
            block = memoryview(buffer)[:size]
            count = self.fp.readinto(block)
            assert count == size, (count, size)
            yield block
            left -= size

    def rewrite(self, entries):
        entries = list(entries)
        if entries == self.entries:
            # No changes.
            return
        with tempfile.NamedTemporaryFile(
            delete=False,
            dir=self.filename.parent,
            suffix='.zip.part',
        ) as fp:
            tempname = fp.name
            buffer = bytearray(BLOCK_SIZE)
            # First: the entries themselves.
            for ze in entries:
                for block in self.read_blocks_into(buffer, ze.zip_start, ze.zip_stop):
                    fp.write(block)
                size = ze.zip_size
                ze.cdfh.offset = fp.tell() - size
                ze.cdfh.stop_offset = ze.cdfh.offset + size - 1
            assert fp.tell() == self.eocd.cdir_offset, (fp.tell(), self.eocd.cdir_offset)
            # Then: the updated central directory.
            for ze in entries:
                fp.write(ze.cdfh.pack())
            # And finally: the end of central directory marker.
            fp.write(self.eocd.pack())
        # Update internal state.
        self.fp.close()
        os.rename(tempname, self.filename)
        # pylint: disable=consider-using-with
        self.fp = self.filename.open('rb')
        self.entries = entries

    # Stream interface for use with `libarchive.stream_reader`.

    def stream(self, start, stop):
        assert stop >= start
        self.stream_start = start
        self.stream_offset = 0
        self.stream_size = stop - start + 1
        self.fp.seek(start)
        return self

    def readinto(self, b):
        left = min(len(b), self.stream_size - self.stream_offset)
        count = self.fp.readinto(memoryview(b)[:left])
        return count

    def seekable(self):
        return True

    def seek(self, offset, whence):
        if whence == os.SEEK_SET:
            pass
        elif whence == os.SEEK_CUR:
            offset = self.stream_offset + offset
        elif whence == os.SEEK_END:
            assert offset <= 0
            offset = self.stream_size + offset
        else:
            raise ValueError(whence)
        assert 0 <= offset <= self.stream_size, (offset, self.stream_size)
        real_offset = self.stream_start + offset
        offset = self.fp.seek(real_offset)
        assert offset == real_offset, (offset, real_offset)
        self.stream_offset = offset - self.stream_start
        return self.stream_offset

    def tell(self):
        return self.stream_offset


@dataclasses.dataclass(slots=True)
class ZipEntry:
    cdfh     : ZipCDFH
    lfh      : ZipLFH
    zrr      : ZipRawReader
    _hash    : str | None = None
    _zip_hash: str | None = None

    @property
    def path(self):
        return self.cdfh.filename.decode()

    @property
    def size(self):
        return self.cdfh.unpacked_size

    @property
    def hash(self):
        h = self._hash
        if h is None:
            h = self.zrr.hash_unpacked(self)
            self._hash = h
        return h

    @property
    def zip_start(self):
        return self.cdfh.offset

    @property
    def zip_stop(self):
        return self.cdfh.stop_offset

    @property
    def zip_hash(self):
        h = self._zip_hash
        if h is None:
            h = self.zrr.hash(self.cdfh.offset, self.cdfh.stop_offset)
            self._zip_hash = h
        return h

    @property
    def zip_size(self):
        return self.cdfh.stop_offset - self.cdfh.offset + 1


def fetch_ranges(http, url, ranges):
    merged_ranges = []
    for r in ranges:
        if merged_ranges:
            pr = merged_ranges[-1]
            assert r[0] > pr[1], (pr, r)
            if pr[1] == r[0] - 1:
                merged_ranges[-1] = (pr[0], r[1])
                continue
        merged_ranges.append(r)
    ranges = merged_ranges
    ranges = ['%u-%u' % (r[0], r[1]) for r in ranges]
    range_support_checked = False
    while ranges:
        count = 1
        range_header = 'bytes=' + ranges[0]
        r = http.request('GET', url, headers={'Range': range_header}, preload_content=False)
        # Does the server actually support range requests?
        if not range_support_checked:
            if 'bytes' not in r.headers.get('Accept-Ranges'):
                raise RuntimeError('Server does not support range requests!')
            range_support_checked = True
        if r.status != 206:
            raise urllib3.exceptions.HTTPError(r.status)
        try:
            yield from r.stream(BLOCK_SIZE)
        finally:
            r.release_conn()
        ranges = ranges[count:]


def hash_file(filename):
    buffer = bytearray(BLOCK_SIZE)
    xh = XXH3()
    with open(filename, 'rb') as fp:
        while True:
            count = fp.readinto(buffer)
            if not count:
                break
            xh.update(memoryview(buffer)[:count])
    return xh.hexdigest()


@dataclasses.dataclass
class ZipSyncEntry:
    path     : str
    size     : int
    hash     : str
    zip_start: int
    zip_stop : int
    zip_hash : str

    # Just to shut up pylint…
    new_zip_start: dataclasses.InitVar = None

    def path_matches(self, path):
        try:
            st = os.stat(path, follow_symlinks=False)
        except FileNotFoundError:
            return False
        return st.st_mode & stat.S_IFREG and st.st_size == self.size and hash_file(path) == self.hash

    @property
    def zip_size(self):
        return self.zip_stop - self.zip_start + 1

@dataclasses.dataclass(slots=True)
class ZipSyncManifest:
    filename      : str
    files         : list[ZipSyncEntry]
    zip_cdir_start: int
    zip_cdir_stop : int
    zip_cdir_hash : str

def serialize_zipsync(manifest, compression_level=19):
    d = dataclasses.asdict(manifest)
    d['files'] = [dataclasses.asdict(f) for f in manifest.files]
    # pylint: disable=c-extension-no-member
    return zstd.ZSTD_compress(json.dumps(
        d,
        separators=(',', ':'),
        sort_keys=True,
    ).encode('ascii'), compression_level, 1)

def deserialize_zipsync(data):
    # pylint: disable=c-extension-no-member
    d = json.loads(zstd.ZSTD_uncompress(data))
    d['files'] = [ZipSyncEntry(**e) for e in d['files']]
    return ZipSyncManifest(**d)

def load_zipsync(filename):
    data = Path(filename).read_bytes()
    return deserialize_zipsync(data)

def save_zipsync(filename, manifest):
    data = serialize_zipsync(manifest)
    Path(filename).write_bytes(data)

def reorder_zipsync(older_zip_or_zipsync, zip_file_or_rawreader):
    older_zip_or_zipsync = Path(older_zip_or_zipsync)
    with contextlib.ExitStack() as stack:
        if older_zip_or_zipsync.suffix == '.zipsync':
            oldz = { ze.path: ze for ze in load_zipsync(older_zip_or_zipsync).files }
        else:
            oldz = stack.enter_context(ZipRawReader(older_zip_or_zipsync))
        if isinstance(zip_file_or_rawreader, ZipRawReader):
            new_filename = zip_file_or_rawreader.filename
            newz = zip_file_or_rawreader
        else:
            new_filename = zip_file_or_rawreader
            newz = stack.enter_context(ZipRawReader(new_filename))
        entries = []
        for nze in newz:
            if nze.size:
                oze = oldz.get(nze.path)
                if oze is None or oze.size != nze.size or oze.hash != nze.hash:
                    # New/modified file.
                    sort_order = (2, nze.zip_start)
                else:
                    # Unmodified file.
                    sort_order = (1, oze.zip_start)
            else:
                # Folder.
                sort_order = (0, nze.zip_start)
            entries.append((sort_order, nze))
        # Update the zip.
        newz.rewrite(ze for __, ze in sorted(entries))


def zipsync_make(zip_path, zipsync_path=None, older_zip_or_zipsync_path=None):
    zip_path = Path(zip_path)
    if zipsync_path is None:
        zipsync_path = zip_path.with_suffix('.zipsync')
    with ZipRawReader(zip_path) as zrr:
        if older_zip_or_zipsync_path:
            reorder_zipsync(older_zip_or_zipsync_path, zrr)
        manifest = ZipSyncManifest(
            zip_path.name,
            [
                ZipSyncEntry(
                    ze.path,
                    ze.size,
                    ze.hash,
                    ze.zip_start,
                    ze.zip_stop,
                    ze.zip_hash,
                )
                for ze in zrr
                # Ignore folders.
                if ze.size != 0
            ],
            zrr.eocd.cdir_offset,
            zrr.eocd.cdir_stop_offset,
            zrr.hash(zrr.eocd.cdir_offset, zrr.eocd.cdir_stop_offset),
        )
    save_zipsync(zipsync_path, manifest)


def fetch_zipsync(zipsync_url, state_dir, http):
    url_path = urllib.parse.urlsplit(zipsync_url).path
    url_path = urllib.parse.unquote(url_path)
    zipsync_file = Path(state_dir) / Path(url_path).name
    etag_file = zipsync_file.with_suffix('.etag')
    manifest = None
    etag = None
    if zipsync_file.exists():
        try:
            manifest = load_zipsync(zipsync_file)
        # pylint: disable=c-extension-no-member
        except (OSError, zstd.Error) as e:
            print('failed loading %s: %s' % (zipsync_file, e), file=sys.stderr)
    if manifest is not None and etag_file.exists():
        etag = etag_file.read_text(encoding='ascii').strip()
    headers = {}
    if etag is not None:
        headers['If-None-Match'] = etag
    r = http.request('GET', zipsync_url, headers=headers)
    if r.status == 304:
        # 304: Not Modified.
        return manifest
    if r.status != 200:
        raise urllib3.exceptions.HTTPError(r.status)
    manifest = deserialize_zipsync(r.data)
    save_zipsync(zipsync_file, manifest)
    etag = r.headers.get('Etag')
    if etag is None:
        etag_file.unlink()
    else:
        etag_file.write_text(etag, encoding='ascii')
    return manifest


def zipsync_sync(state_dir, zipsync_url, seed=None):
    state_dir = Path(state_dir)
    if seed is not None:
        seed = Path(seed)
        assert seed.exists()
        if seed.is_dir():
            def matches(e):
                return e.path_matches(seed / e.path)
        else:
            seed = { e.path: (e.size, e.hash) for e in load_zipsync(seed).files }
            def matches(e):
                return seed.get(e.path) == (e.size, e.hash)
    http = urllib3.PoolManager()
    manifest = fetch_zipsync(zipsync_url, state_dir, http=http)
    reusing = 0
    if seed is None:
        missing = manifest.files
    else:
        missing = []
        for e in manifest.files:
            if matches(e):
                reusing += e.size
                continue
            missing.append(e)
    if not missing:
        # Nothing to update!
        return
    fetching = sum(e.zip_size for e in missing)
    print('missing : %u/%u files' % (len(missing), len(manifest.files)))
    print('reusing : %6s (%10u)' % (naturalsize(reusing), reusing))
    print('fetching: %6s (%10u)' % (naturalsize(fetching), fetching))
    cdir = ZipSyncEntry(
        None, None,
        manifest.zip_cdir_stop - manifest.zip_cdir_start + 1,
        manifest.zip_cdir_start,
        manifest.zip_cdir_stop,
        manifest.zip_cdir_hash,
    )
    assert cdir.zip_start >= len(missing) * ZipCDFH.PACKSIZE
    missing.append(cdir)
    offset = 0
    ranges = []
    for e in missing:
        e.new_zip_start = offset
        ranges.append((e.zip_start, e.zip_stop))
        offset += e.zip_size
    zip_url = urllib.parse.urljoin(zipsync_url, manifest.filename)
    xh = XXH3()
    entry_left = 0
    current = None
    fetched = []
    raw_cdir = io.BytesIO()
    raw_cdir.seek(cdir.zip_size)
    raw_cdir.seek(0)
    with contextlib.ExitStack() as stack:
        progress = tqdm(leave=True, total=fetching, unit='B', unit_divisor=1024, unit_scale=True)
        fp = stack.enter_context((state_dir / 'update.zip').open('w+b'))
        for data in fetch_ranges(http, zip_url, ranges):
            data = memoryview(data)
            while data:
                if current is None:
                    current = missing.pop(0)
                    entry_left = current.zip_size
                    offset = fp.seek(current.new_zip_start)
                    assert offset == current.new_zip_start, (offset, current)
                    xh.reset()
                count = min(entry_left, len(data))
                xh.update(data[:count])
                if current is cdir:
                    raw_cdir.write(data[:count])
                else:
                    fp.write(data[:count])
                entry_left -= count
                assert entry_left >= 0, entry_left
                if not entry_left:
                    assert current.zip_hash == xh.hexdigest(), (current, xh.hexdigest())
                    fetched.append(current)
                    current = None
                data = data[count:]
                progress.update(count)
        assert fp.seek(0, os.SEEK_END) == cdir.new_zip_start, (fp.tell(), cdir.new_zip_start)
        assert not missing, missing
        assert fetched[-1] == cdir
        fetched.pop(-1)
        # Write an updated central directory with only
        # the files we fetched (updating their offsets).
        raw_cdir.seek(0)
        updated = []
        written = 0
        while True:
            raw_cdfh = raw_cdir.read(ZipCDFH.PACKSIZE)
            if not raw_cdfh:
                break
            assert len(raw_cdfh) == ZipCDFH.PACKSIZE, len(raw_cdfh)
            cdfh = ZipCDFH(*struct.unpack(ZipCDFH.PACKFMT, raw_cdfh))
            assert cdfh.signature == ZipCDFH.SIGNATURE, cdfh
            cdfh.filename = raw_cdir.read(cdfh.filename_len)
            cdfh.extra_field = raw_cdir.read(cdfh.extra_field_len)
            cdfh.comment = raw_cdir.read(cdfh.comment_len)
            if current is None:
                if not fetched:
                    break
                current = fetched.pop(0)
            if current.zip_start == cdfh.offset:
                # One of ours!
                cdfh.offset = current.new_zip_start
                assert cdfh.filename.decode('ascii') == current.path, (cdfh, current)
                count = fp.write(cdfh.pack())
                assert count == cdfh.size, (count, cdfh.size)
                updated.append(current)
                written += count
                current = None
        assert not fetched, fetched
        # Write end of central directory.
        eocd = ZipEOCD(
            ZipEOCD.SIGNATURE,
            0, 0,
            len(updated), len(updated),
            fp.tell() - cdir.new_zip_start, cdir.new_zip_start,
            0, b'',
        )
        fp.write(eocd.pack())
    http.clear()


def main():
    parser = argparse.ArgumentParser(prog=sys.argv[0])
    subparsers = parser.add_subparsers(dest='command', title='commands')
    make_parser = subparsers.add_parser('make', formatter_class=argparse.RawTextHelpFormatter)
    make_parser.add_argument('--reorder', dest='older_zip_or_zipsync', metavar='OLDER_ZIP_OR_ZIPSYNC_FILE',
                             help=textwrap.dedent(
                                 """\
                                 will repack the new zip with this order:
                                 ┌─────────────┬──────────────────┬────────────────────┬────┬──────┐
                                 │   folders   │ unmodified files │ new/modified files │ CD │ EOCD │
                                 │ (new order) │   (old order)    │    (new order)     │    │      │
                                 └─────────────┴──────────────────┴────────────────────┴────┴──────┘
                                 """
                             ))
    make_parser.add_argument('zip', metavar='ZIP_FILE',
                             help='source ZIP file')
    make_parser.add_argument('zipsync', metavar='ZIPSYNC_FILE', nargs='?',
                             help='destination zipsync file')
    sync_parser = subparsers.add_parser('sync')
    sync_parser.add_argument('state_dir', metavar='STATE_DIR',
                             help='destination for the zipsync and update files')
    sync_parser.add_argument('zipsync_url', metavar='ZIPSYNC_URL',
                             help='URL of zipsync file')
    sync_parser.add_argument('seed', metavar='SEED_DIR_OR_ZIPSYNC_FILE', nargs='?',
                             help='optional seed directory / zsync file')
    options = parser.parse_args(sys.argv[1:])
    if options.command == 'make':
        zipsync_make(options.zip, zipsync_path=options.zipsync, older_zip_or_zipsync_path=options.older_zip_or_zipsync)
    elif options.command == 'sync':
        zipsync_sync(options.state_dir, options.zipsync_url, options.seed)


if __name__ == '__main__':
    main()
