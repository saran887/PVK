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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBB1wLlRHHNsQ2SxhkqJ5iucIwlRBlX9uI',
    appId: '1:579969147946:web:ce225cd4741afa7c28cf53',
    messagingSenderId: '579969147946',
    projectId: 'flutter-65992',
    authDomain: 'flutter-65992.firebaseapp.com',
    storageBucket: 'flutter-65992.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA0l2kkrMmAxkLH-sg43D7stmfcyrWkTJc',
    appId: '1:579969147946:android:361429beeaa316da28cf53',
    messagingSenderId: '579969147946',
    projectId: 'flutter-65992',
    storageBucket: 'flutter-65992.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCT5CaWzEi3JOvXc382AQLF6En3QdEBAZ4',
    appId: '1:579969147946:ios:19c0f4b629a6f41128cf53',
    messagingSenderId: '579969147946',
    projectId: 'flutter-65992',
    storageBucket: 'flutter-65992.firebasestorage.app',
    iosBundleId: 'com.example.pkv2',
  );
}
