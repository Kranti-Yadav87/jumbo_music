import 'dart:js_interop';
import 'crash_reporting_service.dart';

@JS('triggerPwaInstall')
external JSPromise<JSBoolean> _triggerPwaInstall();

@JS('canInstallPwa')
external JSBoolean _canInstallPwa();

@JS('jumboDownloadUrl')
external void _jumboDownloadUrl(JSString url);

Future<bool> triggerPwaInstall() async {
  try {
    final result = await _triggerPwaInstall().toDart;
    return result.toDart;
  } catch (_) {
    return false;
  }
}

bool canInstallPwa() {
  try {
    return _canInstallPwa().toDart;
  } catch (_) {
    return false;
  }
}

void downloadFile(String url) {
  try {
    _jumboDownloadUrl(url.toJS);
  } catch (error) {
    CrashReportingService.swallow(error, 'pwa_install_helper_web.dart:32');
  }
}
