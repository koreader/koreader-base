#include <archive.h>
#include <archive_entry.h>

#include <lzma.h>

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>


static void _archive_error(struct archive *archive) {
    const char *err = archive_error_string(archive);
    fprintf(stderr, "ERROR: %s\n", err ? err : "Unknown error");
}

static int _gzip_size(struct archive *archive, const char *path, la_int64_t *ps) {
    uint32_t size;
    int      err;
    int      fd;

    err = ARCHIVE_FAILED;

    fd = open(path, O_RDONLY);
    if (fd < 0) {
        archive_set_error(archive, ARCHIVE_FAILED, "%s", strerror(errno));
        goto end;
    }

    if (lseek(fd, -4, SEEK_END) <= 0 || read(fd, &size, 4) != 4) {
        archive_set_error(archive, ARCHIVE_FAILED, "Failed to read GZIP footer");
        goto end;
    }

    *ps = size;
    err = ARCHIVE_OK;

end:
    if (fd != -1)
        close(fd);

    return err;
}

static int _xz_size(struct archive *archive, const char *path, la_int64_t *ps) {
    uint8_t            stream_footer[LZMA_STREAM_HEADER_SIZE];
    lzma_stream_flags  stream_flags;
    uint8_t           *index_buf;
    lzma_index        *index;
    int                err;
    int                fd;

    index = NULL;
    index_buf = NULL;
    err = ARCHIVE_FAILED;

    fd = open(path, O_RDONLY);
    if (fd < 0) {
        archive_set_error(archive, ARCHIVE_FAILED, "%s", strerror(errno));
        goto end;
    }

    if (lseek(fd, -LZMA_STREAM_HEADER_SIZE, SEEK_END) <= 0 ||
        read(fd, stream_footer, LZMA_STREAM_HEADER_SIZE) != LZMA_STREAM_HEADER_SIZE ||
        lzma_stream_footer_decode(&stream_flags, stream_footer) != LZMA_OK) {
        archive_set_error(archive, ARCHIVE_FAILED, "Failed to read XZ footer");
        goto end;
    }

    index_buf = malloc(stream_flags.backward_size);
    if (!index_buf) {
        archive_set_error(archive, ARCHIVE_FAILED, "%s", strerror(errno));
        goto end;
    }

    {
        uint64_t memlimit = INT_MAX;
        size_t   pos = 0;

        if (lseek(fd, -LZMA_STREAM_HEADER_SIZE - stream_flags.backward_size, SEEK_END) <= 0 ||
            read(fd, index_buf, stream_flags.backward_size) != stream_flags.backward_size ||
            lzma_index_buffer_decode(&index, &memlimit, NULL, index_buf, &pos, stream_flags.backward_size) != LZMA_OK) {
            archive_set_error(archive, ARCHIVE_FAILED, "Failed to read XZ index");
            goto end;
        }
    }

    {
        lzma_index_iter index_iter;
        lzma_vli        size = 0;

        lzma_index_iter_init(&index_iter, index);
        while (!lzma_index_iter_next(&index_iter, LZMA_INDEX_ITER_NONEMPTY_BLOCK))
            size += index_iter.block.uncompressed_size;

        *ps = size;
    }

    err = ARCHIVE_OK;

end:
    if (index)
        lzma_index_end(index, NULL);
    if (index_buf)
        free(index_buf);
    if (fd != -1)
        close(fd);

    return err;
}

static int _archive_total_size(struct archive *archive, const char *path, la_int64_t *ps, struct archive_entry **pe) {
    enum {
        SIZE_FROM_FILE_SIZE,
        SIZE_FROM_GZIP_FOOTER,
        SIZE_FROM_XZ_INDEX,
    }                     mode;
    struct archive_entry *entry;
    int                   err;

    if (!path) {
        archive_set_error(archive, ARCHIVE_FAILED, "Cannot determize size of standard input");
        return ARCHIVE_FAILED;
    }

    err = archive_read_next_header(archive, &entry);
    if (err != ARCHIVE_OK)
        return err;

    switch (archive_format(archive)) {
    case ARCHIVE_FORMAT_TAR:
    case ARCHIVE_FORMAT_TAR_USTAR:
    case ARCHIVE_FORMAT_TAR_PAX_INTERCHANGE:
    case ARCHIVE_FORMAT_TAR_PAX_RESTRICTED:
    case ARCHIVE_FORMAT_TAR_GNUTAR:
        {
            switch (archive_filter_code(archive, 0)) {
            case ARCHIVE_FILTER_NONE:
                mode = SIZE_FROM_FILE_SIZE;
                break;
            case ARCHIVE_FILTER_GZIP:
                mode = SIZE_FROM_GZIP_FOOTER;
                break;
            case ARCHIVE_FILTER_XZ:
                mode = SIZE_FROM_XZ_INDEX;
                break;
            default:
                archive_set_error(archive, ARCHIVE_FAILED, "Unsupported TAR compression filter");
                return ARCHIVE_FAILED;
            }
        }
        break;
    case ARCHIVE_FORMAT_ZIP:
        mode = SIZE_FROM_FILE_SIZE;
        break;
    default:
        archive_set_error(archive, ARCHIVE_FAILED, "Unrecognized or unsupported archive format");
        return ARCHIVE_FAILED;
    }

    switch (mode) {
    case SIZE_FROM_FILE_SIZE:
        {
            struct stat st;

            if (stat(path, &st)) {
                archive_set_error(archive, ARCHIVE_FAILED, "%s", strerror(errno));
                return ARCHIVE_FAILED;
            }

            *ps = st.st_size;
        }
        break;
    case SIZE_FROM_GZIP_FOOTER:
        err = _gzip_size(archive, path, ps);
        break;
    case SIZE_FROM_XZ_INDEX:
        err = _xz_size(archive, path, ps);
        break;
    }

    *pe = entry;

    return ARCHIVE_OK;
}

