import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus_app/features/chat/presentation/pages/chat_page.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../injection_container.dart';
import '../../../knowledge_base/domain/entities/knowledge_base.dart';
import '../../domain/entities/document.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';

class DocumentsPage extends StatelessWidget {
  final KnowledgeBase kb;
  const DocumentsPage({super.key, required this.kb});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DocumentBloc>()
        ..add(DocumentsLoadRequested(knowledgeBaseId: kb.id)),
      child: _DocumentsView(kb: kb),
    );
  }
}

class _DocumentsView extends StatefulWidget {
  final KnowledgeBase kb;
  const _DocumentsView({required this.kb});

  @override
  State<_DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<_DocumentsView>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _fabCtrl;
  late Animation<double> _headerFade;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFade = CurvedAnimation(
      parent: _headerCtrl,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fabCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    if (!context.mounted) return;
    context.read<DocumentBloc>().add(DocumentUploadRequested(
          knowledgeBaseId: widget.kb.id,
          filePath: file.path!,
          fileName: file.name,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: NexusAppBar(
        title: widget.kb.name,
        subtitle: 'Documents',
      ),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.secondary.withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KB info card
              FadeTransition(
                opacity: _headerFade,
                child: _KBInfoCard(kb: widget.kb),
              ),

              const SizedBox(height: 20),

              // Section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Row(
                    children: [
                      Text(
                        'DOCUMENTS',
                        style: AppTextStyles.label.copyWith(
                          letterSpacing: 1.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      BlocBuilder<DocumentBloc, DocumentState>(
                        builder: (context, state) {
                          final count = _docCount(state);
                          if (count == 0) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      AppColors.secondary.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              '$count',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Document list
              Expanded(
                child: BlocConsumer<DocumentBloc, DocumentState>(
                  listener: (context, state) {
                    if (state is DocumentFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.surfaceElevated,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    }
                    if (state is DocumentLoaded) {
                      HapticFeedback.lightImpact();
                    }
                  },
                  builder: (context, state) {
                    if (state is DocumentLoading) {
                      return const _DocShimmer();
                    }

                    final docs = _getDocs(state);
                    final isUploading = state is DocumentUploading;
                    final uploadingName = isUploading
                        ? (state).fileName
                        : null;

                    if (docs.isEmpty && !isUploading) {
                      return _EmptyDocState(
                        onUpload: () => _pickAndUpload(context),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      onRefresh: () async {
                        context.read<DocumentBloc>().add(
                            DocumentsLoadRequested(
                                knowledgeBaseId: widget.kb.id));
                        await Future.delayed(
                            const Duration(milliseconds: 600));
                      },
                      child: ListView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        children: [
                          if (isUploading && uploadingName != null)
                            _UploadingCard(fileName: uploadingName),
                          ...docs.asMap().entries.map((e) =>
                              _AnimatedDocCard(
                                doc: e.value,
                                index: e.key,
                                onReprocess: () {
                                  context.read<DocumentBloc>().add(
                                      DocumentReprocessRequested(
                                        documentId: e.value.id,
                                        knowledgeBaseId: widget.kb.id,
                                      ));
                                },
                              )),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Upload FAB
          Positioned(
            bottom: 28,
            right: 24,
            child: ScaleTransition(
              scale: _fabScale,
              child: BlocBuilder<DocumentBloc, DocumentState>(
                builder: (context, state) {
                  final isUploading = state is DocumentUploading;
                  return GestureDetector(
                    onTap: isUploading
                        ? null
                        : () => _pickAndUpload(context),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: isUploading
                            ? const LinearGradient(colors: [
                                Color(0xFF2A2A3A),
                                Color(0xFF2A2A3A)
                              ])
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: isUploading
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.45),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: isUploading
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : const Icon(Icons.upload_file_rounded,
                              color: Colors.white, size: 26),
                    ),
                  );
                },
              ),
            ),
          ),

          // Chat FAB
          Positioned(
            bottom: 100,
            right: 24,
            child: ScaleTransition(
              scale: _fabScale,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, animation, _) =>
                          ChatPage(kb: widget.kb),
                      transitionsBuilder: (_, animation, _, child) =>
                          SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                      transitionDuration:
                          const Duration(milliseconds: 450),
                    ),
                  );
                },
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.secondary, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Document> _getDocs(DocumentState state) {
    if (state is DocumentLoaded) return state.documents;
    if (state is DocumentUploading) return state.documents;
    if (state is DocumentFailure) return state.documents;
    return [];
  }

  int _docCount(DocumentState state) => _getDocs(state).length;
}

// ─── KB info card ─────────────────────────────────────────────────────────────

class _KBInfoCard extends StatelessWidget {
  final KnowledgeBase kb;
  const _KBInfoCard({required this.kb});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_stories_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kb.name,
                      style: AppTextStyles.h4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (kb.description.isNotEmpty)
                    Text(kb.description,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${kb.documentCount}',
                  style: AppTextStyles.statNumber.copyWith(
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
                Text('docs',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated doc card ────────────────────────────────────────────────────────

class _AnimatedDocCard extends StatefulWidget {
  final Document doc;
  final int index;
  final VoidCallback onReprocess;

  const _AnimatedDocCard({
    required this.doc,
    required this.index,
    required this.onReprocess,
  });

  @override
  State<_AnimatedDocCard> createState() => _AnimatedDocCardState();
}

class _AnimatedDocCardState extends State<_AnimatedDocCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.04, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
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
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: _DocCardContent(
              doc: widget.doc,
              onReprocess: widget.onReprocess,
            ),
          ),
        ),
      ),
    );
  }
}

class _DocCardContent extends StatelessWidget {
  final Document doc;
  final VoidCallback onReprocess;
  const _DocCardContent({required this.doc, required this.onReprocess});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // File type icon
        _FileTypeIcon(fileType: doc.fileType),
        const SizedBox(width: 14),

        // Name + meta
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doc.name,
                style: AppTextStyles.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    doc.fileType.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (doc.isReady) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${doc.chunkCount} chunks',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Status / action
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(status: _toBadgeStatus(doc.status)),
            if (doc.isFailed) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onReprocess,
                child: Text(
                  'Retry',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  BadgeStatus _toBadgeStatus(DocumentStatus s) => switch (s) {
        DocumentStatus.ready => BadgeStatus.ready,
        DocumentStatus.processing => BadgeStatus.processing,
        DocumentStatus.failed => BadgeStatus.failed,
        DocumentStatus.pending => BadgeStatus.pending,
      };
}

// ─── File type icon ───────────────────────────────────────────────────────────

class _FileTypeIcon extends StatelessWidget {
  final String fileType;
  const _FileTypeIcon({required this.fileType});

  @override
  Widget build(BuildContext context) {
    final config = switch (fileType.toLowerCase()) {
      'pdf' => (AppColors.error, Icons.picture_as_pdf_rounded),
      'md' || 'markdown' => (AppColors.primary, Icons.code_rounded),
      'txt' => (AppColors.secondary, Icons.article_rounded),
      _ => (AppColors.warning, Icons.insert_drive_file_rounded),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: config.$1.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.$1.withValues(alpha: 0.2)),
      ),
      child: Icon(config.$2, color: config.$1, size: 20),
    );
  }
}

// ─── Uploading card ───────────────────────────────────────────────────────────

class _UploadingCard extends StatefulWidget {
  final String fileName;
  const _UploadingCard({required this.fileName});

  @override
  State<_UploadingCard> createState() => _UploadingCardState();
}

class _UploadingCardState extends State<_UploadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.primary.withValues(alpha: 0.1),
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.fileName,
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Uploading...',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _DocShimmer extends StatefulWidget {
  const _DocShimmer();

  @override
  State<_DocShimmer> createState() => _DocShimmerState();
}

class _DocShimmerState extends State<_DocShimmer>
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
          5,
          (_) => AnimatedBuilder(
            animation: _anim,
            builder: (_, _) => Container(
              height: 72,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Color.lerp(
                    const Color(0xFF16161F),
                    const Color(0xFF1E1E2A),
                    _anim.value),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyDocState extends StatefulWidget {
  final VoidCallback onUpload;
  const _EmptyDocState({required this.onUpload});

  @override
  State<_EmptyDocState> createState() => _EmptyDocStateState();
}

class _EmptyDocStateState extends State<_EmptyDocState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) => Transform.translate(
                offset: Offset(0, -8 * _ctrl.value),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(
                    Icons.upload_file_outlined,
                    color: AppColors.secondary,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('No documents yet', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(
              'Upload PDFs, markdown or text files\nto start chatting with them',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: widget.onUpload,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.upload_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Upload a file',
                        style: AppTextStyles.labelLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}