import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../services/google_sign_in_service.dart';

class AuthRepository {
  const AuthRepository({required this.firebaseReady});

  final bool firebaseReady;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => firebaseReady ? _auth.currentUser : null;

  Stream<User?> authStateChanges() {
    if (!firebaseReady) return Stream<User?>.value(null);
    return _auth.authStateChanges();
  }

  Future<void> signIn({required String email, required String password}) async {
    _ensureFirebase();
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    _ensureFirebase();
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    _ensureFirebase();
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signInWithGoogle() async {
    _ensureFirebase();
    await GoogleSignInService.ensureInitialized();
    if (!GoogleSignInService.supportsAuthenticate()) {
      throw FirebaseAuthException(code: 'google-sign-in-unavailable');
    }

    final googleAccount = await GoogleSignInService.authenticate();
    final googleAuth = googleAccount.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(code: 'missing-google-id-token');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignInService.signOut();
    } on Exception {
      // Firebase sign-out is the source of truth for app state.
    }
    if (firebaseReady && _auth.currentUser != null) {
      await _auth.signOut();
    }
  }

  Future<void> deleteAccount() async {
    _ensureFirebase();
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await user.delete();
    try {
      await GoogleSignInService.signOut();
    } on Exception {
      // The Firebase user deletion is authoritative.
    }
  }

  void _ensureFirebase() {
    if (!firebaseReady) {
      throw FirebaseAuthException(code: 'firebase-not-configured');
    }
  }
}

bool isGoogleSignInCanceled(Object error) {
  return error is GoogleSignInException &&
      error.code == GoogleSignInExceptionCode.canceled;
}

bool isGoogleSignInConfigError(Object error) {
  return error is GoogleSignInException &&
      (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError);
}
