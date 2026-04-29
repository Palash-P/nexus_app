import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus_app/features/documents/presentation/widgets/markdown_body.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../../../injection_container.dart';
import '../../../knowledge_base/domain/entities/knowledge_base.dart';
import '../../domain/entities/message.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class ChatPage extends StatelessWidget {
  final KnowledgeBase kb;
  const ChatPage({super.key, required this.kb});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChatBloc>()
        ..add(ChatStarted(knowledgeBaseId: kb.id)),
      child: _ChatView(kb: kb),
    );
  }
}

class _ChatView extends StatefulWidget {
  final KnowledgeBase kb;
  const _ChatView({required this.kb});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> with TickerProviderStateMixin {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  late AnimationController _inputBarCtrl;
  late Animation<double> _inputBarFade;

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(() {
      setState(() => _hasText = _inputCtrl.text.trim().isNotEmpty);
    });
    _inputBarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _inputBarFade = CurvedAnimation(
      parent: _inputBarCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _inputBarCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _inputCtrl.clear();
    setState(() => _hasText = false);
    context.read<ChatBloc>().add(ChatMessageSent(message: text));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: NexusAppBar(
        title: widget.kb.name,
        subtitle: 'AI chat',
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) => GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.read<ChatBloc>().add(
                    ChatNewConversation(
                        knowledgeBaseId: widget.kb.id));
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'New',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Message list
            Expanded(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior(),
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    if (state is ChatReady) _scrollToBottom();
                    if (state is ChatFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.surfaceElevated,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    }
                  },
                  builder: (context, state) {
                    if (state is ChatLoading) {
                      return const _ChatLoadingState();
                    }
                        
                    List<Message> messages = [];
                    if (state is ChatReady) messages = state.messages;
                    if (state is ChatFailure) {
                      messages = state.previousMessages;
                    }
                        
                    if (messages.isEmpty) {
                      return _EmptyChatState(kbName: widget.kb.name);
                    }
                        
                    return ListView.builder(
                      controller: _scrollCtrl,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _AnimatedMessageBubble(
                          message: msg,
                          index: index,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
        
            // Input bar
            FadeTransition(
              opacity: _inputBarFade,
              child: _ChatInputBar(
                controller: _inputCtrl,
                focusNode: _focusNode,
                hasText: _hasText,
                onSend: () => _sendMessage(context),
                isSending: context.select<ChatBloc, bool>(
                  (bloc) =>
                      bloc.state is ChatReady &&
                      (bloc.state as ChatReady).isSending,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _AnimatedMessageBubble extends StatefulWidget {
  final Message message;
  final int index;

  const _AnimatedMessageBubble({
    required this.message,
    required this.index,
  });

  @override
  State<_AnimatedMessageBubble> createState() =>
      _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    final isUser = widget.message.role == MessageRole.user;
    _slide = Tween<Offset>(
      begin: Offset(isUser ? 0.08 : -0.08, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    Future.delayed(
      Duration(milliseconds: widget.message.isStreaming ? 0 : 30),
      () { if (mounted) _ctrl.forward(); },
    );
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
        child: ScaleTransition(
          scale: _scale,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: widget.message.role == MessageRole.user
                ? _UserBubble(message: widget.message)
                : _AssistantBubble(message: widget.message),
          ),
        ),
      ),
    );
  }
}

// ─── User bubble ──────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final Message message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Assistant bubble ─────────────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  final Message message;
  const _AssistantBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // AI avatar
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 8, bottom: 2),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('⬡',
                style: TextStyle(fontSize: 13, color: Colors.white)),
          ),
        ),

        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: message.isStreaming
                    ? const _TypingIndicator()
                    : CopyableMarkdown(data: message.content),
              ),

              // Citations
              if (message.citations.isNotEmpty) ...[
                const SizedBox(height: 8),
                _CitationRow(citations: message.citations),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            final delay = i * 0.2;
            final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = t < 0.5
                ? Curves.easeIn.transform(t * 2)
                : Curves.easeOut.transform((1 - t) * 2);
            return Container(
              margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3 + (opacity * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

// ─── Citations ────────────────────────────────────────────────────────────────

class _CitationRow extends StatelessWidget {
  final List<Citation> citations;
  const _CitationRow({required this.citations});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: citations.map((c) => _CitationChip(citation: c)).toList(),
    );
  }
}

class _CitationChip extends StatelessWidget {
  final Citation citation;
  const _CitationChip({required this.citation});

  @override
  Widget build(BuildContext context) {
    final confidence = citation.confidence;
    final isHighConfidence = confidence != null && confidence > 0.7;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: isHighConfidence ? 0.35 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.article_outlined,
            size: 11,
            color: AppColors.secondary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              citation.pageNumber != null
                  ? '${citation.sourceTitle} · p.${citation.pageNumber}'
                  : citation.sourceTitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (confidence != null) ...[
            const SizedBox(width: 5),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isHighConfidence
                    ? AppColors.success
                    : AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final bool isSending;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ask anything about your documents...',
                  hintStyle: AppTextStyles.body
                      .copyWith(color: AppColors.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 46,
            height: 46,
            child: GestureDetector(
              onTap: (hasText && !isSending) ? onSend : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: (hasText && !isSending)
                      ? AppColors.primaryGradient
                      : const LinearGradient(colors: [
                          Color(0xFF1C1C26),
                          Color(0xFF1C1C26),
                        ]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: (hasText && !isSending)
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                  border: Border.all(
                    color: (hasText && !isSending)
                        ? Colors.transparent
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Icon(
                          Icons.arrow_upward_rounded,
                          color: hasText
                              ? Colors.white
                              : AppColors.textMuted,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyChatState extends StatefulWidget {
  final String kbName;
  const _EmptyChatState({required this.kbName});

  @override
  State<_EmptyChatState> createState() => _EmptyChatStateState();
}

class _EmptyChatStateState extends State<_EmptyChatState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  final _suggestions = const [
    'Summarize the key points',
    'What are the main topics?',
    'Explain the most important concept',
    'List all action items',
  ];

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nexus logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⬡',
                      style:
                          TextStyle(fontSize: 28, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ask Nexus',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 8),
              Text(
                'Chat with your documents in ${widget.kbName}',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Suggestion chips
              Text(
                'TRY ASKING',
                style: AppTextStyles.label.copyWith(
                  letterSpacing: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _suggestions
                    .map((s) => _SuggestionChip(label: s))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<ChatBloc>().add(ChatMessageSent(message: label));
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── Loading state ────────────────────────────────────────────────────────────

class _ChatLoadingState extends StatefulWidget {
  const _ChatLoadingState();

  @override
  State<_ChatLoadingState> createState() => _ChatLoadingStateState();
}

class _ChatLoadingStateState extends State<_ChatLoadingState>
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
    return Center(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.16),
                  _anim.value,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Center(
                child: Text('⬡',
                    style: TextStyle(
                        fontSize: 22, color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Starting conversation...',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}