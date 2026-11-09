import http.server
import json
import urllib.request
import urllib.parse
import subprocess
import os
import sys
import time
import re
import shutil
import threading

PORT = 8080
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIRECTORY = os.path.join(BASE_DIR, 'build', 'web')
DART_BIN = shutil.which('dart') or '/Users/suraj/development/flutter/bin/dart' or 'dart'
RESOLVER_SCRIPT = os.path.join(BASE_DIR, 'scripts', 'resolve_yt_audio.dart')

STREAM_CACHE = {}
YT_SEARCH_CACHE = {}
CACHE_LOCK = threading.Lock()
YT_KEY = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30'
YT_HEADERS = {
    'Content-Type': 'application/json',
    'Origin': 'https://music.youtube.com',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0'
}

def query_innertube(query_str, timeout=15):
    url = f'https://music.youtube.com/youtubei/v1/search?alt=json&key={YT_KEY}'
    body = json.dumps({
        'context': {'client': {'clientName': 'WEB_REMIX', 'clientVersion': '1.20261024.01.00'}, 'user': {}},
        'query': query_str,
        'params': 'EgWKAQIIAWoMEA4QChADEAQQCRAF'
    }).encode('utf-8')
    req = urllib.request.Request(url, data=body, headers=YT_HEADERS)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read()

def has_search_items(raw_bytes):
    try:
        data = json.loads(raw_bytes.decode('utf-8', errors='ignore'))
        tabs = data.get('contents', {}).get('tabbedSearchResultsRenderer', {}).get('tabs', [])
        secs = tabs[0].get('tabRenderer', {}).get('content', {}).get('sectionListRenderer', {}).get('contents', []) if tabs else []
        for s in secs:
            if s.get('musicCardShelfRenderer'):
                return True
            shelf = s.get('musicShelfRenderer')
            if shelf and shelf.get('contents'):
                return True
    except Exception:
        pass
    return False

class JumboHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, HEAD, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Origin, User-Agent, X-Requested-With')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_HEAD(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == '/api/youtube-stream':
            vid = urllib.parse.parse_qs(parsed.query).get('id', [''])[0]
            with CACHE_LOCK:
                stream_url = STREAM_CACHE.get(vid)
            if stream_url:
                try:
                    req = urllib.request.Request(stream_url, headers={'User-Agent': YT_HEADERS['User-Agent']})
                    with urllib.request.urlopen(req, timeout=10) as resp:
                        self.send_response(resp.status)
                        self.send_header('Content-Type', resp.headers.get('Content-Type', 'audio/webm'))
                        self.send_header('Accept-Ranges', 'bytes')
                        for h in ('Content-Length', 'Content-Range'):
                            if resp.headers.get(h):
                                self.send_header(h, resp.headers.get(h))
                        self.end_headers()
                        return
                except Exception:
                    pass
            self.send_response(200)
            self.send_header('Content-Type', 'audio/webm')
            self.send_header('Accept-Ranges', 'bytes')
            self.end_headers()
            return
        super().do_HEAD()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == '/api/youtube-search':
            q = urllib.parse.parse_qs(parsed.query).get('q', [''])[0].strip()
            if not q:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(b'{"error": "Missing query"}')
                return

            cache_key = q.lower()
            now = time.time()
            with CACHE_LOCK:
                cached = YT_SEARCH_CACHE.get(cache_key)
                if cached and now - cached[1] < 600:
                    cached_data = cached[0]
                else:
                    cached_data = None

            if cached_data:
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                try:
                    self.wfile.write(cached_data)
                except (BrokenPipeError, ConnectionResetError):
                    pass
                return

            data = None
            last_err = None
            for attempt in range(2):
                try:
                    data = query_innertube(q)
                    if not has_search_items(data) and re.search(r'\s+by\s+', q, flags=re.I):
                        cleaned_q = re.sub(r'\s+by\s+', ' ', q, flags=re.I).strip()
                        if cleaned_q and cleaned_q.lower() != q.lower():
                            fallback = query_innertube(cleaned_q)
                            if has_search_items(fallback):
                                data = fallback
                    break
                except Exception as e:
                    last_err = e
                    if attempt == 0:
                        time.sleep(0.3)

            if data is not None:
                with CACHE_LOCK:
                    if len(YT_SEARCH_CACHE) > 100:
                        YT_SEARCH_CACHE.pop(next(iter(YT_SEARCH_CACHE)))
                    YT_SEARCH_CACHE[cache_key] = (data, now)
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                try:
                    self.wfile.write(data)
                except (BrokenPipeError, ConnectionResetError):
                    pass
                return
            else:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                try:
                    self.wfile.write(json.dumps({'error': str(last_err)}).encode('utf-8'))
                except (BrokenPipeError, ConnectionResetError):
                    pass
                return

        elif parsed.path == '/api/youtube-stream':
            vid = urllib.parse.parse_qs(parsed.query).get('id', [''])[0]
            if not vid:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(b'{"error": "Missing video id"}')
                return

            with CACHE_LOCK:
                stream_url = STREAM_CACHE.get(vid)

            if not stream_url:
                try:
                    out = subprocess.check_output(
                        [DART_BIN, RESOLVER_SCRIPT, vid],
                        timeout=15
                    ).decode('utf-8').strip()
                    lines = [l.strip() for l in out.splitlines() if l.strip().startswith('http')]
                    if lines:
                        stream_url = lines[-1]
                        with CACHE_LOCK:
                            STREAM_CACHE[vid] = stream_url
                    else:
                        self.send_response(500)
                        self.send_header('Content-Type', 'application/json')
                        self.end_headers()
                        self.wfile.write(json.dumps({'error': out}).encode('utf-8'))
                        return
                except Exception as e:
                    self.send_response(500)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'error': str(e)}).encode('utf-8'))
                    return

            try:
                headers = {'User-Agent': YT_HEADERS['User-Agent']}
                client_range = self.headers.get('Range')
                if client_range:
                    headers['Range'] = client_range

                req = urllib.request.Request(stream_url, headers=headers)
                with urllib.request.urlopen(req, timeout=15) as resp:
                    self.send_response(resp.status)
                    self.send_header('Content-Type', resp.headers.get('Content-Type', 'audio/webm'))
                    self.send_header('Accept-Ranges', 'bytes')
                    for h in ('Content-Length', 'Content-Range'):
                        if resp.headers.get(h):
                            self.send_header(h, resp.headers.get(h))
                    self.end_headers()
                    while True:
                        chunk = resp.read(64 * 1024)
                        if not chunk:
                            break
                        self.wfile.write(chunk)
                    return
            except (BrokenPipeError, ConnectionResetError):
                return
            except urllib.error.HTTPError as he:
                if he.code in (403, 410):
                    with CACHE_LOCK:
                        STREAM_CACHE.pop(vid, None)
                self.send_response(he.code)
                self.end_headers()
                return
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': str(e)}).encode('utf-8'))
                return

        return super().do_GET()

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path.startswith('/api/yt/'):
            subpath = parsed.path.replace('/api/yt/', '')
            length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(length) if length > 0 else b''
            try:
                target_url = f'https://music.youtube.com/youtubei/{subpath}?{parsed.query}'
                req = urllib.request.Request(target_url, data=body, headers=YT_HEADERS)
                with urllib.request.urlopen(req, timeout=12) as resp:
                    data = resp.read()
                    self.send_response(resp.status)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    try:
                        self.wfile.write(data)
                    except (BrokenPipeError, ConnectionResetError):
                        pass
                    return
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                try:
                    self.wfile.write(json.dumps({'error': str(e)}).encode('utf-8'))
                except (BrokenPipeError, ConnectionResetError):
                    pass
                return

        return super().do_POST()

if __name__ == '__main__':
    with http.server.ThreadingHTTPServer(('', PORT), JumboHandler) as httpd:
        print(f"Jumbo Music local server running at http://localhost:{PORT}")
        httpd.serve_forever()
