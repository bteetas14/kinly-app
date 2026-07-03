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
  String selectedBrand = '';
  late Future<List<dynamic>> categoryBrands;

  @override
  void initState() {
    super.initState();
    activeQuery = widget.initialQuery;
    activeCategory = widget.initialCategory;
    categoryBrands = _brands();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery ||
        oldWidget.initialCategory != widget.initialCategory) {
      setState(() {
        activeQuery = widget.initialQuery;
        activeCategory = widget.initialCategory;
        selectedBrand = '';
        categoryBrands = _brands();
      });
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  ExploreHeading(
                    title: _heading,
                    activeCategory: activeCategory,
                    onClearCategory: () => setState(() {
                      activeCategory = '';
                      selectedBrand = '';
                      categoryBrands = _brands();
                    }),
                  ),
                  if (activeCategory.isNotEmpty) ...[
                    CategoryBrandSection(
                      future: categoryBrands,
                      selectedBrand: selectedBrand,
                      onBrandSelected: (brand) =>
                          setState(() => selectedBrand = brand),
                    ),
                    CatalogHeader(
                      selectedBrand: selectedBrand,
                      onSortSelected: (value) => setState(() => sort = value),
                    ),
                  ] else
                    CatalogHeader(
                      selectedBrand: selectedBrand,
                      onSortSelected: (value) => setState(() => sort = value),
                    ),
                  FutureBuilder<List<dynamic>>(
                    future: _products(api),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return EmptyState(snapshot.error.toString());
                      }
                      final items = snapshot.data ?? <dynamic>[];
                      if (items.isEmpty) {
                        return const EmptyState(
                            'No products match this selection yet.');
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 760 ? 3 : 2;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: columns == 2 ? 0.66 : 0.72,
                              ),
                              itemBuilder: (context, index) {
                                final item =
                                    items[index] as Map<String, dynamic>;
                                return CatalogProductCard(
                                  product: item,
                                  onTap: () =>
                                      context.go('/products/${item['id']}'),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
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
      if (selectedBrand.isNotEmpty) 'brand': selectedBrand,
    });
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }

  Future<List<dynamic>> _brands() async {
    if (activeCategory.isEmpty) {
      return <dynamic>[];
    }
    final data = await ref.read(apiClientProvider).getMap('/brands', query: {
      'category': activeCategory,
      'page_size': 30,
    });
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }

  String get _heading {
    if (activeQuery.isNotEmpty) {
      return 'Results for "$activeQuery"';
    }
    if (activeCategory.isNotEmpty) {
      return '${_categoryLabel(activeCategory)} products';
    }
    return 'Product discovery';
  }

  String _categoryLabel(String value) {
    return value
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class ExploreHeading extends StatelessWidget {
  const ExploreHeading({
    super.key,
    required this.title,
    required this.activeCategory,
    required this.onClearCategory,
  });

  final String title;
  final String activeCategory;
  final VoidCallback onClearCategory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (activeCategory.isNotEmpty) ...[
            const SizedBox(height: 10),
            InputChip(
              avatar: const Icon(Icons.category_outlined, size: 18),
              label: Text(activeCategory),
              onDeleted: onClearCategory,
            ),
          ],
        ],
      ),
    );
  }
}

class CategoryBrandSection extends StatelessWidget {
  const CategoryBrandSection({
    super.key,
    required this.future,
    required this.selectedBrand,
    required this.onBrandSelected,
  });

  final Future<List<dynamic>> future;
  final String selectedBrand;
  final ValueChanged<String> onBrandSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 170,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final brands = snapshot.data?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Featured brands'),
            if (brands.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('No brands have been added to this category yet.'),
              )
            else
              SizedBox(
                height: 142,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: brands.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => CategoryBrandBanner(
                    brand: brands[index],
                    selected: selectedBrand == brands[index]['name'],
                    onTap: () => onBrandSelected(
                        brands[index]['name']?.toString() ?? ''),
                  ),
                ),
              ),
            if (brands.isNotEmpty)
              BrandFilterBar(
                brands: brands,
                selectedBrand: selectedBrand,
                onSelected: onBrandSelected,
              ),
          ],
        );
      },
    );
  }
}

