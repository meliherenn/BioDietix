import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../i18n.dart';
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

    setState(() => _busy = true);
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
        showAppSnack(
          context,
          error.message ?? strings.t('authenticationFailed'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                    AppButton(
                      label: _signUp
                          ? strings.t('createAccount')
                          : strings.t('signIn'),
                      onPressed: _submit,
                      busy: _busy,
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
