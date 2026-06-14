import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/widgets.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late Future<Map<String, dynamic>> detail;

  @override
  void initState() {
    super.initState();
    detail = _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(snapshot.error.toString());
          }
          final data = snapshot.data ?? <String, dynamic>{};
          final product =
              data['product'] as Map<String, dynamic>? ?? <String, dynamic>{};
          final reviews = data['top_reviews'] as List<dynamic>? ?? <dynamic>[];
          final related =
              data['related_products'] as List<dynamic>? ?? <dynamic>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(product['brand_name']?.toString() ?? '',
                  style: Theme.of(context).textTheme.labelLarge),
              Text(product['name']?.toString() ?? 'Product',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(product['description']?.toString() ?? ''),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                      label: Text(
                          'Score ${(product['community_score'] as num?)?.toStringAsFixed(1) ?? '0.0'}')),
                  Chip(label: Text('${product['review_count'] ?? 0} reviews')),
                  Chip(
                      label: Text(
                          '${(((product['repurchase_rate'] as num?) ?? 0) * 100).round()}% repurchase')),
                ],
              ),
              const SizedBox(height: 16),
              if (auth.isAuthenticated)
                FilledButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ReviewSheet(
                        productId: widget.productId, onCreated: _reload),
                  ),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Write review'),
                ),
              const SectionHeader('Top Reviews'),
              for (final review in reviews.cast<Map<String, dynamic>>())
                ReviewTile(review: review),
              const SectionHeader('Related Products'),
              for (final item in related.cast<Map<String, dynamic>>())
                ProductCard(product: item),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _load() {
    return ref.read(apiClientProvider).getMap('/products/${widget.productId}');
  }

  void _reload() {
    setState(() => detail = _load());
  }
}

class ReviewTile extends ConsumerWidget {
  const ReviewTile({super.key, required this.review});

  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(review['title']?.toString() ?? 'Review'),
        subtitle: Text(review['body']?.toString() ?? ''),
        leading: CircleAvatar(child: Text('${review['rating'] ?? 0}')),
        trailing: IconButton(
          tooltip: 'Helpful',
          icon: const Icon(Icons.thumb_up_alt_outlined),
          onPressed: () => ref.read(apiClientProvider).postEmpty(
              '/reviews/${review['id']}/helpful', <String, dynamic>{}),
        ),
      ),
    );
  }
}

class ReviewSheet extends ConsumerStatefulWidget {
  const ReviewSheet(
      {super.key, required this.productId, required this.onCreated});

  final String productId;
  final VoidCallback onCreated;

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  final title = TextEditingController();
  final body = TextEditingController();
  int rating = 5;
  bool repurchased = false;
  bool wouldBuyAgain = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Write review', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 2, label: Text('2')),
              ButtonSegment(value: 3, label: Text('3')),
              ButtonSegment(value: 4, label: Text('4')),
              ButtonSegment(value: 5, label: Text('5')),
            ],
            selected: {rating},
            onSelectionChanged: (value) => setState(() => rating = value.first),
          ),
          TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title')),
          TextField(
              controller: body,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Review')),
          SwitchListTile(
            value: wouldBuyAgain,
            onChanged: (value) => setState(() => wouldBuyAgain = value),
            title: const Text('Would buy again'),
          ),
          SwitchListTile(
            value: repurchased,
            onChanged: (value) => setState(() => repurchased = value),
            title: const Text('Repurchased'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.send_outlined),
            label: const Text('Publish'),
            onPressed: () async {
              await ref.read(apiClientProvider).postMap('/reviews', {
                'product_id': widget.productId,
                'rating': rating,
                'title': title.text,
                'body': body.text,
                'pros': <String>[],
                'cons': <String>[],
                'would_buy_again': wouldBuyAgain,
                'repurchased': repurchased,
                'verified_purchase': false,
                'photos': <String>[],
              });
              if (context.mounted) {
                Navigator.pop(context);
                widget.onCreated();
              }
            },
          ),
        ],
      ),
    );
  }
}
