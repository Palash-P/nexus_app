import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus_app/features/documents/presentation/pages/documents_page.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/knowledge_base.dart';
import '../bloc/kb_bloc.dart';
import '../bloc/kb_event.dart';
import '../bloc/kb_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<KBBloc>()..add(const KBLoadRequested()),
        ),
        BlocProvider.value(value: sl<AuthBloc>()),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _fabController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundOrbs(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _HomeHeader(),
                  ),
                ),

                // Stats row
                FadeTransition(
                  opacity: _headerFade,
                  child: const _StatsRow(),
                ),

                const SizedBox(height: 24),

                // Section title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'KNOWLEDGE BASES',
                        style: AppTextStyles.label.copyWith(
                          letterSpacing: 1.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      BlocBuilder<KBBloc, KBState>(
                        builder: (context, state) {
                          if (state is KBLoaded) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                '${state.knowledgeBases.length}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // KB list
                Expanded(
                  child: BlocConsumer<KBBloc, KBState>(
                    listener: (context, state) {
                      if (state is KBFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: AppColors.surfaceElevated,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is KBLoading) return const _ShimmerList();

                      if (state is KBLoaded || state is KBCreating) {
                        final kbs = state is KBLoaded
                            ? state.knowledgeBases
                            : (state as KBCreating).knowledgeBases;
                        final isCreating = state is KBCreating;

                        if (kbs.isEmpty && !isCreating) {
                          return const _EmptyState();
                        }

                        return RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.surfaceElevated,
                          onRefresh: () async {
                            context
                                .read<KBBloc>()
                                .add(const KBLoadRequested());
                            await Future.delayed(
                                const Duration(milliseconds: 600));
                          },
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            children: [
                              ...kbs.asMap().entries.map((entry) {
                                return _AnimatedKBCard(
                                  kb: entry.value,
                                  index: entry.key,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (_, animation, _) =>
                                            DocumentsPage(kb: entry.value),
                                        transitionsBuilder: (_, animation, _, child) =>
                                            SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(1, 0),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          )),
                                          child: FadeTransition(
                                              opacity: animation, child: child),
                                        ),
                                        transitionDuration:
                                            const Duration(milliseconds: 400),
                                      ),
                                    );
                                    // Refresh KB list when returning
                                    if (context.mounted) {
                                      context.read<KBBloc>().add(const KBLoadRequested());
                                    }
                                  },
                                );
                              }),
                              if (isCreating) const _CreatingCard(),
                            ],
                          ),
                        );
                      }

                      return const _EmptyState();
                    },
                  ),
                ),
              ],
            ),
          ),

          // FAB
          Positioned(
            bottom: 28,
            right: 24,
            child: ScaleTransition(
              scale: _fabScale,
              child: _CreateKBFAB(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Your workspace', style: AppTextStyles.h2),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Avatar + logout
          GestureDetector(
            onTap: () => _showLogoutSheet(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ·';
    if (hour < 17) return 'Good afternoon ·';
    return 'Good evening ·';
  }

  void _showLogoutSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogoutSheet(
        onLogout: () {
          Navigator.pop(context);
          context.read<AuthBloc>().add(const AuthLogoutRequested());
        },
      ),
    );
  }
}

// ─── Stats row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KBBloc, KBState>(
      builder: (context, state) {
        int kbCount = 0;
        int docCount = 0;
        int chunkCount = 0;

        if (state is KBLoaded) {
          kbCount = state.knowledgeBases.length;
          docCount = state.knowledgeBases
              .fold(0, (sum, kb) => sum + kb.documentCount);
          chunkCount =
              state.knowledgeBases.fold(0, (sum, kb) => sum + kb.totalChunks);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              _StatCard(
                value: '$kbCount',
                label: 'Bases',
                color: AppColors.primary,
                delay: const Duration(milliseconds: 100),
              ),
              const SizedBox(width: 10),
              _StatCard(
                value: '$docCount',
                label: 'Documents',
                color: AppColors.secondary,
                delay: const Duration(milliseconds: 200),
              ),
              const SizedBox(width: 10),
              _StatCard(
                value: _formatNumber(chunkCount),
                label: 'Chunks',
                color: AppColors.warning,
                delay: const Duration(milliseconds: 300),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _StatCard extends StatefulWidget {
  final String value;
  final String label;
  final Color color;
  final Duration delay;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Text(
                    widget.value,
                    style: AppTextStyles.statNumber.copyWith(
                      color: widget.color,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated KB card ────────────────────────────────────────────────────────

class _AnimatedKBCard extends StatefulWidget {
  final KnowledgeBase kb;
  final int index;
  final VoidCallback onTap;

  const _AnimatedKBCard({
    required this.kb,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedKBCard> createState() => _AnimatedKBCardState();
}

class _AnimatedKBCardState extends State<_AnimatedKBCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.05, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            onTap: widget.onTap,
            padding: const EdgeInsets.all(18),
            child: _KBCardContent(kb: widget.kb),
          ),
        ),
      ),
    );
  }
}

class _KBCardContent extends StatelessWidget {
  final KnowledgeBase kb;
  const _KBCardContent({required this.kb});

  @override
  Widget build(BuildContext context) {
    final accent = _accentForId(kb.id);

    return Row(
      children: [
        // Icon box
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: accent.withOpacity(0.25)),
          ),
          child: Icon(
            _iconForIndex(kb.id),
            color: accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),

        // Name + meta
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kb.name,
                style: AppTextStyles.h4,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.description_outlined,
                      size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(
                    '${kb.documentCount} doc${kb.documentCount != 1 ? 's' : ''}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.grid_view_rounded,
                      size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(
                    '${_formatChunks(kb.totalChunks)} chunks',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Status + chevron
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(
              status: kb.documentCount > 0
                  ? BadgeStatus.ready
                  : BadgeStatus.pending,
            ),
            const SizedBox(height: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ],
    );
  }

  Color _accentForId(String id) {
  final colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.warning,
    const Color(0xFFEC4899),
    const Color(0xFF06B6D4),
  ];
  return colors[id.hashCode.abs() % colors.length];
}

IconData _iconForIndex(String id) {
  final icons = [
    Icons.auto_stories_rounded,
    Icons.monitor_rounded,
    Icons.balance_rounded,
    Icons.science_rounded,
    Icons.business_center_rounded,
  ];
  return icons[id.hashCode.abs() % icons.length];
}

  String _formatChunks(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ─── Shimmer loading ─────────────────────────────────────────────────────────

class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          4,
          (i) => AnimatedBuilder(
            animation: _anim,
            builder: (_, _) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 78,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFF16161F),
                    const Color(0xFF1E1E2A),
                    _anim.value,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatefulWidget {
  const _EmptyState();

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => Transform.translate(
              offset: Offset(0, -6 * _ctrl.value),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('No knowledge bases yet', style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text(
            'Tap + to create your first one',
            style:
                AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Creating card placeholder ───────────────────────────────────────────────

class _CreatingCard extends StatefulWidget {
  const _CreatingCard();

  @override
  State<_CreatingCard> createState() => _CreatingCardState();
}

class _CreatingCardState extends State<_CreatingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        height: 78,
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.primary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.1),
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Creating knowledge base...',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.primary.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _CreateKBFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showCreateSheet(context);
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<KBBloc>(),
        child: const _CreateKBSheet(),
      ),
    );
  }
}

// ─── Create KB bottom sheet ───────────────────────────────────────────────────

class _CreateKBSheet extends StatefulWidget {
  const _CreateKBSheet();

  @override
  State<_CreateKBSheet> createState() => _CreateKBSheetState();
}

class _CreateKBSheetState extends State<_CreateKBSheet>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _sheetCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<KBBloc, KBState>(
      listener: (context, state) {
        if (state is KBLoaded || state is KBFailure) {
          Navigator.pop(context);
        }
      },
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text('New knowledge base', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(
                  'Give it a name and optional description',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),

                // Name field
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textPrimary),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'NAME',
                    hintText: 'e.g. Company Docs',
                  ),
                ),
                const SizedBox(height: 14),

                // Description field
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'DESCRIPTION',
                    hintText: 'What documents will you add?',
                  ),
                ),
                const SizedBox(height: 24),

                BlocBuilder<KBBloc, KBState>(
                  builder: (context, state) {
                    return GradientButton(
                      label: 'Create knowledge base',
                      isLoading: state is KBCreating,
                      onPressed: state is KBCreating
                          ? null
                          : () {
                              if (!_formKey.currentState!.validate()) return;
                              HapticFeedback.mediumImpact();
                              context.read<KBBloc>().add(KBCreateRequested(
                                    name: _nameCtrl.text.trim(),
                                    description: _descCtrl.text.trim(),
                                  ));
                            },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Logout sheet ─────────────────────────────────────────────────────────────

class _LogoutSheet extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutSheet({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: const Icon(Icons.logout_rounded,
                color: AppColors.error, size: 22),
          ),
          const SizedBox(height: 14),
          Text('Sign out', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'You\'ll need to sign in again to access your knowledge bases.',
            style:
                AppTextStyles.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Sign out',
                  style: AppTextStyles.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background orbs ──────────────────────────────────────────────────────────

class _BackgroundOrbs extends StatelessWidget {
  const _BackgroundOrbs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.primary.withOpacity(0.1),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.secondary.withOpacity(0.08),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }
}