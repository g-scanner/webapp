// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/models.dart';
import '../../../services/analyzer_service.dart';
import '../../../services/report_rate_limiter.dart';
import 'section_card.dart';

void showSubmitReportBottomSheet({
  required BuildContext context,
  required Product currentProduct,
  required UserSettings userSettings,
  required void Function(String barcode, Map<String, dynamic> reportData)
  onReportSubmit,
  required VoidCallback onSubmitted,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: false,
    constraints: const BoxConstraints(maxWidth: 500),
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetCtx) {
      return _SubmitReportSheetContent(
        currentProduct: currentProduct,
        userSettings: userSettings,
        onReportSubmit: onReportSubmit,
        onSubmitted: onSubmitted,
      );
    },
  );
}

class _SubmitReportSheetContent extends StatefulWidget {
  final Product currentProduct;
  final UserSettings userSettings;
  final void Function(String barcode, Map<String, dynamic> reportData)
  onReportSubmit;
  final VoidCallback onSubmitted;

  const _SubmitReportSheetContent({
    required this.currentProduct,
    required this.userSettings,
    required this.onReportSubmit,
    required this.onSubmitted,
  });

  @override
  State<_SubmitReportSheetContent> createState() =>
      _SubmitReportSheetContentState();
}

class _SubmitReportSheetContentState extends State<_SubmitReportSheetContent> {
  String _reportType = "label_unclear";
  late final TextEditingController _commentsController;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _commentsController = TextEditingController();
    _initRateLimitCooldown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _commentsController.dispose();
    super.dispose();
  }

  void _initRateLimitCooldown() async {
    final sec = await ReportRateLimiter.getRemainingCooldownSeconds();
    if (!mounted) return;
    setState(() {
      _remainingSeconds = sec;
    });

    if (_remainingSeconds > 0) {
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_remainingSeconds > 1) {
            _remainingSeconds--;
          } else {
            _remainingSeconds = 0;
            timer.cancel();
          }
        });
      });
    }
  }

  String _getReportTypeLabel(String type) {
    switch (type) {
      case "label_unclear":
        return "common.reportReasons.unclear".tr();
      case "outdated":
        return "common.reportReasons.outdated".tr();
      case "incorrect_status":
        return "common.reportReasons.wrongStatus".tr();
      case "other":
      default:
        return "common.reportReasons.other".tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final bool isBlocked = _remainingSeconds > 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- M3 Drag Handle ---
            Center(
              child: Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // --- Intestazione ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: Text(
                  "product.actions.reportError".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "product.reportSheet.communityCallout".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Contenuto Scrollabile ---
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Selettore Motivo (Stile Pillola G-Scanner) ---
                    Text(
                      "product.reportSheet.reasonLabel".tr(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),

                    LayoutBuilder(
                      builder: (layoutCtx, constraints) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: PopupMenuButton<String>(
                            constraints: BoxConstraints.tightFor(
                              width: constraints.maxWidth,
                            ),
                            tooltip: "product.reportSheet.reasonTooltip".tr(),
                            elevation: 6,
                            shadowColor: Colors.black.withValues(alpha: 0.12),
                            offset: const Offset(0, 60),
                            color: context.cardBackground,
                            surfaceTintColor: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            itemBuilder: (popCtx) {
                              final options = [
                                "label_unclear",
                                "outdated",
                                "incorrect_status",
                                "other",
                              ];

                              return options.map((type) {
                                return AppRadioPopupMenuItem<String>(
                                  value: type,
                                  label: _getReportTypeLabel(type),
                                  isSelected: _reportType == type,
                                  colorScheme: colorScheme,
                                  onTap: () {
                                    setState(() {
                                      _reportType = type;
                                    });
                                  },
                                );
                              }).toList();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.dropdownPillBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _getReportTypeLabel(_reportType),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down_rounded,
                                    size: 24,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- TextField M3 ---
                    Text(
                      "product.reportSheet.detailsLabel".tr(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentsController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: "product.reportSheet.detailsHint".tr(),
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(18),
                      ),
                    ),

                    // --- Card Informativa Rate Limiting M3 (Stile Avviso OFF) ---
                    if (isBlocked) ...[
                      const SizedBox(height: 20),
                      SectionCard(
                        title: "product.reportSheet.rateLimitTitle".tr(),
                        icon: Icons.error_outline_outlined,
                        isCaution: true,
                        child: Text(
                          "product.reportSheet.rateLimitBanner".tr(),
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // --- Azioni M3 (Pill Buttons) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurface,
                                side: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              child: Text(
                                "common.actions.cancel".tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: isBlocked
                                  ? null
                                  : () {
                                      // 1. Registra sottomissione per il rate limiting
                                      ReportRateLimiter.recordSubmission();

                                      final currentLang =
                                          widget.userSettings.preferredLanguage;
                                      final origAnalysis =
                                          AnalyzerService.analyzeGlutenSafety(
                                            name: widget.currentProduct.getName(
                                              currentLang,
                                            ),
                                            brand: widget.currentProduct
                                                .getBrand(currentLang),
                                            ingredients: widget.currentProduct
                                                .getIngredients(currentLang),
                                            allergensList: widget.currentProduct
                                                .getAllergens(currentLang),
                                            reportCount: 0,
                                            categoriesTags: const [],
                                            strictMode:
                                                widget.userSettings.strictMode,
                                            warnAdditives: widget
                                                .userSettings
                                                .warnAdditives,
                                            alertLactose: widget
                                                .userSettings
                                                .alertLactose,
                                            preferredLanguage: currentLang,
                                            ignoreReports: true,
                                          );

                                      final reportData = {
                                        "type": _reportType,
                                        "comments": _commentsController.text,
                                        "originalStatus":
                                            origAnalysis.status.name,
                                      };

                                      // 2. Chiudi immediatamente il bottom sheet (0 ms)
                                      Navigator.pop(context);

                                      // 3. Notifica ottimistica alla vista sottostante
                                      widget.onSubmitted();

                                      // 4. Lancia persistenza e sync in background
                                      widget.onReportSubmit(
                                        widget.currentProduct.barcode,
                                        reportData,
                                      );
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                                disabledBackgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                disabledForegroundColor: colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Text(
                                isBlocked
                                    ? "product.reportSheet.waitCountdown".tr(
                                        namedArgs: {
                                          'time':
                                              ReportRateLimiter.formatRemainingTime(
                                                _remainingSeconds,
                                              ),
                                        },
                                      )
                                    : "product.reportSheet.submit".tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
