import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_controller.dart';

const _themeModeKey = 'theme_mode';

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(storage: ref.watch(secureStorageProvider))..restore();
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController({required this.storage}) : super(ThemeMode.light);

  final FlutterSecureStorage storage;

  Future<void> restore() async {
    state = _parse(await storage.read(key: _themeModeKey));
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await storage.write(key: _themeModeKey, value: mode.name);
  }

  ThemeMode _parse(String? value) {
    return value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }
}

class ThemeModeToggle extends ConsumerWidget {
  const ThemeModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeControllerProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref
          .read(themeControllerProvider.notifier)
          .setMode(dark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}
