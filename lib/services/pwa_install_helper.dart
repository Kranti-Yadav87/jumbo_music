import 'pwa_install_helper_stub.dart'
    if (dart.library.js_interop) 'pwa_install_helper_web.dart' as helper;

Future<bool> triggerPwaInstall() => helper.triggerPwaInstall();
bool canInstallPwa() => helper.canInstallPwa();
