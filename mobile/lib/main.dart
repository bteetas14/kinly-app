import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_router.dart';

void main() {
  runApp(const ProviderScope(child: KinlyApp()));
}

class KinlyApp extends ConsumerWidget {
  const KinlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Kinly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2f6f63),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff7f7f4),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xffdeded8)),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
