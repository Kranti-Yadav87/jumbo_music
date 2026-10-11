import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BatteryOptimizationService extends ChangeNotifier {
  static final BatteryOptimizationService instance =
      BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => instance;
  BatteryOptimizationService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.jumbomusic.app/battery_optimization',
  );

  bool _isOptimizationIgnored = true;
  bool get isOptimizationIgnored => _isOptimizationIgnored;

  bool _hasChecked = false;
  bool get hasChecked => _hasChecked;

  // Mock override for unit testing
  static bool? mockIsIgnored;

  /// Checks if Android system is exempting Jumbo Music from Doze & battery killer
  Future<bool> checkOptimizationStatus() async {
    if (mockIsIgnored != null) {
      _isOptimizationIgnored = mockIsIgnored!;
      _hasChecked = true;
      notifyListeners();
      return _isOptimizationIgnored;
    }

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _isOptimizationIgnored = true;
      _hasChecked = true;
      return true;
    }

    try {
      final res = await _channel.invokeMethod<bool>(
        'isBatteryOptimizationIgnored',
      );
      _isOptimizationIgnored = res ?? false;
    } catch (_) {
      try {
        _isOptimizationIgnored =
            await Permission.ignoreBatteryOptimizations.isGranted;
      } catch (_) {
        _isOptimizationIgnored = true;
      }
    }

    _hasChecked = true;
    notifyListeners();
    return _isOptimizationIgnored;
  }

  /// Triggers the Android system dialog to allow unrestricted background playback
  Future<bool> requestIgnoreBatteryOptimization() async {
    if (mockIsIgnored != null) {
      _isOptimizationIgnored = true;
      notifyListeners();
      return true;
    }

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final res = await _channel.invokeMethod<bool>(
        'requestIgnoreBatteryOptimization',
      );
      if (res == true) {
        // Re-check after a brief pause for user interaction
        await Future.delayed(const Duration(milliseconds: 600));
        await checkOptimizationStatus();
        return _isOptimizationIgnored;
      }
    } catch (_) {
      try {
        final status = await Permission.ignoreBatteryOptimizations.request();
        _isOptimizationIgnored = status.isGranted;
        notifyListeners();
        return _isOptimizationIgnored;
      } catch (_) {}
    }

    return false;
  }
}
