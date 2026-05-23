import 'package:flutter/material.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/flamingo_theme.dart';
import 'utils/app_constants.dart';

/// The root application widget.
/// Wrapped in a [ProviderScope] by main.dart.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.goRouter();

    return MaterialApp.router(
      title: AppConstants.appTitle,
      theme: FlamingoTheme.theme,
      routerConfig: router,
    );
  }
}
