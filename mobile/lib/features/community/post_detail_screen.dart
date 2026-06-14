import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/widgets.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiClientProvider);
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Discussion')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: api.getMap('/posts/$postId'),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(snapshot.error.toString());
          }
          final post = snapshot.data ?? <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(post['community_name']?.toString() ?? '',
                  style: Theme.of(context).textTheme.labelLarge),
              Text(post['title']?.toString() ?? 'Post',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(post['body']?.toString() ?? ''),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Upvote',
                    onPressed: auth.isAuthenticated
                        ? () =>
                            api.postEmpty('/posts/$postId/vote', {'value': 1})
                        : null,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    tooltip: 'Downvote',
                    onPressed: auth.isAuthenticated
                        ? () =>
                            api.postEmpty('/posts/$postId/vote', {'value': -1})
                        : null,
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Report',
                    onPressed: auth.isAuthenticated
                        ? () => api.postEmpty('/posts/$postId/report',
                            {'reason': 'Community report'})
                        : null,
                    icon: const Icon(Icons.flag_outlined),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
