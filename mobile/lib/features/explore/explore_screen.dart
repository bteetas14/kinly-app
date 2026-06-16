import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/kinly_brand.dart';
import '../../core/responsive.dart';
import '../../core/widgets.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen(
      {super.key, this.initialQuery = '', this.initialCategory = ''});

  final String initialQuery;
  final String initialCategory;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String sort = 'trending';
  String activeQuery = '';
  String activeCategory = '';

  @override
  void initState() {
    super.initState();
    activeQuery = widget.initialQuery;
    activeCategory = widget.initialCategory;
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery ||
        oldWidget.initialCategory != widget.initialCategory) {
      activeQuery = widget.initialQuery;
      activeCategory = widget.initialCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiClientProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const KinlyBackButton(),
        title: const Text('Explore'),
      ),
      body: KinlyPageFrame(
        maxWidth: 960,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _heading,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.sort),
                        onSelected: (value) => setState(() => sort = value),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                              value: 'trending', child: Text('Trending')),
                          PopupMenuItem(
                              value: 'highest_rated',
                              child: Text('Highest Rated')),
                          PopupMenuItem(
                              value: 'most_reviewed',
                              child: Text('Most Reviewed')),
                          PopupMenuItem(
                              value: 'most_trusted_reviews',
                              child: Text('Most Trusted')),
                          PopupMenuItem(
                              value: 'lowest_price',
                              child: Text('Lowest Price')),
                          PopupMenuItem(
                              value: 'highest_price',
                              child: Text('Highest Price')),
                          PopupMenuItem(value: 'newest', child: Text('Newest')),
                        ],
                      ),
                    ],
                  ),
                  if (activeCategory.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    InputChip(
                      avatar: const Icon(Icons.category_outlined, size: 18),
                      label: Text(activeCategory),
                      onDeleted: () => setState(() => activeCategory = ''),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: AsyncList(
                future: _products(api),
                itemBuilder: (context, item) => ProductCard(
                  product: item,
                  onTap: () => context.go('/products/${item['id']}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> _products(ApiClient api) async {
    final path = activeQuery.isEmpty ? '/products' : '/products/search';
    final data = await api.getMap(path, query: {
      'q': activeQuery,
      'sort': sort,
      if (activeCategory.isNotEmpty) 'category': activeCategory,
    });
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }

  String get _heading {
    if (activeQuery.isNotEmpty) {
      return 'Results for "$activeQuery"';
    }
    if (activeCategory.isNotEmpty) {
      return 'Browse $activeCategory';
    }
    return 'Product discovery';
  }
}
