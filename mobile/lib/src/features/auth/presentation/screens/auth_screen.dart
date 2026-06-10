import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';
import '../../data/auth_repository.dart';
import '../cubit/auth_cubit.dart';

enum _AuthMode { signIn, signUp, forgotPassword }

class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.firebaseReady, super.key});

  final bool firebaseReady;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _mode = _AuthMode.signIn;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<AuthCubit>();
    switch (_mode) {
      case _AuthMode.signIn:
        await cubit.signIn(email: _email.text, password: _password.text);
      case _AuthMode.signUp:
        await cubit.signUp(email: _email.text, password: _password.text);
      case _AuthMode.forgotPassword:
        await cubit.sendPasswordReset(_email.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          showAppSnack(context, _authErrorMessage(strings, state.error));
        } else if (state is AuthPasswordResetSent) {
          showAppSnack(context, strings.t('passwordResetSent'));
        }
      },
      builder: (context, state) {
        final busy = state is AuthLoading;
        final forgot = _mode == _AuthMode.forgotPassword;
        final signingUp = _mode == _AuthMode.signUp;

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: pagePadding,
              children: [
                HeroPanel(
                  kicker: strings.t('biodietixMobile'),
                  title: strings.t('authHeroTitle'),
                  subtitle: strings.t('authHeroSubtitle'),
                  icon: Icons.verified_user_rounded,
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
                    title: forgot
                        ? strings.t('forgotPassword')
                        : signingUp
                        ? strings.t('createAccount')
                        : strings.t('signIn'),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppFormTextField(
                            label: strings.t('email'),
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return strings.t('emailRequired');
                              }
                              if (!email.contains('@')) {
                                return strings.t('invalidEmail');
                              }
                              return null;
                            },
                          ),
                          if (!forgot)
                            AppFormTextField(
                              label: strings.t('password'),
                              controller: _password,
                              obscureText: true,
                              validator: (value) {
                                final password = value ?? '';
                                if (password.length < 6) {
                                  return strings.t('weakPassword');
                                }
                                return null;
                              },
                            ),
                          AppButton(
                            label: forgot
                                ? strings.t('sendResetLink')
                                : signingUp
                                ? strings.t('createAccount')
                                : strings.t('signIn'),
                            onPressed: _submit,
                            busy: busy,
                          ),
                          if (!forgot) ...[
                            const SizedBox(height: 10),
                            _AuthDivider(label: strings.t('or')),
                            const SizedBox(height: 10),
                            AppButton(
                              label: strings.t('continueWithGoogle'),
                              onPressed: context
                                  .read<AuthCubit>()
                                  .signInWithGoogle,
                              busy: busy,
                              secondary: true,
                            ),
                          ],
                          const SizedBox(height: 10),
                          AppButton(
                            label: forgot
                                ? strings.t('backToSignIn')
                                : signingUp
                                ? strings.t('alreadyHaveAccount')
                                : strings.t('createNewAccount'),
                            onPressed: () {
                              setState(() {
                                _mode = forgot
                                    ? _AuthMode.signIn
                                    : signingUp
                                    ? _AuthMode.signIn
                                    : _AuthMode.signUp;
                              });
                            },
                            secondary: true,
                          ),
                          if (!forgot && !signingUp) ...[
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => setState(
                                () => _mode = _AuthMode.forgotPassword,
                              ),
                              child: Text(strings.t('forgotPassword')),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _authErrorMessage(AppStrings strings, Object error) {
    if (isGoogleSignInCanceled(error)) return strings.t('googleSignInCanceled');
    if (isGoogleSignInConfigError(error)) return strings.t('googleConfigError');

    if (error is FirebaseAuthException) {
      final raw = '${error.code} ${error.message ?? ''}'.toLowerCase();
      if (raw.contains('configuration_not_found') ||
          raw.contains('configuration-not-found') ||
          raw.contains('operation-not-allowed')) {
        return strings.t('firebaseAuthConfigError');
      }

      return switch (error.code) {
        'firebase-not-configured' => strings.t('firebaseMissingMessage'),
        'email-already-in-use' => strings.t('emailAlreadyInUse'),
        'invalid-email' => strings.t('invalidEmail'),
        'weak-password' => strings.t('weakPassword'),
        'wrong-password' || 'invalid-credential' => strings.t('wrongPassword'),
        'user-not-found' => strings.t('userNotFound'),
        'network-request-failed' => strings.t('networkRequestFailed'),
        'missing-google-id-token' => strings.t('googleMissingIdToken'),
        'google-sign-in-unavailable' => strings.t('googleSignInUnavailable'),
        _ => error.message ?? strings.t('authenticationFailed'),
      };
    }

    return '${strings.t('authenticationFailed')} $error';
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
