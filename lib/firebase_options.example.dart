import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Key-free bootstrap template. Generate real local options with FlutterFire.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw StateError(
    'Firebase is not configured. Follow the Firebase setup in README.md and '
    'run flutterfire configure for your own project.',
  );
}
