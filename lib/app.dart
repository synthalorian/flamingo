import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/flamingo_theme.dart';
import 'core/theme/theme_provider.dart';

/// The root application widget.
/// Wrapped in a [ProviderScope] by main.dart.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.goRouter();
    final theme = ref.watch(themeDataProvider);

    // Sync legacy static colors so screens using FlamingoColors still work
    FlamingoColors.syncFrom(theme.colorScheme);

    return MaterialApp.router(
      title: 'Flamingo',
      theme: theme,
      routerConfig: router,
    );
  }
}
