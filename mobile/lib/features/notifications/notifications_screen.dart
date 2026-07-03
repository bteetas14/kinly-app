import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/kinly_brand.dart';
import '../../core/responsive.dart';
import '../../core/theme_controller.dart';
import '../../core/widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiClientProvider);
    return Scaffold(
      appBar: AppBar(
        title: const KinlyTitle(text: 'Notifications'),
        actions: const [MobileThemeModeAction()],
      ),
      body: KinlyPageFrame(
        maxWidth: 760,
        child: AsyncList(
          future: _load(api),
          emptyMessage: 'No notifications yet.',
          itemBuilder: (context, item) {
            final colors = Theme.of(context).colorScheme;
            final unread = item['read_at'] == null;
            final type = item['type']?.toString() ?? '';
            return Card(
              color: Color.alphaBlend(
                (unread ? colors.primary : colors.secondary)
                    .withValues(alpha: unread ? 0.06 : 0.04),
                colors.surface,
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: unread
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  foregroundColor:
                      unread ? colors.primary : colors.onSurfaceVariant,
                  child: Icon(_notificationIcon(type)),
                ),
                title: Text(
                  item['title']?.toString() ?? 'Notification',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(item['body']?.toString() ?? ''),
                onTap: () => api.patchMap(
                    '/notifications/${item['id']}/read', <String, dynamic>{}),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<List<dynamic>> _load(ApiClient api) async {
    final data = await api.getMap('/notifications');
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }

  IconData _notificationIcon(String type) {
    return switch (type) {
      'reply' => Icons.reply_rounded,
      'mention' => Icons.alternate_email_rounded,
      'helpful_vote' => Icons.thumb_up_alt_rounded,
      'brand_response' => Icons.verified_rounded,
      'new_badge' => Icons.workspace_premium_rounded,
      'community_activity' => Icons.forum_rounded,
      'review_reminder' => Icons.update_rounded,
      'follow' => Icons.person_add_alt_1_rounded,
      _ => Icons.notifications_rounded,
    };
  }
}
