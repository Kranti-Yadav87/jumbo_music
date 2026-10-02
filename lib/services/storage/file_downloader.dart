// Picks the real (dart:io) implementation on mobile/desktop and a stub on web.
export 'downloaded_file.dart';
export 'file_downloader_stub.dart'
    if (dart.library.io) 'file_downloader_io.dart';
