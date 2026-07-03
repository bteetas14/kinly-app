import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/kinly_brand.dart';
import '../../core/responsive.dart';
import '../../core/theme_controller.dart';
import '../../core/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiClientProvider);
    return Scaffold(
      appBar: AppBar(
        title: const KinlyTitle(),
        centerTitle: false,
        actions: const [MobileThemeModeAction()],
      ),
      body: KinlyPageFrame(
        maxWidth: 1080,
        child: RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: EdgeInsets.only(
              bottom: kinlyIsDesktop(context) ? 24 : 96,
            ),
            children: [
              HomeSearchHeader(
                controller: search,
                onSearch: _submitSearch,
              ),
              CategoryBrowse(
                future: _list(api, '/categories', const {}),
              ),
              const SectionHeader('Trending Products'),
              HomePreviewList(
                future: _list(
                    api, '/products', {'sort': 'trending', 'page_size': 3}),
                itemBuilder: (context, item) => ProductCard(
                  product: item,
                  onTap: () => context.go('/products/${item['id']}'),
                ),
              ),
              BrandBrowse(
                future: _list(api, '/brands', {'page_size': 8}),
              ),
              const SectionHeader('Popular Discussions'),
              HomePreviewList(
                future: _list(api, '/posts', {'page_size': 3}),
                itemBuilder: (context, item) => PostCard(
                  post: item,
                  onTap: () => context.go('/community/posts/${item['id']}'),
                ),
              ),
              const SectionHeader('Recently Reviewed Products'),
              HomePreviewList(
                future:
                    _list(api, '/products', {'sort': 'newest', 'page_size': 3}),
                itemBuilder: (context, item) => ProductCard(
                  product: item,
                  onTap: () => context.go('/products/${item['id']}'),
                ),
              ),
              const SectionHeader('Community Picks'),
              HomePreviewList(
                future: _list(api, '/products',
                    {'sort': 'highest_rated', 'page_size': 3}),
                itemBuilder: (context, item) => ProductCard(
                  product: item,
                  onTap: () => context.go('/products/${item['id']}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>> _list(
      ApiClient api, String path, Map<String, dynamic> query) async {
    final data = await api.getMap(path, query: query);
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }

  void _submitSearch() {
    final value = search.text.trim();
    if (value.isEmpty) {
      context.go('/explore');
      return;
    }
    context.go('/explore?q=${Uri.encodeQueryComponent(value)}');
  }
}

class HomePreviewList extends StatelessWidget {
  const HomePreviewList({
    super.key,
    required this.future,
    required this.itemBuilder,
  });

  final Future<List<dynamic>> future;
  final Widget Function(BuildContext context, Map<String, dynamic> item)
      itemBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return EmptyState(snapshot.error.toString());
        }
        final items = (snapshot.data ?? <dynamic>[])
            .take(3)
            .cast<Map<String, dynamic>>()
            .toList();
        if (items.isEmpty) {
          return const EmptyState('Nothing to show yet.');
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                itemBuilder(context, items[index]),
                if (index != items.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class CategoryBrowse extends StatelessWidget {
  const CategoryBrowse({super.key, required this.future});

  final Future<List<dynamic>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? <dynamic>[];
        if (snapshot.connectionState != ConnectionState.done || items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Explore by Category'),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in items.cast<Map<String, dynamic>>()) ...[
                    CategoryBubble(
                      name: item['name']?.toString() ?? '',
                      slug: item['slug']?.toString() ?? '',
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class CategoryBubble extends StatelessWidget {
  const CategoryBubble({super.key, required this.name, required this.slug});

  final String name;
  final String slug;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () =>
          context.go('/explore?category=${Uri.encodeQueryComponent(slug)}'),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.10),
                ),
              ),
              child: Icon(_categoryIcon(name), color: colors.primary),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String value) {
    final name = value.toLowerCase();
    if (name.contains('skin')) return Icons.face_retouching_natural_outlined;
    if (name.contains('hair')) return Icons.content_cut_outlined;
    if (name.contains('makeup')) return Icons.brush_outlined;
    if (name.contains('body')) return Icons.spa_outlined;
    if (name.contains('wellness')) return Icons.self_improvement_outlined;
    if (name.contains('fashion')) return Icons.checkroom_outlined;
    return Icons.category_outlined;
  }
}

class BrandBrowse extends StatelessWidget {
  const BrandBrowse({super.key, required this.future});

  final Future<List<dynamic>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? <dynamic>[];
        if (snapshot.connectionState != ConnectionState.done || items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Brands'),
            SizedBox(
              height: 112,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final brand = items[index] as Map<String, dynamic>;
                  final colors = Theme.of(context).colorScheme;
                  final dark = Theme.of(context).brightness == Brightness.dark;
                  return SizedBox(
                    width: 188,
                    child: Card(
                      color: dark
                          ? const Color(0xff242321)
                          : Color.alphaBlend(
                              colors.secondary.withValues(alpha: 0.08),
                              colors.surface,
                            ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.go('/brands/${brand['id']}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.verified_outlined,
                                  color: colors.primary),
                              const Spacer(),
                              Text(
                                brand['name']?.toString() ?? 'Brand',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: colors.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                '${brand['review_count'] ?? 0} reviews',
                                style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class HomeSearchHeader extends StatelessWidget {
  const HomeSearchHeader({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer,
            Color.alphaBlend(
              colors.secondary.withValues(alpha: 0.10),
              colors.surface,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Honest beauty starts here.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Real people. Real reviews. Better decisions.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onPrimaryContainer.withValues(alpha: 0.76)),
          ),
          const SizedBox(height: 20),
          SearchBar(
            controller: controller,
            hintText: 'Search products, brands, ingredients...',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(2),
            shadowColor:
                WidgetStatePropertyAll(colors.shadow.withValues(alpha: 0.12)),
            backgroundColor: WidgetStatePropertyAll(colors.surface),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.08)),
              ),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16),
            ),
            trailing: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'Search',
                  color: colors.onPrimary,
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: onSearch,
                ),
              ),
            ],
            onSubmitted: (_) => onSearch(),
          ),
        ],
      ),
    );
  }
}
