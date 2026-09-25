import 'package:flutter/material.dart';
import 'package:aicu/repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final VoidCallback onSignedIn;
  const LoginScreen({super.key, required this.authRepository, required this.onSignedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  Future<void> _submit() async {
    setState(() => _error = null);
    try {
      await widget.authRepository.signIn(_email.text, _password.text);
      widget.onSignedIn();
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Check your email and password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AICU sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextField(
            key: const Key('emailField'),
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            key: const Key('passwordField'),
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(key: const Key('signInButton'), onPressed: _submit, child: const Text('Sign in')),
        ]),
      ),
    );
  }
}
