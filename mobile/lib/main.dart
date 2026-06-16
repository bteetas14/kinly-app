import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/app_router.dart';

void main() {
  usePathUrlStrategy();
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
          seedColor: const Color(0xff0f7b68),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfffaf8f3),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xfffbf9f4),
          foregroundColor: Color(0xff15201d),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xffe2ded5)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xffffffff),
          selectedColor: const Color(0xffd6f4eb),
          side: const BorderSide(color: Color(0xffd8d2c8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xffffffff),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffd8d2c8)),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
