import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/auth_controller.dart';
import '../../core/kinly_brand.dart';
import '../../core/responsive.dart';
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
  late Future<List<dynamic>> reviews;
  String reviewSort = 'most_helpful';

  @override
  void initState() {
    super.initState();
    detail = _loadDetail();
    reviews = _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const KinlyBackButton(),
        title: const Text('Product'),
      ),
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
          final topReviews =
              data['top_reviews'] as List<dynamic>? ?? <dynamic>[];
          final positive =
              data['positive_reviews'] as List<dynamic>? ?? <dynamic>[];
          final critical =
              data['critical_reviews'] as List<dynamic>? ?? <dynamic>[];
          final related =
              data['related_products'] as List<dynamic>? ?? <dynamic>[];
          final images = product['image_urls'] as List<dynamic>? ?? <dynamic>[];
          final reviewCount = (product['review_count'] as num?)?.toInt() ?? 0;
          return KinlyPageFrame(
            maxWidth: 920,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, kinlyIsDesktop(context) ? 28 : 110),
              children: [
                if (images.isNotEmpty) ProductImages(images: images),
                Text(product['brand_name']?.toString() ?? '',
                    style: Theme.of(context).textTheme.labelLarge),
                Text(product['name']?.toString() ?? 'Product',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(product['description']?.toString() ?? ''),
                const SizedBox(height: 16),
                MetricWrap(product: product),
                const SizedBox(height: 12),
                if (auth.isAuthenticated)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
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
                      OutlinedButton.icon(
                        icon: const Icon(Icons.bookmark_border),
                        label: const Text('Save'),
                        onPressed: () => ref.read(apiClientProvider).postEmpty(
                            '/products/${widget.productId}/save',
                            <String, dynamic>{}),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.favorite_border),
                        label: const Text('Wishlist'),
                        onPressed: () => ref.read(apiClientProvider).postEmpty(
                            '/products/${widget.productId}/wishlist',
                            <String, dynamic>{}),
                      ),
                    ],
                  ),
                if (reviewCount > 2 && topReviews.isNotEmpty) ...[
                  const SectionHeader('Top Reviews'),
                  for (final review in topReviews.cast<Map<String, dynamic>>())
                    ReviewTile(review: review, onChanged: _reloadReviews),
                ],
                if (positive.isNotEmpty) ...[
                  const SectionHeader('Positive Experiences'),
                  for (final review in positive.cast<Map<String, dynamic>>())
                    ReviewTile(
                        review: review,
                        compact: true,
                        onChanged: _reloadReviews),
                ],
                if (critical.isNotEmpty) ...[
                  const SectionHeader('Critical Experiences'),
                  for (final review in critical.cast<Map<String, dynamic>>())
                    ReviewTile(
                        review: review,
                        compact: true,
                        onChanged: _reloadReviews),
                ],
                SectionHeader(
                  'All Reviews',
                  action: PopupMenuButton<String>(
                    icon: const Icon(Icons.sort),
                    onSelected: (value) => setState(() {
                      reviewSort = value;
                      reviews = _loadReviews();
                    }),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                          value: 'most_helpful', child: Text('Most helpful')),
                      PopupMenuItem(
                          value: 'highest_confidence',
                          child: Text('Highest confidence')),
                      PopupMenuItem(value: 'newest', child: Text('Newest')),
                      PopupMenuItem(
                          value: 'highest_rating',
                          child: Text('Highest rating')),
                      PopupMenuItem(
                          value: 'lowest_rating', child: Text('Lowest rating')),
                    ],
                  ),
                ),
                FutureBuilder<List<dynamic>>(
                  future: reviews,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final items = snapshot.data ?? <dynamic>[];
                    if (items.isEmpty) {
                      return const EmptyState('No reviews yet.');
                    }
                    return Column(
                      children: [
                        for (final review in items.cast<Map<String, dynamic>>())
                          ReviewTile(review: review, onChanged: _reloadReviews),
                      ],
                    );
                  },
                ),
                const SectionHeader('Related Products'),
                for (final item in related.cast<Map<String, dynamic>>())
                  ProductCard(
                    product: item,
                    onTap: () => context.go('/products/${item['id']}'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadDetail() {
    return ref.read(apiClientProvider).getMap('/products/${widget.productId}');
  }

  Future<List<dynamic>> _loadReviews() async {
    final data = await ref.read(apiClientProvider).getMap(
        '/products/${widget.productId}/reviews',
        query: {'sort': reviewSort});
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }

  void _reload() {
    setState(() {
      detail = _loadDetail();
      reviews = _loadReviews();
    });
  }

  void _reloadReviews() {
    setState(() => reviews = _loadReviews());
  }
}

class ProductImages extends StatelessWidget {
  const ProductImages({super.key, required this.images});

  final List<dynamic> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              images[index].toString(),
              width: 180,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 180,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MetricWrap extends StatelessWidget {
  const MetricWrap({super.key, required this.product});

  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(label: Text('Score ${_decimal(product['community_score'])}')),
        Chip(
            label: Text('Confidence ${_scorePercent(product['trust_score'])}')),
        Chip(label: Text('${product['review_count'] ?? 0} reviews')),
        Chip(label: Text('${_percent(product['repurchase_rate'])} repurchase')),
        Chip(
            label: Text(
                '${_percent(product['verified_purchase_percentage'])} verified')),
        Chip(
            label: Text(
                '${_percent(product['long_term_review_percentage'])} long-term')),
      ],
    );
  }

  String _decimal(dynamic value) => ((value as num?) ?? 0).toStringAsFixed(1);
  String _percent(dynamic value) =>
      '${((((value as num?) ?? 0) * 100).round())}%';
  String _scorePercent(dynamic value) {
    final number = ((value as num?) ?? 0).toDouble();
    return '${(number > 1 ? number : number * 100).round()}%';
  }
}

