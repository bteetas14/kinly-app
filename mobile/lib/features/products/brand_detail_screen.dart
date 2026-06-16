import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/kinly_brand.dart';
import '../../core/responsive.dart';
import '../../core/widgets.dart';

class BrandDetailScreen extends ConsumerWidget {
  const BrandDetailScreen({super.key, required this.brandId});

  final String brandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiClientProvider);
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const KinlyBackButton(),
        title: const Text('Brand'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Future.wait([
          api.getMap('/brands/$brandId'),
          api.getMap('/brands/$brandId/products'),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(snapshot.error.toString());
          }
          final brand = snapshot.data?[0] ?? <String, dynamic>{};
          final products =
              snapshot.data?[1]['data'] as List<dynamic>? ?? <dynamic>[];
          return KinlyPageFrame(
            maxWidth: 860,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, kinlyIsDesktop(context) ? 28 : 110),
              children: [
                Text(brand['name']?.toString() ?? 'Brand',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(brand['description']?.toString() ?? ''),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Status ${brand['status'] ?? 'active'}')),
                    Chip(
                        label: Text(
                            'Certification ${brand['certification_status'] ?? 'unverified'}')),
                    Chip(
                        label: Text('${brand['product_count'] ?? 0} products')),
                    Chip(label: Text('${brand['review_count'] ?? 0} reviews')),
                  ],
                ),
                const SizedBox(height: 12),
                if (auth.isAuthenticated)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Favorite brand'),
                    onPressed: () => api.postEmpty(
                        '/brands/$brandId/favorite', <String, dynamic>{}),
                  ),
                const SectionHeader('Products'),
                for (final product in products.cast<Map<String, dynamic>>())
                  ProductCard(
                    product: product,
                    onTap: () => context.go('/products/${product['id']}'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
