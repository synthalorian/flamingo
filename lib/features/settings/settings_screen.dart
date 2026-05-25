import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/crt_background.dart';
import '../../core/widgets/glow_container.dart';

/// Settings screen with theme picker.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(themeIndexProvider);
    final cs = Theme.of(context).colorScheme;

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
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.1),
                      cs.primary.withValues(alpha: 0.5),
                      cs.primary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Theme section header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, size: 16, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      'THEME',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
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
                        onTap: () =>
                            ref.read(themeIndexProvider.notifier).setTheme(i),
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

class _ThemeCard extends StatefulWidget {
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
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnim = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    if (widget.active) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ThemeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.active && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = widget.name.accentColor;

    final previewBg = _previewBg(widget.index);
    final previewPrimary = _previewPrimary(widget.index);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return Transform.scale(
          scale: widget.active ? _pulseAnim.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.active
                  ? [
                      BoxShadow(
                        color: ac.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: widget.active
                  ? ac.withValues(alpha: 0.1)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              surfaceTintColor: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.active
                          ? ac.withValues(alpha: 0.8)
                          : cs.outlineVariant.withValues(alpha: 0.2),
                      width: widget.active ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Theme preview swatch with glow
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: previewBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.3),
                          ),
                          boxShadow: widget.active
                              ? [
                                  BoxShadow(
                                    color: previewPrimary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            widget.name.icon,
                            color: previewPrimary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name + description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name.label,
                              style: TextStyle(
                                color: widget.active ? ac : cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.name.description,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Active indicator
                      if (widget.active)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: ac.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle, color: ac, size: 22),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _previewPrimary(int i) {
    switch (i) {
      case 0:
        return const Color(0xFFFF69B4);
      case 1:
        return const Color(0xFFD81B60);
      case 2:
        return const Color(0xFFFF69B4);
      case 3:
        return const Color(0xFF8F00FF);
      default:
        return const Color(0xFFFF69B4);
    }
  }

  Color _previewBg(int i) {
    switch (i) {
      case 0:
        return const Color(0xFF0A0012);
      case 1:
        return const Color(0xFFF5F0FA);
      case 2:
        return const Color(0xFF1A0008);
      case 3:
        return const Color(0xFF240037);
      default:
        return const Color(0xFF0A0012);
    }
  }
}
