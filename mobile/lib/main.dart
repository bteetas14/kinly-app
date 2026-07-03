import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/app_router.dart';
import 'core/theme_controller.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: KinlyApp()));
}

class KinlyApp extends ConsumerWidget {
  const KinlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: 'Kinly',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xffb85a7b),
      brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xffe99ab5) : const Color(0xffb14f72),
      onPrimary: dark ? const Color(0xff36101f) : Colors.white,
      primaryContainer:
          dark ? const Color(0xff4b2532) : const Color(0xffffe4eb),
      onPrimaryContainer:
          dark ? const Color(0xffffdce6) : const Color(0xff31111d),
      secondary: dark ? const Color(0xffdfc2b5) : const Color(0xff77564a),
      secondaryContainer:
          dark ? const Color(0xff3b2b27) : const Color(0xffffede6),
      onSecondaryContainer:
          dark ? const Color(0xffffede6) : const Color(0xff2d1914),
      tertiary: dark ? const Color(0xff9ed8c7) : const Color(0xff267261),
      tertiaryContainer:
          dark ? const Color(0xff173a34) : const Color(0xffd9f4ec),
      onTertiaryContainer:
          dark ? const Color(0xffd9f4ec) : const Color(0xff06241f),
      surface: dark ? const Color(0xff1d1d1b) : const Color(0xfffffbf7),
      surfaceContainerLow:
          dark ? const Color(0xff242321) : const Color(0xffffffff),
      surfaceContainerHighest:
          dark ? const Color(0xff2d2b29) : const Color(0xfff4ebe5),
      outlineVariant: dark ? const Color(0xff403a3a) : const Color(0xffeadfda),
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xff171716) : const Color(0xfffbf5ef),
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
            dark ? const Color(0xff171716) : const Color(0xfffbf5ef),
        foregroundColor:
            dark ? const Color(0xfff7efe9) : const Color(0xff21191b),
      ),
      cardTheme: CardThemeData(
        elevation: 0.5,
        color: dark ? const Color(0xff22211f) : const Color(0xfffffcf9),
        shadowColor: Colors.black.withValues(alpha: dark ? 0.26 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(
            color: dark ? const Color(0xff383532) : const Color(0xffeee2dc),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor:
            dark ? const Color(0xff272521) : const Color(0xfffffbf8),
        selectedColor: dark ? const Color(0xff5b2c3b) : const Color(0xffffdce6),
        side: BorderSide(
          color: dark ? const Color(0xff403a3a) : const Color(0xffeadfda),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xff242321) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? const Color(0xff403a3a) : const Color(0xffeadfda),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            dark ? const Color(0xff1d1d1b) : const Color(0xfffffbf7),
        modalBackgroundColor:
            dark ? const Color(0xff1d1d1b) : const Color(0xfffffbf7),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
