import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/kinly_brand.dart';
import '../../core/responsive.dart';
import '../../core/theme_controller.dart';
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
          const ThemeModeToggle(),
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
                ProfileHero(user: user),
                const SectionHeader('Bio'),
                ProfilePanel(
                  child: TextField(
                      controller: bio,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                          hintText: 'Tell people what you care about')),
                ),
                const SectionHeader('Expertise'),
                ProfilePanel(
                  child: TextField(
                      controller: expertise,
                      decoration: const InputDecoration(
                          hintText: 'Acne, sunscreen, curly hair')),
                ),
                const SectionHeader('Review Defaults'),
                ProfilePanel(
                  child: Column(
                    children: [
                      TextField(
                          controller: skinType,
                          decoration:
                              const InputDecoration(labelText: 'Skin type')),
                      const SizedBox(height: 10),
                      TextField(
                          controller: hairType,
                          decoration:
                              const InputDecoration(labelText: 'Hair type')),
                      const SizedBox(height: 10),
                      TextField(
                          controller: ageGroup,
                          decoration:
                              const InputDecoration(labelText: 'Age group')),
                      const SizedBox(height: 10),
                      TextField(
                          controller: skinConcerns,
                          decoration: const InputDecoration(
                              labelText: 'Skin concerns, comma separated')),
                    ],
                  ),
                ),
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

class ProfileHero extends StatelessWidget {
  const ProfileHero({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final username = user['username']?.toString() ?? 'Member';
    final initial = username.trim().isEmpty
        ? 'K'
        : username.trim().substring(0, 1).toUpperCase();
    return Card(
      color: Color.alphaBlend(
        colors.primary.withValues(alpha: 0.055),
        colors.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.primary,
              child: Text(
                initial,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 28),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              username,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              'Glow ${user['reputation'] ?? 0}',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ProfileStat(
                      label: 'Reviews', value: '${user['review_count'] ?? 0}'),
                ),
                Expanded(
                  child: ProfileStat(
                      label: 'Helpful',
                      value: '${user['helpful_votes_received'] ?? 0}'),
                ),
                Expanded(
                  child: ProfileStat(
                    label: 'Saved',
                    value:
                        '${(user['saved_products'] as List<dynamic>? ?? <dynamic>[]).length}',
                  ),
                ),
                Expanded(
                  child: ProfileStat(
                    label: 'Wishlist',
                    value:
                        '${(user['wishlist'] as List<dynamic>? ?? <dynamic>[]).length}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  const ProfileStat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class ProfilePanel extends StatelessWidget {
  const ProfilePanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}
