import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/crt_background.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/page_transition.dart';
import '../../core/widgets/glow_container.dart';
import '../../models/tool_model.dart';
import '../../utils/app_constants.dart';

/// The main home screen showing a grid of tool cards with neon visuals.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late Animation<double> _headerAnim;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _headerAnim = CurvedAnimation(
      parent: _headerCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  List<ToolItem> get _filteredTools {
    if (_searchQuery.isEmpty) return AppConstants.tools;
    final q = _searchQuery.toLowerCase();
    return AppConstants.tools
        .where(
          (t) =>
              t.title.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: CrtBackground(
        child: AnimatedBackground(
          particleCount: 6,
          colors: [cs.primary, cs.secondary, cs.tertiary],
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Glowing animated header ──
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _headerAnim,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _headerAnim.value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - _headerAnim.value)),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  cs.primary.withValues(alpha: 0.12),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      cs.primary,
                                                      cs.primary.withValues(
                                                        alpha: 0.3,
                                                      ),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: cs.primary
                                                          .withValues(
                                                            alpha: 0.4,
                                                          ),
                                                      blurRadius: 12,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.flash_on,
                                                  color: Colors.black87,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                AppConstants.appTitle,
                                                style: theme
                                                    .textTheme
                                                    .headlineLarge
                                                    ?.copyWith(
                                                      color: cs.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 1,
                                                      shadows: [
                                                        Shadow(
                                                          color: cs.primary
                                                              .withValues(
                                                                alpha: 0.4,
                                                              ),
                                                          blurRadius: 12,
                                                        ),
                                                      ],
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            AppConstants.appSubtitle,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                  letterSpacing: 1,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: cs.primary.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: cs.primary.withValues(
                                                  alpha: 0.2,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.settings_rounded,
                                              color: cs.primary,
                                              size: 22,
                                            ),
                                          ),
                                          onPressed: () =>
                                              context.push('/settings'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Search bar
                                Container(
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHigh.withValues(
                                      alpha: 0.6,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: cs.primary.withValues(alpha: 0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    decoration: InputDecoration(
                                      hintText: 'Search tools...',
                                      hintStyle: TextStyle(
                                        color: cs.onSurfaceVariant.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: cs.primary.withValues(
                                          alpha: 0.6,
                                        ),
                                        size: 20,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Neon divider
                                Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        cs.primary.withValues(alpha: 0.6),
                                        cs.secondary.withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cs.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Tool Grid ──
                _filteredTools.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No tools found',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final tool = _filteredTools[index];
                            return StaggeredToolCard(
                              index: index,
                              tool: tool,
                              icon: AppConstants.iconForToolId(tool.id),
                            );
                          }, childCount: _filteredTools.length),
                        ),
                      ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Staggered entrance animated tool card.
class StaggeredToolCard extends StatefulWidget {
  final int index;
  final ToolItem tool;
  final IconData icon;

  const StaggeredToolCard({
    super.key,
    required this.index,
    required this.tool,
    required this.icon,
  });

  @override
  State<StaggeredToolCard> createState() => _StaggeredToolCardState();
}

class _StaggeredToolCardState extends State<StaggeredToolCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final delay = widget.index * 0.04;
    Future.delayed(Duration(milliseconds: (delay * 1000).round()), () {
      if (mounted) _ctrl.forward();
    });
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tool = widget.tool;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Opacity(
          opacity: _anim.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _anim.value)),
            child: tool.isComingSoon
                ? _buildComingSoonCard(cs)
                : _buildActiveCard(cs),
          ),
        );
      },
    );
  }

  Widget _buildComingSoonCard(ColorScheme cs) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.onSurfaceVariant.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              widget.tool.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Soon',
                style: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCard(ColorScheme cs) {
    final accentColor = widget.tool.accentColor;

    return GestureDetector(
      onTap: () {
        if (context.mounted) {
          context.push(widget.tool.routePath);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: _hovered ? 0.5 : 0.2),
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: _hovered ? 0.15 : 0.05),
              blurRadius: _hovered ? 16 : 8,
              spreadRadius: _hovered ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon with glow
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: accentColor, size: 28),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.tool.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.tool.description,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    accentColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'OPEN',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