class ReviewTile extends ConsumerWidget {
  const ReviewTile(
      {super.key, required this.review, this.compact = false, this.onChanged});

  final Map<String, dynamic> review;
  final bool compact;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xff9ff1df),
                  foregroundColor: const Color(0xff073d34),
                  child: Text('${review['rating'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    review['title']?.toString() ?? 'Review',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                ConfidenceChip(
                    value: review['confidence']?.toString() ?? 'medium'),
              ],
            ),
            const SizedBox(height: 8),
            Text(review['body']?.toString() ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: compact ? 3 : null,
                overflow: compact ? TextOverflow.ellipsis : null),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(label: Text(_purchaseLabel(review['purchase_type']))),
                if (review['repurchased'] == true)
                  const Chip(label: Text('Repurchased')),
                if (review['verified_purchase'] == true)
                  const Chip(label: Text('Verified')),
                if ((review['follow_ups_completed'] as num?) != null)
                  Chip(
                      label:
                          Text('${review['follow_ups_completed']} follow-ups')),
                if ((review['status']?.toString() ?? 'published') !=
                    'published')
                  Chip(label: Text(review['status'].toString())),
              ],
            ),
            if (auth.isAuthenticated && !compact) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                    label: const Text('Helpful'),
                    onPressed: () async {
                      await ref.read(apiClientProvider).postEmpty(
                          '/reviews/${review['id']}/helpful',
                          <String, dynamic>{});
                      onChanged?.call();
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text('Follow up'),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => FollowupSheet(
                          reviewId: review['id'].toString(),
                          onCreated: onChanged),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Report'),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => ReportReviewSheet(
                          reviewId: review['id'].toString(),
                          onReported: onChanged),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _purchaseLabel(dynamic value) {
    return switch (value?.toString()) {
      'gifted' => 'Gifted',
      'pr_package' => 'PR package',
      'sponsored' => 'Sponsored',
      'free_sample' => 'Free sample',
      'beta_tester' => 'Beta tester',
      _ => 'Bought myself',
    };
  }
}

