import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/crt_background.dart';

/// Settings screen with theme picker.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(themeIndexProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: cs.primary,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SETTINGS',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // Theme section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'THEME',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ),

              // Theme cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final active = i == currentIndex;
                      final name = FlamingoThemeName.values[i];
                      return _ThemeCard(
                        name: name,
                        active: active,
                        index: i,
                        onTap: () => ref.read(themeIndexProvider.notifier).setTheme(i),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final FlamingoThemeName name;
  final bool active;
  final int index;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.name,
    required this.active,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = name.accentColor;

    // Preview colors
    final previewBg = _previewBg(index);
    final previewPrimary = _previewPrimary(index);
    final previewSecondary = _previewSecondary(index);

    return Material(
      color: active ? ac.withValues(alpha: 0.1) : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? ac : cs.outlineVariant.withValues(alpha: 0.3),
              width: active ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Theme preview swatch
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: previewBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Icon(name.icon, color: previewPrimary, size: 22),
                ),
              ),
              const SizedBox(width: 16),

              // Name + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.label,
                      style: TextStyle(
                        color: active ? ac : cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name.description,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Active indicator
              if (active)
                Icon(Icons.check_circle, color: ac, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Color _previewPrimary(int i) {
    switch (i) {
      case 0: return const Color(0xFFFF69B4);
      case 1: return const Color(0xFFD81B60);
      case 2: return const Color(0xFFFF69B4);
      case 3: return const Color(0xFF8F00FF);
      default: return const Color(0xFFFF69B4);
    }
  }

  Color _previewSecondary(int i) {
    switch (i) {
      case 0: return const Color(0xFF00D4FF);
      case 1: return const Color(0xFF0288D1);
      case 2: return const Color(0xFFFF1493);
      case 3: return const Color(0xFF03EDF9);
      default: return const Color(0xFF00D4FF);
    }
  }

  Color _previewBg(int i) {
    switch (i) {
      case 0: return const Color(0xFF0A0012);
      case 1: return const Color(0xFFF5F0FA);
      case 2: return const Color(0xFF1A0008);
      case 3: return const Color(0xFF240037);
      default: return const Color(0xFF0A0012);
    }
  }
}