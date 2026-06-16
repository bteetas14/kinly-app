import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/kinly_brand.dart';
import '../../core/responsive.dart';
import '../../core/widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiClientProvider);
    return Scaffold(
      appBar: AppBar(title: const KinlyTitle(text: 'Notifications')),
      body: KinlyPageFrame(
        maxWidth: 760,
        child: AsyncList(
          future: _load(api),
          emptyMessage: 'No notifications yet.',
          itemBuilder: (context, item) => Card(
            child: ListTile(
              leading: Icon(item['read_at'] == null
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none),
              title: Text(item['title']?.toString() ?? 'Notification'),
              subtitle: Text(item['body']?.toString() ?? ''),
              onTap: () => api.patchMap(
                  '/notifications/${item['id']}/read', <String, dynamic>{}),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>> _load(ApiClient api) async {
    final data = await api.getMap('/notifications');
    return data['data'] as List<dynamic>? ?? <dynamic>[];
  }
}