class ConfidenceChip extends StatelessWidget {
  const ConfidenceChip({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final color = switch (value) {
      'high' => Colors.green,
      'low' => Colors.orange,
      _ => Theme.of(context).colorScheme.primary,
    };
    return Chip(
      avatar: Icon(Icons.verified_user_outlined, size: 16, color: color),
      label: Text('${value[0].toUpperCase()}${value.substring(1)}'),
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
  late Future<Map<String, dynamic>> profile;
  int rating = 5;
  bool repurchased = false;
  bool wouldBuyAgain = true;
  bool verifiedPurchase = false;
  String purchaseType = 'bought_myself';

  @override
  void initState() {
    super.initState();
    profile = _loadProfile();
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: profile,
      builder: (context, snapshot) {
        final user = snapshot.data ?? <String, dynamic>{};
        final concerns = user['skin_concerns'] as List<dynamic>? ?? <dynamic>[];
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18),
            child: ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Write review',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                const SizedBox(height: 14),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1')),
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                    ButtonSegment(value: 4, label: Text('4')),
                    ButtonSegment(value: 5, label: Text('5')),
                  ],
                  selected: {rating},
                  onSelectionChanged: (value) =>
                      setState(() => rating = value.first),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: purchaseType,
                  decoration:
                      const InputDecoration(labelText: 'How did you get it?'),
                  items: const [
                    DropdownMenuItem(
                        value: 'bought_myself', child: Text('Bought myself')),
                    DropdownMenuItem(value: 'gifted', child: Text('Gifted')),
                    DropdownMenuItem(
                        value: 'pr_package', child: Text('PR package')),
                    DropdownMenuItem(
                        value: 'sponsored', child: Text('Sponsored')),
                    DropdownMenuItem(
                        value: 'free_sample', child: Text('Free sample')),
                    DropdownMenuItem(
                        value: 'beta_tester', child: Text('Beta tester')),
                  ],
                  onChanged: (value) =>
                      setState(() => purchaseType = value ?? 'bought_myself'),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(
                    controller: body,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: 'Review')),
                const SizedBox(height: 12),
                _ProfileReviewDefaults(user: user),
                const SizedBox(height: 8),
                SwitchListTile(
                    value: wouldBuyAgain,
                    onChanged: (value) => setState(() => wouldBuyAgain = value),
                    title: const Text('Would buy again')),
                SwitchListTile(
                    value: repurchased,
                    onChanged: (value) => setState(() => repurchased = value),
                    title: const Text('Repurchased')),
                SwitchListTile(
                    value: verifiedPurchase,
                    onChanged: (value) =>
                        setState(() => verifiedPurchase = value),
                    title: const Text('Verified purchase')),
                const SizedBox(height: 8),
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
                      'verified_purchase': verifiedPurchase,
                      'purchase_type': purchaseType,
                      'skin_type': user['skin_type']?.toString() ?? '',
                      'hair_type': user['hair_type']?.toString() ?? '',
                      'age_group': user['age_group']?.toString() ?? '',
                      'skin_concerns':
                          concerns.map((item) => item.toString()).toList(),
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
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final auth = ref.read(authControllerProvider);
    final userID = auth.user?['id']?.toString();
    if (userID == null) {
      return <String, dynamic>{};
    }
    return ref.read(apiClientProvider).getMap('/users/$userID');
  }
}

class _ProfileReviewDefaults extends StatelessWidget {
  const _ProfileReviewDefaults({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final concerns = user['skin_concerns'] as List<dynamic>? ?? <dynamic>[];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffddd7cd)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('From your profile',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _DefaultChip(
                  label: user['skin_type'], fallback: 'Skin type unset'),
              _DefaultChip(
                  label: user['hair_type'], fallback: 'Hair type unset'),
              _DefaultChip(label: user['age_group'], fallback: 'Age unset'),
              if (concerns.isEmpty)
                const Chip(label: Text('Concerns unset'))
              else
                for (final concern in concerns)
                  Chip(label: Text(concern.toString())),
            ],
          ),
        ],
      ),
    );
  }
}