class BrandFilterBar extends StatelessWidget {
  const BrandFilterBar({
    super.key,
    required this.brands,
    required this.selectedBrand,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> brands;
  final String selectedBrand;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 0, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined,
                    size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Filter by brand',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                if (selectedBrand.isNotEmpty)
                  TextButton(
                    onPressed: () => onSelected(''),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                BrandFilterChip(
                  label: 'All',
                  selected: selectedBrand.isEmpty,
                  onTap: () => onSelected(''),
                ),
                const SizedBox(width: 8),
                for (final brand in brands) ...[
                  BrandFilterChip(
                    label: brand['name']?.toString() ?? 'Brand',
                    selected: selectedBrand == brand['name'],
                    onTap: () => onSelected(brand['name']?.toString() ?? ''),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BrandFilterChip extends StatelessWidget {
  const BrandFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primary : colors.surfaceContainerLow,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class CategoryBrandBanner extends StatelessWidget {
  const CategoryBrandBanner({
    super.key,
    required this.brand,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> brand;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bannerURL = brand['banner_url']?.toString() ?? '';
    final name = brand['name']?.toString() ?? 'Brand';
    return SizedBox(
      width: 250,
      child: Card(
        color: selected ? colors.primaryContainer : colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bannerURL.isNotEmpty)
                Image.network(
                  bannerURL,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: bannerURL.isEmpty
                        ? [
                            colors.primaryContainer,
                            colors.secondaryContainer,
                          ]
                        : [
                            Colors.black.withValues(alpha: 0.12),
                            Colors.black.withValues(alpha: 0.68),
                          ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: colors.surface.withValues(alpha: 0.92),
                      foregroundColor: colors.primary,
                      child: Text(
                        name.trim().isEmpty
                            ? 'B'
                            : name.trim().substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: bannerURL.isEmpty
                                ? colors.onPrimaryContainer
                                : Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '${brand['product_count'] ?? 0} products',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: bannerURL.isEmpty
                                ? colors.onPrimaryContainer
                                    .withValues(alpha: 0.72)
                                : Colors.white.withValues(alpha: 0.82),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final images = product['image_urls'] as List<dynamic>? ?? <dynamic>[];
    final price = ((product['price_cents'] as num?) ?? 0) / 100;
    final score = ((product['community_score'] as num?) ?? 0).toDouble();
    final reviews = (product['review_count'] as num?)?.toInt() ?? 0;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CatalogProductVisual(
                imageURL: images.isEmpty ? '' : images.first.toString(),
                category: product['category_name']?.toString() ?? '',
                brand: product['brand_name']?.toString() ?? '',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['brand_name']?.toString().toUpperCase() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['name']?.toString() ?? 'Product',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              reviews == 0 ? 'New' : score.toStringAsFixed(1),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: colors.onPrimaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (reviews > 0) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$reviews reviews',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CatalogProductVisual extends StatelessWidget {
  const CatalogProductVisual({
    super.key,
    required this.imageURL,
    required this.category,
    required this.brand,
  });

  final String imageURL;
  final String category;
  final String brand;

  @override
  Widget build(BuildContext context) {
    if (imageURL.isNotEmpty) {
      return Image.network(
        imageURL,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: Color.alphaBlend(
        _categoryColor(colors).withValues(alpha: 0.16),
        colors.surface,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 82,
            height: 112,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _categoryIcon(),
              size: 38,
              color: _categoryColor(colors),
            ),
          ),
          Positioned(
            bottom: 12,
            child: Text(
              brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon() {
    final value = category.toLowerCase();
    if (value.contains('hair')) return Icons.content_cut_rounded;
    if (value.contains('makeup')) return Icons.brush_rounded;
    if (value.contains('body')) return Icons.spa_rounded;
    if (value.contains('wellness')) return Icons.self_improvement_rounded;
    if (value.contains('fashion')) return Icons.checkroom_rounded;
    return Icons.local_florist_rounded;
  }

  Color _categoryColor(ColorScheme colors) {
    final value = category.toLowerCase();
    if (value.contains('hair')) return colors.secondary;
    if (value.contains('makeup')) return colors.primary;
    if (value.contains('body')) return colors.tertiary;
    if (value.contains('wellness')) return colors.secondary;
    if (value.contains('fashion')) return colors.onSurfaceVariant;
    return colors.primary;
  }
}

class CatalogHeader extends StatelessWidget {
  const CatalogHeader({
    super.key,
    required this.selectedBrand,
    required this.onSortSelected,
  });

  final String selectedBrand;
  final ValueChanged<String> onSortSelected;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      selectedBrand.isEmpty ? 'Product catalogue' : '$selectedBrand products',
      action: PopupMenuButton<String>(
        tooltip: 'Sort products',
        icon: const Icon(Icons.tune_rounded),
        onSelected: onSortSelected,
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'trending', child: Text('Trending')),
          PopupMenuItem(value: 'highest_rated', child: Text('Highest Rated')),
          PopupMenuItem(value: 'most_reviewed', child: Text('Most Reviewed')),
          PopupMenuItem(
              value: 'most_trusted_reviews', child: Text('Most Trusted')),
          PopupMenuItem(value: 'lowest_price', child: Text('Lowest Price')),
          PopupMenuItem(value: 'highest_price', child: Text('Highest Price')),
          PopupMenuItem(value: 'newest', child: Text('Newest')),
        ],
      ),
    );
  }
}
