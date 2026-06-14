import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class AsyncList extends StatelessWidget {
  const AsyncList({
    super.key,
    required this.future,
    required this.itemBuilder,
    this.emptyMessage = 'Nothing to show yet.',
  });

  final Future<List<dynamic>> future;
  final Widget Function(BuildContext context, Map<String, dynamic> item)
      itemBuilder;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(snapshot.error.toString());
        }
        final items = snapshot.data ?? <dynamic>[];
        if (items.isEmpty) {
          return EmptyState(emptyMessage);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              itemBuilder(context, items[index] as Map<String, dynamic>),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final score =
        (product['community_score'] as num?)?.toStringAsFixed(1) ?? '0.0';
    final price = ((product['price_cents'] as num?) ?? 0) / 100;
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.spa_outlined,
                    color: colors.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product['name']?.toString() ?? 'Product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product['brand_name'] ?? ''} • \$${price.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 42,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rate_rounded,
                        size: 18, color: colors.primary),
                    Text(score, style: Theme.of(context).textTheme.labelSmall),
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

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.onTap});

  final Map<String, dynamic> post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.forum_outlined,
                    color: colors.onTertiaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['title']?.toString() ?? 'Post',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${post['community_name'] ?? 'Community'} • ${post['author_name'] ?? 'Member'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_up, color: colors.primary),
                  Text('${(post['upvotes'] ?? 0) - (post['downvotes'] ?? 0)}',
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
