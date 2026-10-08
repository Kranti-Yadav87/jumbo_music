import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'presence_service.dart';

class PrivacySecurityService extends ChangeNotifier {
  static final PrivacySecurityService _instance =
      PrivacySecurityService._internal();
  factory PrivacySecurityService() => _instance;

  PrivacySecurityService._internal() {
    _isIncognitoMode =
        DatabaseService.instance.getSetting('incognitoMode', false) as bool;
    _biometricLockEnabled =
        DatabaseService.instance.getSetting('biometricLock', false) as bool;
  }

  bool _isIncognitoMode = false;
  bool _analyticsEnabled = false;
  final bool _localVaultEncrypted = true;
  bool _biometricLockEnabled = false;

  bool get isIncognitoMode => _isIncognitoMode;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get localVaultEncrypted => _localVaultEncrypted;
  bool get biometricLockEnabled => _biometricLockEnabled;

  void toggleIncognitoMode() {
    _isIncognitoMode = !_isIncognitoMode;
    DatabaseService.instance.updateSetting('incognitoMode', _isIncognitoMode);
    if (_isIncognitoMode) {
      PresenceService.instance.updateListeningStatus(
        isPlaying: false,
        isIncognito: true,
      );
    }
    notifyListeners();
  }

  void toggleAnalytics() {
    _analyticsEnabled = !_analyticsEnabled;
    DatabaseService.instance.updateSetting(
      'analyticsEnabled',
      _analyticsEnabled,
    );
    notifyListeners();
  }

  void toggleBiometricLock() {
    _biometricLockEnabled = !_biometricLockEnabled;
    DatabaseService.instance.updateSetting(
      'biometricLock',
      _biometricLockEnabled,
    );
    notifyListeners();
  }

  String exportUserDataAsJson({
    required List<String> favoriteIds,
    required List<String> downloadedSongIds,
    required int playlistCount,
  }) {
    final data = {
      'app': 'Jumbo Music',
      'version': '2.0.0',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'privacy_guarantee':
          'Zero-knowledge client storage. No listening habits or audio data sold or shared.',
      'user_data': {
        'favorites_count': favoriteIds.length,
        'favorite_song_ids': favoriteIds,
        'downloaded_count': downloadedSongIds.length,
        'downloaded_ids': downloadedSongIds,
        'custom_playlists_count': playlistCount,
        'incognito_mode_active': _isIncognitoMode,
        'vault_encrypted': _localVaultEncrypted,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
