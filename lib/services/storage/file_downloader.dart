// Picks the real implementation per platform:
//  - mobile/desktop (dart:io): files in app storage
//  - web (dart:js_interop): browser Cache Storage
export 'downloaded_file.dart';
export 'file_downloader_stub.dart'
    if (dart.library.io) 'file_downloader_io.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart';
