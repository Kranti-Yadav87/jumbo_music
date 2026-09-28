import 'dart:js_interop';

@JS('triggerPwaInstall')
external JSPromise<JSBoolean> _triggerPwaInstall();

@JS('canInstallPwa')
external JSBoolean _canInstallPwa();

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
