import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/kinly_brand.dart';
import '../../core/responsive.dart';
import '../../core/widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<Map<String, dynamic>> profile;
  final bio = TextEditingController();
  final expertise = TextEditingController();
  final skinType = TextEditingController();
  final hairType = TextEditingController();
  final ageGroup = TextEditingController();
  final skinConcerns = TextEditingController();

  @override
  void initState() {
    super.initState();
    profile = _load();
  }

  @override
  void dispose() {
    bio.dispose();
    expertise.dispose();
    skinType.dispose();
    hairType.dispose();
    ageGroup.dispose();
    skinConcerns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const KinlyTitle(text: 'Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: KinlyPageFrame(
        maxWidth: 760,
        child: FutureBuilder<Map<String, dynamic>>(
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
            expertise.text =
                (user['expertise'] as List<dynamic>? ?? <dynamic>[]).join(', ');
            skinType.text = user['skin_type']?.toString() ?? '';
            hairType.text = user['hair_type']?.toString() ?? '';
            ageGroup.text = user['age_group']?.toString() ?? '';
            skinConcerns.text =
                (user['skin_concerns'] as List<dynamic>? ?? <dynamic>[])
                    .join(', ');
            return ListView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, kinlyIsDesktop(context) ? 24 : 110),
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
                Text('Karma ${user['reputation'] ?? 0}',
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
                        label: Text(
                            '${(user['saved_products'] as List<dynamic>? ?? <dynamic>[]).length} saved')),
                    Chip(
                        label: Text(
                            '${(user['wishlist'] as List<dynamic>? ?? <dynamic>[]).length} wishlist')),
                  ],
                ),
                const SectionHeader('Bio'),
                TextField(
                    controller: bio,
                    minLines: 3,
                    maxLines: 5,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder())),
                const SectionHeader('Expertise'),
                TextField(
                    controller: expertise,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Acne, sunscreen, curly hair')),
                const SectionHeader('Review Defaults'),
                TextField(
                    controller: skinType,
                    decoration: const InputDecoration(labelText: 'Skin type')),
                const SizedBox(height: 10),
                TextField(
                    controller: hairType,
                    decoration: const InputDecoration(labelText: 'Hair type')),
                const SizedBox(height: 10),
                TextField(
                    controller: ageGroup,
                    decoration: const InputDecoration(labelText: 'Age group')),
                const SizedBox(height: 10),
                TextField(
                    controller: skinConcerns,
                    decoration: const InputDecoration(
                        labelText: 'Skin concerns, comma separated')),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save profile'),
                  onPressed: () async {
                    final updated = await ref
                        .read(apiClientProvider)
                        .patchMap('/users/profile', {
                      'bio': bio.text,
                      'avatar_url': user['avatar_url'] ?? '',
                      'expertise': expertise.text
                          .split(',')
                          .map((item) => item.trim())
                          .where((item) => item.isNotEmpty)
                          .toList(),
                      'skin_type': skinType.text,
                      'hair_type': hairType.text,
                      'age_group': ageGroup.text,
                      'skin_concerns': skinConcerns.text
                          .split(',')
                          .map((item) => item.trim())
                          .where((item) => item.isNotEmpty)
                          .toList(),
                    });
                    setState(() => profile = Future.value(updated));
                  },
                ),
                const SectionHeader('Favorite Brands'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final brand
                        in (user['favorite_brands'] as List<dynamic>? ??
                            <dynamic>[]))
                      Chip(label: Text(brand.toString())),
                  ],
                ),
                const SectionHeader('Saved Products'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final product
                        in (user['saved_products'] as List<dynamic>? ??
                            <dynamic>[]))
                      Chip(label: Text(product.toString())),
                  ],
                ),
                const SectionHeader('Wishlist'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final product
                        in (user['wishlist'] as List<dynamic>? ?? <dynamic>[]))
                      Chip(label: Text(product.toString())),
                  ],
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
