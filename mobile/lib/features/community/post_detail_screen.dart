import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/kinly_brand.dart';
import '../../core/responsive.dart';
import '../../core/widgets.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  late Future<Map<String, dynamic>> post;
  late Future<List<dynamic>> comments;

  @override
  void initState() {
    super.initState();
    post = _post();
    comments = _comments();
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiClientProvider);
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const KinlyBackButton(fallbackLocation: '/community'),
        title: const Text('Discussion'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: post,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(snapshot.error.toString());
          }
          final item = snapshot.data ?? <String, dynamic>{};
          return KinlyPageFrame(
            maxWidth: 860,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, kinlyIsDesktop(context) ? 28 : 110),
              children: [
                Text(item['community_name']?.toString() ?? '',
                    style: Theme.of(context).textTheme.labelLarge),
                Text(item['title']?.toString() ?? 'Post',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(item['body']?.toString() ?? ''),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Upvote',
                      onPressed: auth.isAuthenticated
                          ? () => api.postEmpty(
                              '/posts/${widget.postId}/vote', {'value': 1})
                          : null,
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: 'Downvote',
                      onPressed: auth.isAuthenticated
                          ? () => api.postEmpty(
                              '/posts/${widget.postId}/vote', {'value': -1})
                          : null,
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Report',
                      onPressed: auth.isAuthenticated
                          ? () => api.postEmpty(
                              '/posts/${widget.postId}/report',
                              {'reason': 'Community report'})
                          : null,
                      icon: const Icon(Icons.flag_outlined),
                    ),
                  ],
                ),
                if (auth.isAuthenticated)
                  FilledButton.icon(
                    icon: const Icon(Icons.comment_outlined),
                    label: const Text('Comment'),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => CommentSheet(
                          postId: widget.postId, onCreated: _reloadComments),
                    ),
                  ),
                const SectionHeader('Comments'),
                FutureBuilder<List<dynamic>>(
                  future: comments,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()));
                    }
                    final items = snapshot.data ?? <dynamic>[];
                    if (items.isEmpty) {
                      return const EmptyState('No comments yet.');
                    }
                    return Column(
                      children: [
                        for (final comment
                            in items.cast<Map<String, dynamic>>())
                          Card(
                            child: ListTile(
                              title: Text(comment['author_name']?.toString() ??
                                  'Member'),
                              subtitle: Text(comment['body']?.toString() ?? ''),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _post() {
    return ref.read(apiClientProvider).getMap('/posts/${widget.postId}');
  }

  Future<List<dynamic>> _comments() async {
    final data = await ref
        .read(apiClientProvider)
        .getMap('/posts/${widget.postId}/comments');
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }

  void _reloadComments() {
    setState(() => comments = _comments());
  }
}

class CommentSheet extends ConsumerStatefulWidget {
  const CommentSheet(
      {super.key, required this.postId, required this.onCreated});

  final String postId;
  final VoidCallback onCreated;

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final body = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Add comment', style: Theme.of(context).textTheme.titleLarge),
          TextField(
              controller: body,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Comment')),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              await ref.read(apiClientProvider).postMap('/comments', {
                'post_id': widget.postId,
                'parent_comment_id': '',
                'body': body.text,
              });
              if (context.mounted) {
                Navigator.pop(context);
                widget.onCreated();
              }
            },
            child: const Text('Post comment'),
          ),
        ],
      ),
    );
  }
}
