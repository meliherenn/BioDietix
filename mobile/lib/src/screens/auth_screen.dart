import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../i18n.dart';
import '../services/google_sign_in_service.dart';
import '../widgets/ui.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.firebaseReady, super.key});

  final bool firebaseReady;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _signUp = false;
  var _busy = false;
  var _googleBusy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = AppScope.of(context).strings;
    if (!widget.firebaseReady) {
      showAppSnack(context, strings.t('firebaseMissingMessage'));
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      if (_signUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        _showAuthError(_firebaseErrorMessage(strings, error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    final strings = AppScope.of(context).strings;
    if (!widget.firebaseReady) {
      showAppSnack(context, strings.t('firebaseMissingMessage'));
      return;
    }
    setState(() {
      _googleBusy = true;
      _errorMessage = null;
    });

    try {
      await GoogleSignInService.ensureInitialized();
      if (!GoogleSignInService.supportsAuthenticate()) {
        _showAuthError(strings.t('googleSignInUnavailable'));
        return;
      }

      final googleAccount = await GoogleSignInService.authenticate();
      final googleAuth = googleAccount.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(code: 'missing-google-id-token');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (!mounted) return;
      if (error.code == GoogleSignInExceptionCode.canceled) {
        _showAuthError(strings.t('googleSignInCanceled'));
      } else if (error.code ==
              GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        _showAuthError(strings.t('googleConfigError'));
      } else {
        _showAuthError(
          '${strings.t('googleSignInFailed')}: ${error.description ?? error.code.name}',
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) _showAuthError(_firebaseErrorMessage(strings, error));
    } catch (error) {
      if (mounted) {
        final details = error.toString().toLowerCase();
        if (details.contains('serverclientid') ||
            details.contains('clientconfiguration') ||
            details.contains('google-services')) {
          _showAuthError(strings.t('googleConfigError'));
        } else {
          _showAuthError('${strings.t('googleSignInFailed')}: $error');
        }
      }
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _showAuthError(String message) {
    setState(() => _errorMessage = message);
    showAppSnack(context, message);
  }

  String _firebaseErrorMessage(
    AppStrings strings,
    FirebaseAuthException error,
  ) {
    final raw = '${error.code} ${error.message ?? ''}'.toLowerCase();
    if (raw.contains('configuration_not_found') ||
        raw.contains('configuration-not-found') ||
        raw.contains('operation-not-allowed')) {
      return strings.t('firebaseAuthConfigError');
    }

    return switch (error.code) {
      'email-already-in-use' => strings.t('emailAlreadyInUse'),
      'invalid-email' => strings.t('invalidEmail'),
      'weak-password' => strings.t('weakPassword'),
      'wrong-password' || 'invalid-credential' => strings.t('wrongPassword'),
      'user-not-found' => strings.t('userNotFound'),
      'network-request-failed' => strings.t('networkRequestFailed'),
      'missing-google-id-token' => strings.t('googleMissingIdToken'),
      _ => error.message ?? strings.t('authenticationFailed'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            HeroPanel(
              kicker: strings.t('biodietixMobile'),
              title: strings.t('authHeroTitle'),
              subtitle: strings.t('authHeroSubtitle'),
            ),
            if (!widget.firebaseReady)
              AppCard(
                title: strings.t('firebaseMissingTitle'),
                child: NoticeBox(
                  message: strings.t('firebaseMissingMessage'),
                  warning: true,
                ),
              )
            else
              AppCard(
                title: _signUp
                    ? strings.t('createAccount')
                    : strings.t('signIn'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: strings.t('email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    AppTextField(
                      label: strings.t('password'),
                      controller: _password,
                      obscureText: true,
                    ),
                    if (_errorMessage != null)
                      NoticeBox(message: _errorMessage!, warning: true),
                    AppButton(
                      label: _signUp
                          ? strings.t('createAccount')
                          : strings.t('signIn'),
                      onPressed: _submit,
                      busy: _busy,
                    ),
                    const SizedBox(height: 10),
                    _AuthDivider(label: strings.t('or')),
                    const SizedBox(height: 10),
                    AppButton(
                      label: strings.t('continueWithGoogle'),
                      onPressed: _signInWithGoogle,
                      busy: _googleBusy,
                      secondary: true,
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: _signUp
                          ? strings.t('alreadyHaveAccount')
                          : strings.t('createNewAccount'),
                      onPressed: () => setState(() => _signUp = !_signUp),
                      secondary: true,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: appLineColor(context))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
        Expanded(child: Divider(color: appLineColor(context))),
      ],
    );
  }
}
