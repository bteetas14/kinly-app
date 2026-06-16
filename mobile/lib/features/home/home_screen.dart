import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/kinly_brand.dart';
import '../../core/responsive.dart';
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
        actions: [
          IconButton(
            tooltip: 'Explore filters',
            icon: const Icon(Icons.tune),
            onPressed: () => context.go('/explore'),
          ),
        ],
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
              BrandBrowse(
                future: _list(api, '/brands', {'page_size': 8}),
              ),
              const SectionHeader('Trending Products'),
              SizedBox(
                height: 250,
                child: AsyncList(
                  future: _list(
                      api, '/products', {'sort': 'trending', 'page_size': 5}),
                  itemBuilder: (context, item) => ProductCard(
                    product: item,
                    onTap: () => context.go('/products/${item['id']}'),
                  ),
                ),
              ),
              const SectionHeader('Popular Discussions'),
              SizedBox(
                height: 250,
                child: AsyncList(
                  future: _list(api, '/posts', {'page_size': 5}),
                  itemBuilder: (context, item) => PostCard(
                    post: item,
                    onTap: () => context.go('/community/posts/${item['id']}'),
                  ),
                ),
              ),
              const SectionHeader('Recently Reviewed Products'),
              SizedBox(
                height: 250,
                child: AsyncList(
                  future: _list(
                      api, '/products', {'sort': 'newest', 'page_size': 5}),
                  itemBuilder: (context, item) => ProductCard(
                      product: item,
                      onTap: () => context.go('/products/${item['id']}')),
                ),
              ),
              const SectionHeader('Community Picks'),
              SizedBox(
                height: 250,
                child: AsyncList(
                  future: _list(api, '/products',
                      {'sort': 'highest_rated', 'page_size': 5}),
                  itemBuilder: (context, item) => ProductCard(
                      product: item,
                      onTap: () => context.go('/products/${item['id']}')),
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
            const SectionHeader('Browse Categories'),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in items.cast<Map<String, dynamic>>()) ...[
                    ActionChip(
                      avatar: const Icon(Icons.category_outlined, size: 18),
                      label: Text(item['name']?.toString() ?? ''),
                      onPressed: () => context.go(
                          '/explore?category=${Uri.encodeQueryComponent(item['slug']?.toString() ?? '')}'),
                    ),
                    const SizedBox(width: 8),
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
                  return SizedBox(
                    width: 190,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.go('/brands/${brand['id']}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.verified_outlined),
                              const Spacer(),
                              Text(
                                brand['name']?.toString() ?? 'Brand',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text('${brand['review_count'] ?? 0} reviews'),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: const Border(
          bottom: BorderSide(color: Color(0xffe7e1d8)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find products people actually use',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search skincare, makeup, haircare, wellness, fashion, and brands.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          SearchBar(
            controller: controller,
            hintText: 'Search products, brands, categories',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Color(0xffddd7cd)),
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
