import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onSubmit});

  final Future<void> Function(String email, String password, bool isSignup)
  onSubmit;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _isSignup = false;
  bool _hidePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_email.text.trim(), _password.text, _isSignup);
    } on FirebaseAuthException catch (error) {
      _showError(switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'email-already-in-use' =>
          'This email already has an account. Try logging in.',
        'weak-password' => 'Choose a stronger password.',
        'invalid-credential' ||
        'user-not-found' ||
        'wrong-password' => 'Email or password is incorrect.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        'operation-not-allowed' =>
          'Email/password sign-in must be enabled in Firebase.',
        _ => 'Unable to sign in. Please try again.',
      });
    } catch (_) {
      _showError('Unable to connect. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleMode() {
    _formKey.currentState!.reset();
    _password.clear();
    _confirmation.clear();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _isSignup = !_isSignup;
      _hidePassword = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 64).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(
                                Icons.casino_outlined,
                                size: 48,
                                color: theme.colorScheme.onPrimary,
                                semanticLabel: 'Dice',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Dice Roll',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSignup
                                ? 'Create an account to play.'
                                : 'Log in to play.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (value) {
                              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(value?.trim() ?? '')) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            obscureText: _hidePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: _isSignup
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: [
                              _isSignup
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            onFieldSubmitted: (_) {
                              if (!_isSignup) _submit();
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                tooltip: _hidePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your password.';
                              }
                              if (_isSignup && value.length < 6) {
                                return 'Use at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          if (_isSignup) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmation,
                              obscureText: _hidePassword,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirm your password.';
                                }
                                if (value != _password.text) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: Text(
                              _isSubmitting
                                  ? 'Please wait…'
                                  : (_isSignup ? 'Create account' : 'Log in'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isSubmitting ? null : _toggleMode,
                            child: Text(
                              _isSignup
                                  ? 'Already have an account? Log in'
                                  : 'New here? Sign up',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
