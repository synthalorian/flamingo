import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/crt_background.dart';
import '../../models/tool_model.dart';
import '../../utils/app_constants.dart';

/// The main home screen showing a grid of tool cards.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: CrtBackground(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appTitle,
                      style: textTheme.headlineLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.appSubtitle,
                      style: textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // ── Tool Grid ───────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tool = AppConstants.tools[index];
                    return _ToolCard(
                      tool: tool,
                      icon: AppConstants.iconForToolId(tool.id),
                    );
                  },
                  childCount: AppConstants.tools.length,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
          ],
        ),
      ),
    );
  }
}

/// A single tool card displayed in the home grid.
class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tool,
    required this.icon,
  });

  final ToolItem tool;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final card = Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: tool.isComingSoon
              ? theme.disabledColor.withValues(alpha: 0.15)
              : colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      color: tool.isComingSoon
          ? theme.disabledColor.withValues(alpha: 0.08)
          : theme.cardTheme.color ?? const Color(0xFF2D1B4D),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: tool.isComingSoon
            ? null
            : () {
                if (context.mounted) {
                  context.push(tool.routePath);
                }
              },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or lock
              if (tool.isComingSoon)
                Icon(
                  Icons.lock_outline,
                  color: theme.disabledColor.withValues(alpha: 0.5),
                  size: 36,
                )
              else
                Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 36,
                ),
              const SizedBox(height: 8),
              // Title
              Text(
                tool.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tool.isComingSoon
                      ? theme.disabledColor.withValues(alpha: 0.5)
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Subtitle / badge
              if (tool.isComingSoon)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.disabledColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Coming soon',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor.withValues(alpha: 0.5),
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TAP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return card;
  }
}
