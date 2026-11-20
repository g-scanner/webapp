// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/app_status_pill.dart';

class SafetyLegendChips extends StatefulWidget {
  const SafetyLegendChips({super.key});

  @override
  State<SafetyLegendChips> createState() => _SafetyLegendChipsState();
}

class _SafetyLegendChipsState extends State<SafetyLegendChips> {
  static const double _kSlotHeight = 118.0;
  static const double _kPointerHeight = 8.5;
  static const double _kPointerWidth = 16.0;

  // Colori semantici ricavati dal tema (stessi usati in SafetyStatusCard)

  int? _selectedIndex;
  int _activeCol = 0;
  bool _wasOpen = false;

  void _onIndicatorTap(int index) {
    if (_selectedIndex == index) {
      // Tap sull'indicatore già attivo -> deselezione (ritorno a stato di riposo)
      setState(() {
        _selectedIndex = null;
        _wasOpen = false;
      });
    } else if (_selectedIndex == null) {
      // Apertura da riposo: la freccetta nasce già posizionata senza scorrere da sinistra
      setState(() {
        _activeCol = index;
        _selectedIndex = index;
        _wasOpen = false;
      });
      // Permette ai successivi cambi tra indicatori di scivolare fluidamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedIndex != null) {
          setState(() {
            _wasOpen = true;
          });
        }
      });
    } else {
      // Cambio indicatore attivo (da A a B) -> scivolamento orizzontale della freccetta
      setState(() {
        _activeCol = index;
        _selectedIndex = index;
        _wasOpen = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final items = _buildItems();
    final containerColor = colorScheme.scannerLegendContainerBg;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "scanner.legend.title".tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(items.length, (index) {
              return Expanded(
                child: _buildIndicatorItem(context, index, items[index]),
              );
            }),
          ),
          const SizedBox(height: 9),
          _buildDetailSlot(context, colorScheme, items),
        ],
      ),
    );
  }

  List<_IndicatorData> _buildItems() {
    return [
      _IndicatorData(
        icon: Icons.check_circle,
        title: "product.status.safe".tr(),
        variant: AppStatusPillVariant.primary,
        pillIcon: Icons.check_circle_outline,
        pillLabel: "scanner.legend.safe.pill".tr(),
        description: "scanner.legend.safe.description".tr(),
      ),
      _IndicatorData(
        icon: Icons.warning,
        title: "product.status.uncertain".tr(),
        variant: AppStatusPillVariant.tertiary,
        pillIcon: Icons.warning_amber,
        pillLabel: "scanner.legend.uncertain.pill".tr(),
        description: "scanner.legend.uncertain.description".tr(),
      ),
      _IndicatorData(
        icon: Icons.cancel,
        title: "product.status.unsafe".tr(),
        variant: AppStatusPillVariant.error,
        pillIcon: Icons.cancel_outlined,
        pillLabel: "scanner.legend.unsafe.pill".tr(),
        description: "scanner.legend.unsafe.description".tr(),
      ),
      _IndicatorData(
        icon: Icons.help,
        title: "product.status.unknown".tr(),
        variant: AppStatusPillVariant.neutral,
        pillIcon: Icons.help_outline,
        pillLabel: "scanner.legend.unknown.pill".tr(),
        description: "scanner.legend.unknown.description".tr(),
      ),
    ];
  }

  Widget _buildIndicatorItem(
    BuildContext context,
    int index,
    _IndicatorData item,
  ) {
    final isSelected = _selectedIndex == index;
    final colorScheme = context.colorScheme;
    final circleBg = AppStatusPill.iconCircleBgForVariant(item.variant, colorScheme);
    final iconColor = AppStatusPill.colorsForVariant(item.variant, colorScheme).text;

    // Geometria precisa della tile per centrare il cerchio perfettamente sull'icona
    const double circleSize = 44.0;
    const double iconTop = 9.0;
    const double tileHeight = 86.0;
    const double circleBottomUnselected = tileHeight - (iconTop + circleSize); // 33.0

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.title,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onIndicatorTap(index),
            borderRadius: BorderRadius.circular(16),
            hoverColor: iconColor.withValues(alpha: 0.08),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double tileWidth = constraints.maxWidth;
                final double horizontalInset = (tileWidth - circleSize) / 2;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: tileHeight,
                    width: tileWidth,
                    child: Stack(
                      children: [
                        // Background che nasce centrato sull'icona e si espande sull'intera tile
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          top: isSelected ? 0.0 : iconTop,
                          bottom: isSelected ? 0.0 : circleBottomUnselected,
                          left: isSelected ? 0.0 : horizontalInset,
                          right: isSelected ? 0.0 : horizontalInset,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: circleBg,
                              borderRadius: BorderRadius.circular(
                                isSelected ? 16.0 : (circleSize / 2),
                              ),
                            ),
                          ),
                        ),
                        // Contenuto con icona allineata esattamente all'area 44x44
                        Padding(
                          padding: const EdgeInsets.only(top: iconTop, bottom: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: tileWidth,
                                height: circleSize,
                                child: Center(
                                  child: Icon(item.icon, color: iconColor, size: 26),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSlot(
    BuildContext context,
    ColorScheme colorScheme,
    List<_IndicatorData> items,
  ) {
    final hasSelection = _selectedIndex != null;
    final cardBg = context.cardBackground;

    return SizedBox(
      key: const ValueKey('_safetyLegendDetailSlot'),
      height: _kSlotHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = constraints.maxWidth / 4;
          final targetPointerX = (_activeCol + 0.5) * columnWidth;

          return Stack(
            children: [
              // A) Stato a riposo: "Testo Puro sul Grigio (Minimal)"
              IgnorePointer(
                ignoring: hasSelection,
                child: AnimatedOpacity(
                  opacity: hasSelection ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: SizedBox.expand(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.65),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "scanner.legend.hintTitle".tr(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "scanner.legend.hintSubtitle".tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // B) Stato attivo: Card Unificata con Freccetta Integrata (Unico path continuo)
              IgnorePointer(
                ignoring: !hasSelection,
                child: AnimatedOpacity(
                  opacity: hasSelection ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: targetPointerX),
                    duration: _wasOpen
                        ? const Duration(milliseconds: 240)
                        : Duration.zero,
                    curve: Curves.easeOutCubic,
                    builder: (context, pointerX, child) {
                      return CustomPaint(
                        painter: _UnifiedCardPainter(
                          color: cardBg,
                          shadowColor: Colors.black.withValues(
                            alpha: context.isDarkMode ? 0.3 : 0.08,
                          ),
                          pointerX: pointerX,
                          pointerWidth: _kPointerWidth,
                          pointerHeight: _kPointerHeight,
                          borderRadius: 20.0,
                        ),
                        child: child,
                      );
                    },
                    child: SizedBox.expand(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          _kPointerHeight + 10,
                          16,
                          10,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeOut,
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: <Widget>[
                                ...previousChildren,
                                ?currentChild,
                              ],
                            );
                          },
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: _buildDetailContent(
                            context,
                            items[_activeCol],
                            ValueKey<int>(_activeCol),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    _IndicatorData item,
    Key key,
  ) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppStatusPill.preset(
          variant: item.variant,
          label: item.pillLabel,
          icon: item.pillIcon,
        ),
        const SizedBox(height: 8),
        Text(
          item.description,
          style: TextStyle(
            fontSize: 12.0,
            height: 1.35,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Disegna la card bianca e il puntatore come un unico poligono geometrico continuo.
/// Non esiste alcuna linea o ombra tra la freccetta e la card: formano un unico corpo solido.
class _UnifiedCardPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final double pointerX;
  final double pointerWidth;
  final double pointerHeight;
  final double borderRadius;

  const _UnifiedCardPainter({
    required this.color,
    required this.shadowColor,
    required this.pointerX,
    required this.pointerWidth,
    required this.pointerHeight,
    required this.borderRadius,
  });

  Path _buildPath(Size size) {
    final path = Path();
    final r = borderRadius;
    final top = pointerHeight;
    final bottom = size.height;
    final left = 0.0;
    final right = size.width;
    final halfW = pointerWidth / 2;

    // Assicura che la freccia rimanga sul tratto rettilineo superiore tra i due raccordi
    final minPointerX = left + r + halfW;
    final maxPointerX = right - r - halfW;
    final safeX = pointerX.clamp(minPointerX, maxPointerX);

    final pLeft = safeX - halfW;
    final pRight = safeX + halfW;

    // Inizio dal vertice superiore sinistro (dopo il raggio)
    path.moveTo(left + r, top);

    // Bordo superiore fino alla freccetta
    path.lineTo(pLeft, top);
    // Salita al vertice della freccetta (y = 0)
    path.lineTo(safeX, 0.0);
    // Discesa al bordo superiore
    path.lineTo(pRight, top);

    // Completamento bordo superiore fino al raccordo destro
    path.lineTo(right - r, top);
    path.arcToPoint(Offset(right, top + r), radius: Radius.circular(r));

    // Bordo destro
    path.lineTo(right, bottom - r);
    path.arcToPoint(Offset(right - r, bottom), radius: Radius.circular(r));

    // Bordo inferiore
    path.lineTo(left + r, bottom);
    path.arcToPoint(Offset(left, bottom - r), radius: Radius.circular(r));

    // Bordo sinistro
    path.lineTo(left, top + r);
    path.arcToPoint(Offset(left + r, top), radius: Radius.circular(r));

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final path = _buildPath(size);

    // Ombra morbida perimetrale esterna (nessuna linea interna o sotto la freccia!)
    if (shadowColor.a > 0) {
      final shadowPaint1 = Paint()
        ..color = shadowColor.withValues(alpha: shadowColor.a * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint1);

      final shadowPaint2 = Paint()
        ..color = shadowColor.withValues(alpha: shadowColor.a * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawPath(path.shift(const Offset(0, 1)), shadowPaint2);
    }

    // Riempimento solido del corpo unico
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _UnifiedCardPainter oldDelegate) =>
      color != oldDelegate.color ||
      shadowColor != oldDelegate.shadowColor ||
      pointerX != oldDelegate.pointerX ||
      pointerWidth != oldDelegate.pointerWidth ||
      pointerHeight != oldDelegate.pointerHeight ||
      borderRadius != oldDelegate.borderRadius;
}

class _IndicatorData {
  final IconData icon;
  final String title;
  final AppStatusPillVariant variant;
  final IconData pillIcon;
  final String pillLabel;
  final String description;

  const _IndicatorData({
    required this.icon,
    required this.title,
    required this.variant,
    required this.pillIcon,
    required this.pillLabel,
    required this.description,
  });
}
