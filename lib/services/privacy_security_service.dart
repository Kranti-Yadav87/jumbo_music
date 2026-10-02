import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PrivacySecurityService extends ChangeNotifier {
  static final PrivacySecurityService _instance =
      PrivacySecurityService._internal();
  factory PrivacySecurityService() => _instance;

  PrivacySecurityService._internal();

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
    notifyListeners();
  }

  void toggleAnalytics() {
    _analyticsEnabled = !_analyticsEnabled;
    notifyListeners();
  }

  void toggleBiometricLock() {
    _biometricLockEnabled = !_biometricLockEnabled;
    notifyListeners();
  }

  String exportUserDataAsJson({
    required List<String> favoriteIds,
    required List<String> downloadedSongIds,
    required int playlistCount,
  }) {
    final data = {
      'app': 'Jumbo Music',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'privacy_policy':
          'Zero-knowledge client storage. No data shared with third parties.',
      'user_data': {
        'favorites_count': favoriteIds.length,
        'favorite_song_ids': favoriteIds,
        'downloaded_count': downloadedSongIds.length,
        'downloaded_ids': downloadedSongIds,
        'custom_playlists_count': playlistCount,
        'incognito_mode_active': _isIncognitoMode,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