class _DefaultChip extends StatelessWidget {
  const _DefaultChip({required this.label, required this.fallback});

  final dynamic label;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final text = label?.toString() ?? '';
    return Chip(label: Text(text.isEmpty ? fallback : text));
  }
}

class FollowupSheet extends ConsumerStatefulWidget {
  const FollowupSheet({super.key, required this.reviewId, this.onCreated});

  final String reviewId;
  final VoidCallback? onCreated;

  @override
  ConsumerState<FollowupSheet> createState() => _FollowupSheetState();
}

class _FollowupSheetState extends ConsumerState<FollowupSheet> {
  final body = TextEditingController();
  String stage = 'day_30';
  bool stillUsing = true;
  bool wouldBuyAgain = true;
  bool repurchased = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Review follow-up',
              style: Theme.of(context).textTheme.titleLarge),
          DropdownButtonFormField<String>(
            initialValue: stage,
            items: const [
              DropdownMenuItem(value: 'day_1', child: Text('Day 1')),
              DropdownMenuItem(value: 'day_30', child: Text('Day 30')),
              DropdownMenuItem(value: 'day_90', child: Text('Day 90')),
              DropdownMenuItem(value: 'day_180', child: Text('Day 180')),
            ],
            onChanged: (value) => setState(() => stage = value ?? 'day_30'),
          ),
          TextField(
              controller: body,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Update')),
          SwitchListTile(
              value: stillUsing,
              onChanged: (value) => setState(() => stillUsing = value),
              title: const Text('Still using')),
          SwitchListTile(
              value: wouldBuyAgain,
              onChanged: (value) => setState(() => wouldBuyAgain = value),
              title: const Text('Would buy again')),
          SwitchListTile(
              value: repurchased,
              onChanged: (value) => setState(() => repurchased = value),
              title: const Text('Repurchased')),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(apiClientProvider)
                  .postMap('/reviews/${widget.reviewId}/followups', {
                'stage': stage,
                'body': body.text,
                'still_using': stillUsing,
                'would_buy_again': wouldBuyAgain,
                'repurchased': repurchased,
              });
              if (context.mounted) {
                Navigator.pop(context);
                widget.onCreated?.call();
              }
            },
            child: const Text('Save follow-up'),
          ),
        ],
      ),
    );
  }
}

class ReportReviewSheet extends ConsumerStatefulWidget {
  const ReportReviewSheet({super.key, required this.reviewId, this.onReported});

  final String reviewId;
  final VoidCallback? onReported;

  @override
  ConsumerState<ReportReviewSheet> createState() => _ReportReviewSheetState();
}

class _ReportReviewSheetState extends ConsumerState<ReportReviewSheet> {
  String reason = 'fake_review';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report review', style: Theme.of(context).textTheme.titleLarge),
          DropdownButtonFormField<String>(
            initialValue: reason,
            items: const [
              DropdownMenuItem(
                  value: 'fake_review', child: Text('Fake review')),
              DropdownMenuItem(
                  value: 'hidden_sponsorship',
                  child: Text('Hidden sponsorship')),
              DropdownMenuItem(
                  value: 'affiliate_spam', child: Text('Affiliate spam')),
              DropdownMenuItem(
                  value: 'suspicious_behavior',
                  child: Text('Suspicious behavior')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) =>
                setState(() => reason = value ?? 'fake_review'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              await ref.read(apiClientProvider).postEmpty(
                  '/reviews/${widget.reviewId}/report',
                  {'reason': reason, 'details': ''});
              if (context.mounted) {
                Navigator.pop(context);
                widget.onReported?.call();
              }
            },
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}
