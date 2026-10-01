// File generated for jumbo-music-ff58c Firebase configuration.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDb3z-A1yiuSJrEM2t5y8DDyjbSbdDIBMY',
    appId: '1:375294688779:web:d70c2a88e7542a8b17d10e',
    messagingSenderId: '375294688779',
    projectId: 'jumbo-music-ff58c',
    authDomain: 'jumbo-music-ff58c.firebaseapp.com',
    storageBucket: 'jumbo-music-ff58c.firebasestorage.app',
    measurementId: 'G-KW8HZ2RQJV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBkbvsBLTCg7aurTS46uwTBr4t7G-HODOw',
    appId: '1:375294688779:android:c558a013dd361ac517d10e',
    messagingSenderId: '375294688779',
    projectId: 'jumbo-music-ff58c',
    storageBucket: 'jumbo-music-ff58c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCV8cJanQ1YXAPduJO_kctGQBV9CKCmfak',
    appId: '1:375294688779:ios:2e8f8c0f301c6dbf17d10e',
    messagingSenderId: '375294688779',
    projectId: 'jumbo-music-ff58c',
    storageBucket: 'jumbo-music-ff58c.firebasestorage.app',
    iosBundleId: 'com.jumbomusic.app',
  );
}

