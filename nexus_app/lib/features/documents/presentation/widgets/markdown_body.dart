import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nexus_app/core/theme/app_theme.dart';

class NexusMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;

  const NexusMarkdown({
    super.key,
    required this.data,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: MarkdownStyleSheet(
        // Paragraphs
        p: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
          height: 1.65,
        ),

        // Bold
        strong: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          height: 1.65,
        ),

        // Italic
        em: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
          height: 1.65,
        ),

        // H1
        h1: AppTextStyles.h2.copyWith(
          color: AppColors.textPrimary,
          fontSize: 20,
        ),

        // H2
        h2: AppTextStyles.h3.copyWith(
          color: AppColors.textPrimary,
          fontSize: 17,
        ),

        // H3
        h3: AppTextStyles.h4.copyWith(
          color: AppColors.textPrimary,
        ),

        // Code inline
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: AppColors.secondary,
          backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
        ),

        // Code block
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),

        codeblockPadding: const EdgeInsets.all(14),

        // Blockquote
        blockquote: AppTextStyles.body.copyWith(
          color: AppColors.textMuted,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 14),

        // Lists
        listBullet: AppTextStyles.body.copyWith(
          color: AppColors.primary,
          height: 1.65,
        ),
        listIndent: 20,

        // Horizontal rule
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),

        // Spacing
        pPadding: const EdgeInsets.only(bottom: 6),
        h1Padding: const EdgeInsets.only(top: 12, bottom: 6),
        h2Padding: const EdgeInsets.only(top: 10, bottom: 4),
        h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
        blockSpacing: 10,
      ),
    );
  }
}

// Long-press to copy wrapper
class CopyableMarkdown extends StatelessWidget {
  final String data;

  const CopyableMarkdown({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        Clipboard.setData(ClipboardData(text: data));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Copied to clipboard',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: NexusMarkdown(data: data),
    );
  }
}