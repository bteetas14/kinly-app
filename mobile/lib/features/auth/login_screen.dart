import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  bool signup = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kinly')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(signup ? 'Create account' : 'Sign in',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email')),
          if (signup) ...[
            const SizedBox(height: 12),
            TextField(
                controller: username,
                decoration: const InputDecoration(labelText: 'Username')),
          ],
          const SizedBox(height: 12),
          TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 16),
          if (auth.error != null)
            Text(auth.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: auth.loading
                ? null
                : () {
                    final controller =
                        ref.read(authControllerProvider.notifier);
                    if (signup) {
                      controller.signup(
                          email.text, username.text, password.text);
                    } else {
                      controller.login(email.text, password.text);
                    }
                  },
            icon: auth.loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.login),
            label: Text(signup ? 'Create account' : 'Sign in'),
          ),
          TextButton(
            onPressed: () => setState(() => signup = !signup),
            child: Text(
                signup ? 'Use an existing account' : 'Create a new account'),
          ),
        ],
      ),
    );
  }
}
