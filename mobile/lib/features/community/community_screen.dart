import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/kinly_brand.dart';
import '../../core/responsive.dart';
import '../../core/widgets.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  late Future<List<dynamic>> communities;
  late Future<List<dynamic>> posts;
  String selectedCommunityId = '';
  String selectedCommunityName = 'All';

  @override
  void initState() {
    super.initState();
    communities = _communities();
    posts = _posts();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const KinlyTitle(text: 'Community'),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              tooltip: 'Create post',
              icon: const Icon(Icons.add),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => CreatePostSheet(
                  communities: communities,
                  onCreated: () => setState(() => posts = _posts()),
                ),
              ),
            ),
        ],
      ),
      body: KinlyPageFrame(
        maxWidth: 980,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<dynamic>>(
              future: communities,
              builder: (context, snapshot) {
                final items = snapshot.data ?? <dynamic>[];
                if (snapshot.connectionState != ConnectionState.done ||
                    items.isEmpty) {
                  return const SizedBox.shrink();
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: selectedCommunityId.isEmpty,
                        onSelected: (_) => _selectCommunity('', 'All'),
                      ),
                      const SizedBox(width: 8),
                      for (final item
                          in items.cast<Map<String, dynamic>>()) ...[
                        ChoiceChip(
                          label: Text(item['name']?.toString() ?? ''),
                          selected: selectedCommunityId == item['id'],
                          onSelected: (_) => _selectCommunity(
                              item['id'].toString(),
                              item['name']?.toString() ?? 'Community'),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(selectedCommunityName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: AsyncList(
                future: posts,
                itemBuilder: (context, item) => PostCard(
                  post: item,
                  onTap: () => context.go('/community/posts/${item['id']}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCommunity(String id, String name) {
    setState(() {
      selectedCommunityId = id;
      selectedCommunityName = name;
      posts = _posts();
    });
  }

  Future<List<dynamic>> _communities() async {
    final data = await ref.read(apiClientProvider).getMap('/communities');
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }

  Future<List<dynamic>> _posts() async {
    final data = await ref.read(apiClientProvider).getMap('/posts', query: {
      if (selectedCommunityId.isNotEmpty) 'community_id': selectedCommunityId,
    });
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }
}

class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet(
      {super.key, required this.communities, required this.onCreated});

  final Future<List<dynamic>> communities;
  final VoidCallback onCreated;

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final title = TextEditingController();
  final body = TextEditingController();
  String communityId = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: FutureBuilder<List<dynamic>>(
        future: widget.communities,
        builder: (context, snapshot) {
          final items = snapshot.data ?? <dynamic>[];
          if (communityId.isEmpty && items.isNotEmpty) {
            communityId =
                (items.first as Map<String, dynamic>)['id'].toString();
          }
          return ListView(
            shrinkWrap: true,
            children: [
              Text('Create post',
                  style: Theme.of(context).textTheme.titleLarge),
              DropdownButtonFormField<String>(
                initialValue: communityId.isEmpty ? null : communityId,
                decoration: const InputDecoration(labelText: 'Community'),
                items: [
                  for (final item in items.cast<Map<String, dynamic>>())
                    DropdownMenuItem(
                        value: item['id'].toString(),
                        child: Text(item['name']?.toString() ?? 'Community')),
                ],
                onChanged: (value) => setState(() => communityId = value ?? ''),
              ),
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
                onPressed: communityId.isEmpty
                    ? null
                    : () async {
                        await ref.read(apiClientProvider).postMap('/posts', {
                          'community_id': communityId,
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
          );
        },
      ),
    );
  }
}
