import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
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
        title: const Text('Kinly'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Explore filters',
            icon: const Icon(Icons.tune),
            onPressed: () => context.go('/explore'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          children: [
            HomeSearchHeader(
              controller: search,
              onSearch: _submitSearch,
            ),
            const SectionHeader('Trending Products'),
            SizedBox(
              height: 250,
              child: AsyncList(
                future: _list(
                    api, '/products', {'sort': 'trending', 'page_size': 5}),
                itemBuilder: (context, item) => ProductCard(
                  product: item,
                  onTap: () => context.go('/explore/products/${item['id']}'),
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
                future:
                    _list(api, '/products', {'sort': 'newest', 'page_size': 5}),
                itemBuilder: (context, item) => ProductCard(
                    product: item,
                    onTap: () => context.go('/explore/products/${item['id']}')),
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
                    onTap: () => context.go('/explore/products/${item['id']}')),
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        color: colors.surface,
        border: const Border(
          bottom: BorderSide(color: Color(0xffdeded8)),
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
            trailing: [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.arrow_forward),
                onPressed: onSearch,
              ),
            ],
            onSubmitted: (_) => onSearch(),
          ),
        ],
      ),
    );
  }
}
