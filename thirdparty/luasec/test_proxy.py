#!/usr/bin/env python3
"""Loopback integration tests for the staged LuaSocket/LuaSec CONNECT patches.

Run from the repository root, pointing at a native KOReader build directory:
    KOREADER_BUILD=/path/to/native/build
    LUA="$KOREADER_BUILD/luajit" \\
        LUA_PATH="$KOREADER_BUILD/common/?.lua;;" \\
        LUA_CPATH="$KOREADER_BUILD/common/?.so;;" \\
        python3 thirdparty/luasec/test_proxy.py
Requires Python 3, openssl and luajit (override with LUA). No Internet or credentials
are used. TLS certificates and keys are generated in a temporary directory.
"""
import base64
import os
from pathlib import Path
import select
import socket
import socketserver
import ssl
import subprocess
import tempfile
import threading
import unittest


def read_headers(conn):
    data = bytearray()
    while not data.endswith(b'\r\n\r\n'):
        chunk = conn.recv(1)
        if not chunk:
            raise EOFError('connection closed during headers')
        data.extend(chunk)
        if len(data) > 100000:
            raise ValueError('oversized test request')
    return bytes(data)


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

    def handle_error(self, request, client_address):
        # TLS rejection and early EOF are intentional negative-test outcomes.
        pass


class ProxyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.cert = Path(cls.tmp.name) / 'ca.pem'
        cls.key = Path(cls.tmp.name) / 'key.pem'
        subprocess.run(['openssl', 'req', '-x509', '-newkey', 'rsa:2048',
                        '-nodes', '-days', '1', '-subj', '/CN=localhost',
                        '-addext', 'subjectAltName=DNS:localhost,DNS:other.localhost',
                        '-keyout', str(cls.key), '-out', str(cls.cert)],
                       check=True, capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def setUp(self):
        self.requests = []
        self.connects = []
        self.sni = []
        self.proxy_reply = b'HTTP/1.1 200 Connection established\r\n\r\n'
        self.context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        self.context.load_cert_chain(self.cert, self.key)
        self.context.set_servername_callback(lambda sock, name, ctx: self.sni.append(name))
        test = self

        class Origin(socketserver.BaseRequestHandler):
            def handle(self):
                with test.context.wrap_socket(self.request, server_side=True) as conn:
                    headers = read_headers(conn)
                    length = 0
                    for line in headers.split(b'\r\n')[1:]:
                        if line.lower().startswith(b'content-length:'):
                            length = int(line.split(b':', 1)[1])
                    body = b''
                    while len(body) < length:
                        body += conn.recv(length - len(body))
                    test.requests.append((headers, body))
                    if headers.startswith(b'GET /redirect '):
                        conn.sendall(b'HTTP/1.1 302 Found\r\nLocation: https://other.localhost:8443/final\r\nContent-Length: 0\r\n\r\n')
                    else:
                        conn.sendall(b'HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok')

        self.origin = Server(('127.0.0.1', 0), Origin)

        class Proxy(socketserver.BaseRequestHandler):
            def handle(self):
                conn = self.request
                headers = read_headers(conn)
                test.connects.append(headers)
                if not headers.startswith(b'CONNECT '):
                    conn.sendall(b'HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok')
                    return
                conn.sendall(test.proxy_reply)
                if not test.proxy_reply.startswith((b'HTTP/1.1 200 ', b'HTTP/1.1 201 ')):
                    return
                with socket.create_connection(test.origin.server_address) as upstream:
                    while True:
                        ready, _, _ = select.select([conn, upstream], [], [], 5)
                        if not ready:
                            return
                        for source in ready:
                            data = source.recv(65536)
                            if not data:
                                return
                            (upstream if source is conn else conn).sendall(data)

        self.proxy = Server(('127.0.0.1', 0), Proxy)
        for server in (self.origin, self.proxy):
            threading.Thread(target=server.serve_forever, daemon=True).start()
            self.addCleanup(server.server_close)
            self.addCleanup(server.shutdown)

    def lua(self, code, trusted=True):
        prefix = '''
local http = require('socket.http')
local https = require('ssl.https')
local ssl = require('ssl')
local ltn12 = require('ltn12')
local socket = require('socket')
local connections = {}
local tcp = socket.tcp
socket.tcp = function(...)
    local c,e = tcp(...)
    if c then connections[#connections+1] = c end
    return c,e
end
local wrap = ssl.wrap
ssl.wrap = function(...)
    local c,e = wrap(...)
    if c then connections[#connections+1] = c end
    return c,e
end
http.TIMEOUT = 2
https.TIMEOUT = 2
'''
        if trusted:
            prefix += 'ssl.set_system_ca(%r)\n' % str(self.cert)
        prefix += "local proxy = 'http://127.0.0.1:%d'\n" % self.proxy.server_address[1]
        prefix += "local direct = 'https://localhost:%d/'\n" % self.origin.server_address[1]
        code += "\nfor _,c in ipairs(connections) do assert(c:getfd()==-1, 'connection leaked') end"
        result = subprocess.run([os.environ.get('LUA', 'luajit'), '-e', prefix + code],
                                text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_http_global_proxy(self):
        self.lua("http.PROXY=proxy; local b,c=http.request('https://localhost/path?q=1'); assert(b=='ok' and c==200)")
        self.assertTrue(self.connects[0].startswith(b'CONNECT localhost:443 HTTP/1.1\r\n'))
        self.assertTrue(self.requests[0][0].startswith(b'GET /path?q=1 HTTP/1.1\r\n'))
        self.assertEqual(self.sni, ['localhost'])

    def test_https_string_return_and_post(self):
        self.lua("http.PROXY=proxy; local b,c=https.request('https://localhost/form', 'a=1'); assert(b=='ok' and c==200)")
        self.assertEqual(self.requests[0][1], b'a=1')
        self.assertTrue(self.requests[0][0].startswith(b'POST /form '))

    def test_https_table_return(self):
        self.lua("local t={}; local r,c=https.request{url='https://localhost/',proxy=proxy,sink=ltn12.sink.table(t)}; assert(r==1 and c==200 and table.concat(t)=='ok')")

    def test_request_proxy_overrides_global(self):
        self.lua("http.PROXY='http://127.0.0.1:1'; local r,c=http.request{url='https://localhost:8443/',proxy=proxy}; assert(r==1 and c==200); assert(http.PROXY=='http://127.0.0.1:1')")
        self.assertTrue(self.connects[0].startswith(b'CONNECT localhost:8443 '))

    def test_proxy_auth_stays_out_of_origin(self):
        self.lua("proxy=proxy:gsub('http://',function() return 'http://user%40name:p%3Ass@' end); local r,c=http.request{url='https://localhost/',proxy=proxy}; assert(r==1 and c==200)")
        token = base64.b64encode(b'user@name:p:ss')
        self.assertIn(b'Proxy-Authorization: Basic ' + token, self.connects[0])
        self.assertNotIn(b'proxy-authorization', self.requests[0][0].lower())
        self.assertNotIn(token, self.requests[0][0])

    def test_explicit_proxy_auth_stays_out_of_origin(self):
        self.lua("local r,c=http.request{url='https://localhost/',proxy=proxy,headers={['Proxy-Authorization']='Basic test-token'}}; assert(r==1 and c==200)")
        self.assertIn(b'Proxy-Authorization: Basic test-token', self.connects[0])
        self.assertNotIn(b'proxy-authorization', self.requests[0][0].lower())

    def test_malformed_proxy_no_direct_fallback(self):
        self.lua("http.PROXY=''; local b,e=https.request(direct); assert(b==nil and e=='unsupported HTTPS proxy', tostring(e))")
        self.assertEqual(self.requests, [])

    def test_timeout(self):
        self.proxy_reply = b'HTTP/1.1 200 OK\r\n'
        self.lua("http.PROXY=proxy; local b,e=https.request('https://localhost/'); assert(b==nil and e=='timeout', tostring(e))")
        self.assertEqual(self.requests, [])

    def test_redirect_rebuilds_tunnel_and_sni(self):
        self.lua("http.PROXY=proxy; local b,c=http.request('https://localhost/redirect'); assert(b=='ok' and c==200)")
        self.assertEqual(self.sni, ['localhost', 'other.localhost'])
        self.assertTrue(self.connects[1].startswith(b'CONNECT other.localhost:8443 '))
        self.assertTrue(self.requests[1][0].startswith(b'GET /final '))

    def test_direct_https(self):
        self.lua("local b,c=https.request(direct); assert(b=='ok' and c==200)")
        self.assertEqual(self.connects, [])

    def test_plain_http_proxy_unchanged(self):
        self.lua("http.PROXY=proxy; local b,c=http.request('http://example.invalid/path'); assert(b=='ok' and c==200)")
        self.assertTrue(self.connects[0].startswith(b'GET http://example.invalid:80/path '))
        self.assertEqual(self.requests, [])

    def test_non_200_success(self):
        self.proxy_reply = b'HTTP/1.1 201 Established\r\nX-Test: value\r\n\r\n'
        self.lua("http.PROXY=proxy; local b,c=https.request('https://localhost/'); assert(b=='ok' and c==200)")

    def test_reject_and_malformed(self):
        for reply in (b'HTTP/1.1 407 Authentication required\r\n\r\n', b'not HTTP\r\n', b'HTTP/1.1 2000 bad\r\n'):
            self.proxy_reply = reply
            self.lua("http.PROXY=proxy; local b,e=https.request('https://localhost/'); assert(b==nil and e=='proxy CONNECT failed', tostring(e))")
        self.assertEqual(self.requests, [])

    def test_truncated_headers(self):
        self.proxy_reply = b'HTTP/1.1 200 OK\r\nX-Truncated: yes\r\n'
        self.lua("http.PROXY=proxy; local b,e=https.request('https://localhost/'); assert(b==nil and e)")
        self.assertEqual(self.requests, [])

    def test_oversized_headers(self):
        self.proxy_reply = b'HTTP/1.1 200 OK\r\nX-Large: ' + b'x' * 65536 + b'\r\n\r\n'
        self.lua("http.PROXY=proxy; local b,e=https.request('https://localhost/'); assert(b==nil and e=='proxy CONNECT headers too large', tostring(e))")
        self.assertEqual(self.requests, [])

    def test_untrusted_certificate_rejected(self):
        self.lua("http.PROXY=proxy; local b,e=https.request('https://localhost/'); assert(b==nil and e)", trusted=False)
        self.assertEqual(self.requests, [])

    def test_hostname_mismatch_rejected(self):
        self.lua("http.PROXY=proxy; local b,e=https.request('https://wrong.invalid/'); assert(b==nil and e=='hostname does not match certificate', tostring(e))")
        self.assertEqual(self.requests, [])

    def test_unsupported_proxy_scheme(self):
        self.lua("http.PROXY=proxy:gsub('http:', 'https:'); local b,e=https.request('https://localhost/'); assert(b==nil and e=='unsupported HTTPS proxy', tostring(e))")
        self.assertEqual(self.connects, [])

    def test_ipv6_authority(self):
        self.lua("http.PROXY=proxy; local b,e=https.request('https://[::1]:8443/'); assert(b==nil and e=='hostname does not match certificate', tostring(e))")
        self.assertTrue(self.connects[0].startswith(b'CONNECT [::1]:8443 '))

    def test_explicit_ca_file(self):
        self.lua("local r,c=https.request{url='https://localhost/',proxy=proxy,cafile=" + repr(str(self.cert)) + ",verify='peer'}; assert(r==1 and c==200)", trusted=False)

    def test_proxy_connection_failure(self):
        self.lua("http.PROXY='http://127.0.0.1:1'; local b,e=https.request('https://localhost/'); assert(b==nil and e)")
        self.assertEqual(self.connects, [])

    def test_proxy_auth_header_injection_rejected(self):
        self.lua("local b,e=http.request{url='https://localhost/',proxy=proxy,headers={['Proxy-Authorization']='Basic token\\r\\nX-Injected: yes'}}; assert(b==nil and e=='invalid proxy authorization', tostring(e))")
        self.assertEqual(self.requests, [])

    def test_existing_restrictions(self):
        self.lua("http.PROXY=proxy; local b,e=https.request{url='https://localhost/',redirect=true}; assert(b==nil and e=='redirect not supported'); b,e=https.request{url='https://localhost/',create=function()end}; assert(b==nil and e=='create function not permitted')")
        self.assertEqual(self.connects, [])


if __name__ == '__main__':
    unittest.main(verbosity=2)
