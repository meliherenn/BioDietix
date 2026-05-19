import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  GoogleSignInService._();

  static Future<void>? _initialization;

  static Future<void> ensureInitialized() {
    _initialization ??= GoogleSignIn.instance.initialize();
    return _initialization!;
  }

  static Future<GoogleSignInAccount> authenticate() async {
    await ensureInitialized();
    return GoogleSignIn.instance.authenticate();
  }

  static bool supportsAuthenticate() {
    return GoogleSignIn.instance.supportsAuthenticate();
  }

  static Future<void> signOut() async {
    await ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }
}
