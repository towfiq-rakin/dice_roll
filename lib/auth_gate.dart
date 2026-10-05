import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_page.dart';
import 'game_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = FirebaseAuth.instance;
  late final _authChanges = _auth.authStateChanges();
  bool _signingOut = false;

  Future<void> _submit(String email, String password, bool isSignup) async {
    if (isSignup) {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await _auth.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to log out. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Unable to load your account. Please restart the app.',
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return AuthPage(onSubmit: _submit);

        return GamePage(
          key: ValueKey(user.uid),
          onLogout: _signOut,
          isLoggingOut: _signingOut,
        );
      },
    );
  }
}
