// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/theme/theme.dart';

class ReportVotingSection extends StatelessWidget {
  final bool isVoteLoading;
  final int currentVote;
  final int upvotes;
  final int downvotes;
  final ValueChanged<int> onVote;

  const ReportVotingSection({
    super.key,
    required this.isVoteLoading,
    required this.currentVote,
    required this.upvotes,
    required this.downvotes,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    if (isVoteLoading) {
      return Skeletonizer(
        enabled: true,
        child: _buildLayout(
          colorScheme: colorScheme,
          upvoteChild: _VoteButton(
            icon: Icons.thumb_up_outlined,
            count: 0,
            isActive: false,
            isUpvote: true,
            colorScheme: colorScheme,
            onTap: () {},
          ),
          downvoteChild: _VoteButton(
            icon: Icons.thumb_down_outlined,
            count: 0,
            isActive: false,
            isUpvote: false,
            colorScheme: colorScheme,
            onTap: () {},
          ),
        ),
      );
    }

    return _buildLayout(
      colorScheme: colorScheme,
      upvoteChild: _VoteButton(
        icon: currentVote == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
        count: upvotes,
        isActive: currentVote == 1,
        isUpvote: true,
        colorScheme: colorScheme,
        onTap: () => onVote(1),
      ),
      downvoteChild: _VoteButton(
        icon: currentVote == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
        count: downvotes,
        isActive: currentVote == -1,
        isUpvote: false,
        colorScheme: colorScheme,
        onTap: () => onVote(-1),
      ),
    );
  }

  Widget _buildLayout({
    required ColorScheme colorScheme,
    required Widget upvoteChild,
    required Widget downvoteChild,
  }) {
    return Column(
      children: [
        Text(
          "report.detail.agreeQuestion".tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [upvoteChild, const SizedBox(width: 12), downvoteChild],
        ),
      ],
    );
  }
}

/// Bottone singolo voto con conteggio e indicatore visivo.
class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final bool isUpvote;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.isActive,
    required this.isUpvote,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Colori attivi coordinati con i selettori di sincronizzazione dati
    final activeColor = isUpvote
        ? colorScheme.statusPrimaryText
        : colorScheme.statusErrorText;
    final activeBg = isUpvote
        ? colorScheme.selectedItemBg
        : colorScheme.selectedErrorItemBg;
    final activeBorder = isUpvote
        ? colorScheme.selectedItemBorder
        : colorScheme.selectedErrorItemBorder;

    final iconColor = isActive ? activeColor : colorScheme.onSurfaceVariant;
    final textColor = isActive ? activeColor : colorScheme.onSurfaceVariant;
    final bgColor = isActive ? activeBg : colorScheme.unselectedItemBg;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? activeBorder : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: isUpvote
              ? colorScheme.splashPrimary
              : colorScheme.splashError,
          highlightColor: isUpvote
              ? colorScheme.selectedItemBg
              : colorScheme.selectedErrorItemBg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: textColor,
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
