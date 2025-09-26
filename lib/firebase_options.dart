import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvjhyY07LAAQEJbeurwlPv4nxN2ZQ0flo',
    appId: '1:111772119339:android:9f4f9101dca79134e0956e',
    messagingSenderId: '111772119339',
    projectId: 'cargo-flow-72e58',
    storageBucket: 'cargo-flow-72e58.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDvjhyY07LAAQEJbeurwlPv4nxN2ZQ0flo',
    appId: '1:111772119339:ios:9f4f9101dca79134e0956e', // Placeholder, update with actual iOS app ID
    messagingSenderId: '111772119339',
    projectId: 'cargo-flow-72e58',
    storageBucket: 'cargo-flow-72e58.firebasestorage.app',
    iosBundleId: 'com.Ahmedriad.cargoflow', // Assuming same as Android package
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDvjhyY07LAAQEJbeurwlPv4nxN2ZQ0flo',
    appId: '1:111772119339:web:9f4f9101dca79134e0956e', // Placeholder, update with actual web app ID
    messagingSenderId: '111772119339',
    projectId: 'cargo-flow-72e58',
    storageBucket: 'cargo-flow-72e58.firebasestorage.app',
  );
}
