import 'web_download_helper_stub.dart'
    if (dart.library.js_interop) 'web_download_helper_web.dart' as helper;

void triggerBrowserDownload(String url, String filename) {
  helper.triggerBrowserDownload(url, filename);
}
