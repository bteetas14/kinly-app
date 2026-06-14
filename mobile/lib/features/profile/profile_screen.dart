import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<Map<String, dynamic>> profile;
  final bio = TextEditingController();

  @override
  void initState() {
    super.initState();
    profile = _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(snapshot.error.toString());
          }
          final user = snapshot.data ?? auth.user ?? <String, dynamic>{};
          bio.text = user['bio']?.toString() ?? '';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(
                  radius: 36,
                  child: Text((user['username']?.toString() ?? 'K')
                      .substring(0, 1)
                      .toUpperCase())),
              const SizedBox(height: 12),
              Text(user['username']?.toString() ?? 'Member',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              Text(
                  'Reputation ${user['reputation'] ?? 0} • Trust ${user['trust_score'] ?? 0}',
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('${user['review_count'] ?? 0} reviews')),
                  Chip(
                      label: Text(
                          '${user['helpful_votes_received'] ?? 0} helpful')),
                  Chip(
                      label: Text('${user['followers_count'] ?? 0} followers')),
                  Chip(
                      label: Text('${user['following_count'] ?? 0} following')),
                ],
              ),
              const SectionHeader('Bio'),
              TextField(
                  controller: bio,
                  minLines: 3,
                  maxLines: 5,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save profile'),
                onPressed: () async {
                  final updated = await ref.read(apiClientProvider).patchMap(
                      '/users/profile', {
                    'bio': bio.text,
                    'avatar_url': user['avatar_url'] ?? ''
                  });
                  setState(() => profile = Future.value(updated));
                },
              ),
              const SectionHeader('Badges'),
              Wrap(
                spacing: 8,
                children: [
                  for (final badge
                      in (user['badges'] as List<dynamic>? ?? <dynamic>[]))
                    Chip(label: Text(badge.toString())),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _load() async {
    final auth = ref.read(authControllerProvider);
    final id = auth.user?['id']?.toString();
    if (id == null) {
      return auth.user ?? <String, dynamic>{};
    }
    return ref.read(apiClientProvider).getMap('/users/$id');
  }
}