static int _archive_list(struct archive *archive) {
    struct archive_entry *entry;
    int                   err;

    for (;;) {
        err = archive_read_next_header(archive, &entry);
        if (err == ARCHIVE_EOF)
            return ARCHIVE_OK;
        if (err != ARCHIVE_OK)
            return err;
        const char *path = archive_entry_pathname(entry);
        write(1, path, strlen(path));
        write(1, "\n", 1);
    }
}

struct progress_ctx {
    struct archive *archive;
    la_int64_t      progress;
    double          percent;
    double          size;
    char            size_unit;
    la_int64_t      total_size;
};

#define KILO  (1000)
#define MEGA  (KILO  * 1000)
#define GIGA  (MEGA  * 1000)

static void print_progress(struct progress_ctx *ctx, la_int64_t progress) {
    int  line_length;
    char line[16];

    if (progress == ctx->progress)
        return;
    ctx->progress = progress;

    if (ctx->total_size) {
        double percent = floor((double)progress / ctx->total_size * 100.0);

        if (percent == ctx->percent)
            return;
        ctx->percent = percent;

        line_length = snprintf(line, sizeof (line), "\r%3.0f%%", percent);
    } else {
        double size;
        char   size_unit;

        if (progress >= GIGA) {
            size = (double)progress / GIGA;
            size_unit = 'G';
        } else if (progress >= MEGA) {
            size = (double)progress / MEGA;
            size_unit = 'M';
        } else {
            size = (double)progress / KILO;
            size_unit = 'K';
        }

        if (size_unit == ctx->size_unit && (size - ctx->size) < 0.1)
            return;
        ctx->size_unit = size_unit;
        ctx->size = size;

        line_length = snprintf(line, sizeof (line), "\r%5.1f%c", size, size_unit);
    }

    write(1, line, line_length);
}

static void extract_progress(void *u) {
    struct progress_ctx *ctx = u;

    print_progress(ctx, archive_filter_bytes(ctx->archive, 0));
}

static int _archive_extract(struct archive *archive, const char *path, int progress) {
    struct progress_ctx   progress_ctx;
    struct archive       *o;
    struct archive_entry *entry;
    int                   err;

    o = archive_write_disk_new();

    if (progress) {
        progress_ctx.archive = archive;
        progress_ctx.progress = 0;
        progress_ctx.percent = -1;
        progress_ctx.size_unit = '\0';
        progress_ctx.size = 0;
        progress_ctx.total_size = 0;

        // Disable output buffering.
        setvbuf(stdout, NULL, _IONBF, 0);

        archive_read_extract_set_progress_callback(archive, extract_progress, &progress_ctx);
        if (path) {
            err = _archive_total_size(archive, path, &progress_ctx.total_size, &entry);
            if (err != ARCHIVE_OK)
                return err;
            goto direct_to_extract;
        }
    }

    for (;;) {
        err = archive_read_next_header(archive, &entry);
        if (err == ARCHIVE_EOF) {
            if (progress) {
                if (progress_ctx.total_size)
                    print_progress(&progress_ctx, progress_ctx.total_size);
                write(1, "\n", 1);
            }
            return ARCHIVE_OK;
        }
        if (err != ARCHIVE_OK)
            return err;
direct_to_extract:
        err = archive_read_extract2(archive, entry, o);
        if (err != ARCHIVE_OK)
            return err;
    }
}

static void usage(const char *arg0) {
    fprintf(stderr,
           "%s [-l|-x|-X] ARCHIVE\n"
           "\n"
           " -l   list archive contents\n"
           " -x   extract archive\n"
           " -X   extract archive with progress counter\n"
           , arg0);
}

int main(int argc, char **argv) {
    enum {
        MODE_EXTRACT,
        MODE_EXTRACT_WITH_PROGRESS,
        MODE_LIST,
    }                     mode;
    struct archive       *archive;
    const char           *path;
    int                   err;

    if (argc != 3) {
        usage(argv[0]);
        return 1;
    }

    if (0 == strcmp(argv[1], "-l"))
        mode = MODE_LIST;
    else if (0 == strcmp(argv[1], "-x"))
        mode = MODE_EXTRACT;
    else if (0 == strcmp(argv[1], "-X"))
        mode = MODE_EXTRACT_WITH_PROGRESS;
    else {
        usage(argv[0]);
        return strcmp(argv[1], "-h") ? 1 : 0;
    }

    archive = archive_read_new();
    archive_read_support_filter_gzip(archive);
    archive_read_support_filter_none(archive);
    archive_read_support_filter_xz(archive);
    archive_read_support_format_tar(archive);
    archive_read_support_format_zip(archive);

    path = strcmp(argv[2], "-") ? argv[2] : NULL;

    err = archive_read_open_filename(archive, path, 10240);
    if (err == ARCHIVE_OK) {
        switch (mode) {
        case MODE_EXTRACT:
        case MODE_EXTRACT_WITH_PROGRESS:
            err = _archive_extract(archive, path, mode == MODE_EXTRACT_WITH_PROGRESS);
            break;
        case MODE_LIST:
            err = _archive_list(archive);
            break;
        }
    }

    if (err != ARCHIVE_OK)
        _archive_error(archive);

    archive_read_close(archive);
    archive_read_free(archive);

    return err != ARCHIVE_OK ? 2 : 0;
}
