import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/widgets.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final query = TextEditingController();
  String sort = 'trending';
  String activeQuery = '';

  @override
  void initState() {
    super.initState();
    activeQuery = widget.initialQuery;
    query.text = widget.initialQuery;
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      activeQuery = widget.initialQuery;
      query.text = widget.initialQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiClientProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: query,
                    leading: const Icon(Icons.search),
                    hintText: 'Search products, brands, categories',
                    trailing: [
                      IconButton(
                        tooltip: 'Search',
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () =>
                            setState(() => activeQuery = query.text.trim()),
                      ),
                    ],
                    onSubmitted: (value) =>
                        setState(() => activeQuery = value.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) => setState(() => sort = value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'trending', child: Text('Trending')),
                    PopupMenuItem(
                        value: 'highest_rated', child: Text('Highest Rated')),
                    PopupMenuItem(
                        value: 'most_reviewed', child: Text('Most Reviewed')),
                    PopupMenuItem(
                        value: 'lowest_price', child: Text('Lowest Price')),
                    PopupMenuItem(
                        value: 'highest_price', child: Text('Highest Price')),
                    PopupMenuItem(value: 'newest', child: Text('Newest')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncList(
              future: _products(api),
              itemBuilder: (context, item) => ProductCard(
                product: item,
                onTap: () => context.go('/explore/products/${item['id']}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<dynamic>> _products(ApiClient api) async {
    final path = activeQuery.isEmpty ? '/products' : '/products/search';
    final data =
        await api.getMap(path, query: {'q': activeQuery, 'sort': sort});
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }
}
