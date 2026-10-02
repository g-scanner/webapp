// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';

class AnalyzedItemData {
  final String productName;
  final String brand;
  final GlutenSafetyStatus status;
  final bool hasLactose;

  AnalyzedItemData({
    required this.productName,
    required this.brand,
    required this.status,
    required this.hasLactose,
  });
}

class HistoryItemTile extends StatefulWidget {
  final ScanHistoryItem item;
  final AnalyzedItemData data;
  final bool isPending;
  final ValueChanged<String> onSelectItem;
  final VoidCallback onLongPress;
  final bool alertLactose;

  const HistoryItemTile({
    super.key,
    required this.item,
    required this.data,
    this.isPending = false,
    required this.onSelectItem,
    required this.onLongPress,
    this.alertLactose = false,
  });

  @override
  State<HistoryItemTile> createState() => _HistoryItemTileState();
}

class _HistoryItemTileState extends State<HistoryItemTile> {
  bool _isHovered = false;

  Widget _buildStatusTag(BuildContext context, GlutenSafetyStatus status) {
    final colorScheme = context.colorScheme;
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case GlutenSafetyStatus.adatto:
        bgColor = colorScheme.primaryContainer.withValues(alpha: 0.15);
        textColor = colorScheme.primary;
        label = "history.item.status.safe".tr();
        icon = Icons.check_circle_outline;
        break;
      case GlutenSafetyStatus.nonAdatto:
        bgColor = colorScheme.errorContainer.withValues(alpha: 0.15);
        textColor = colorScheme.error;
        label = "history.item.status.unsafe".tr();
        icon = Icons.cancel_outlined;
        break;
      case GlutenSafetyStatus.incerto:
        bgColor = colorScheme.tertiaryContainer.withValues(alpha: 0.15);
        textColor = colorScheme.tertiary;
        label = "history.item.status.uncertain".tr();
        icon = Icons.help_outline;
        break;
      case GlutenSafetyStatus.sconosciuto:
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        label = "history.item.status.unknown".tr();
        icon = Icons.search_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Colore dei placeholder skeleton: di default surfaceContainerHighest,
  /// ma su hover si scurisce con un blend di onSurfaceVariant per mantenere
  /// contrasto visibile quando l'overlay hover copre la card.
  Color _skeletonColor(BuildContext context) {
    final colorScheme = context.colorScheme;
    if (_isHovered) {
      return Color.lerp(
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
        0.15,
      )!;
    }
    return colorScheme.surfaceContainerHighest;
  }

  Widget _buildSkeletonStatusPill(BuildContext context) {
    final colorScheme = context.colorScheme;
    final bgColor = colorScheme.tertiaryContainer.withValues(alpha: 0.15);
    final tertiary = colorScheme.tertiary;
    final baseAlpha = _isHovered ? 0.65 : 0.45;
    final highlightAlpha = _isHovered ? 0.35 : 0.20;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Skeletonizer(
        enabled: true,
        effect: ShimmerEffect(
          baseColor: tertiary.withValues(alpha: baseAlpha),
          highlightColor: tertiary.withValues(alpha: highlightAlpha),
        ),
        child: Container(
          width: 52,
          height: 11,
          decoration: BoxDecoration(
            color: tertiary.withValues(alpha: baseAlpha),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildLactoseTag(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            "history.item.lactose".tr(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;
    final skeletonBg = _skeletonColor(context);

    Widget cardContent = Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.isPending)
                      _buildSkeletonStatusPill(context)
                    else
                      _buildStatusTag(context, widget.data.status),
                    if (!widget.isPending &&
                        widget.alertLactose &&
                        widget.data.hasLactose)
                      _buildLactoseTag(context),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.isPending) ...[
                  Skeletonizer(
                    enabled: true,
                    child: Container(
                      width: 220,
                      height: 18,
                      decoration: BoxDecoration(
                        color: skeletonBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Skeletonizer(
                            enabled: true,
                            child: Container(
                              width: 80,
                              height: 13,
                              decoration: BoxDecoration(
                                color: skeletonBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatRelativeDate(widget.item.scannedAt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    widget.data.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.data.brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatRelativeDate(widget.item.scannedAt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Transform.translate(
              offset: const Offset(8, 0),
              child: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cardBg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => widget.onSelectItem(widget.item.barcode),
        onLongPress: widget.isPending ? null : widget.onLongPress,
        onHover: widget.isPending
            ? (hovering) => setState(() => _isHovered = hovering)
            : null,
        hoverColor: colorScheme.surfaceContainerHighest,
        highlightColor: context.surfaceContainerLow,
        child: cardContent,
      ),
    );
  }
}

class HistoryItemSkeleton extends StatelessWidget {
  const HistoryItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 16,
              color: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 20,
              color: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 6),
            Container(
              width: 100,
              height: 14,
              color: colorScheme.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}
