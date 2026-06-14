import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/widgets.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  late Future<List<dynamic>> posts;

  @override
  void initState() {
    super.initState();
    posts = _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              tooltip: 'Create post',
              icon: const Icon(Icons.add),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => CreatePostSheet(
                    onCreated: () => setState(() => posts = _load())),
              ),
            ),
        ],
      ),
      body: AsyncList(
        future: posts,
        itemBuilder: (context, item) => PostCard(
          post: item,
          onTap: () => context.go('/community/posts/${item['id']}'),
        ),
      ),
    );
  }

  Future<List<dynamic>> _load() async {
    final data = await ref.read(apiClientProvider).getMap('/posts');
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }
}

class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet({super.key, required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final communityId = TextEditingController();
  final title = TextEditingController();
  final body = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Create post', style: Theme.of(context).textTheme.titleLarge),
          TextField(
              controller: communityId,
              decoration: const InputDecoration(labelText: 'Community ID')),
          TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title')),
          TextField(
              controller: body,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Body')),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.send_outlined),
            label: const Text('Publish'),
            onPressed: () async {
              await ref.read(apiClientProvider).postMap('/posts', {
                'community_id': communityId.text,
                'title': title.text,
                'body': body.text,
                'tags': <String>[],
                'images': <String>[],
              });
              if (context.mounted) {
                Navigator.pop(context);
                widget.onCreated();
              }
            },
          ),
        ],
      ),
    );
  }
}
