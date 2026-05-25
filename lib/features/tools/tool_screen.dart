import 'package:flutter/material.dart';

import '../../core/widgets/crt_background.dart';

/// Generic tool screen shell.
/// Takes a [toolId] from the route path parameter and shows a placeholder.
class ToolScreen extends StatelessWidget {
  /// The tool identifier extracted from the route.
  final String toolId;

  const ToolScreen({super.key, required this.toolId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(toolId)),
      body: CrtBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Tool $toolId - coming soon',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
