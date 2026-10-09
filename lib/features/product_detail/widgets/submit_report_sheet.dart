// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/models.dart';
import '../../../services/analyzer_service.dart';

void showSubmitReportBottomSheet({
  required BuildContext context,
  required Product currentProduct,
  required UserSettings userSettings,
  required Future<void> Function(
    String barcode,
    Map<String, dynamic> reportData,
  )
  onReportSubmit,
  required VoidCallback onSubmitted,
}) {
  String reportType = "label_unclear";
  final TextEditingController reportCommentsController =
      TextEditingController();
  bool submittingReport = false;

  String getReportTypeLabel(String type) {
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

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: false,
    constraints: const BoxConstraints(maxWidth: 500),
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetCtx) {
      return StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setSheetState) {
          final colorScheme = sheetCtx.colorScheme;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: sheetCtx.cardBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- M3 Drag Handle ---
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // --- Intestazione ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.flag_rounded,
                            color: colorScheme.error,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "product.actions.reportError".tr(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "product.reportSheet.communityCallout".tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

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
                      builder: (context, constraints) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: PopupMenuButton<String>(
                            // 1. Forza il popup a essere largo ESATTAMENTE quanto il bottone:
                            constraints: BoxConstraints.tightFor(
                              width: constraints.maxWidth,
                            ),
                            tooltip: "product.reportSheet.reasonTooltip".tr(),
                            elevation: 6,
                            shadowColor: Colors.black.withValues(alpha: 0.12),
                            offset: const Offset(0, 60),
                            color: sheetCtx.cardBackground,
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
                            itemBuilder: (context) {
                              final options = [
                                "label_unclear",
                                "outdated",
                                "incorrect_status",
                                "other",
                              ];

                              return options.map((type) {
                                return AppRadioPopupMenuItem<String>(
                                  value: type,
                                  label: getReportTypeLabel(type),
                                  isSelected: reportType == type,
                                  colorScheme: colorScheme,
                                  onTap: () =>
                                      setSheetState(() => reportType = type),
                                );
                              }).toList();
                            },
                            // Trigger a Pillola (Full-width, zero bordi)
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      getReportTypeLabel(reportType),
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
                      controller: reportCommentsController,
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
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Azioni M3 (Pill Buttons) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: TextButton(
                            onPressed: submittingReport
                                ? null
                                : () => Navigator.pop(sheetCtx),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.onSurfaceVariant,
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: Text(
                              "common.actions.cancel".tr(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
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
                              onPressed: submittingReport
                                  ? null
                                  : () async {
                                      setSheetState(
                                        () => submittingReport = true,
                                      );
                                      try {
                                        final currentLang =
                                            userSettings.preferredLanguage;
                                        final origAnalysis =
                                            AnalyzerService.analyzeGlutenSafety(
                                              name: currentProduct.getName(
                                                currentLang,
                                              ),
                                              brand: currentProduct.getBrand(
                                                currentLang,
                                              ),
                                              ingredients: currentProduct
                                                  .getIngredients(currentLang),
                                              allergensList: currentProduct
                                                  .getAllergens(currentLang),
                                              reportCount: 0,
                                              categoriesTags: const [],
                                              strictMode:
                                                  userSettings.strictMode,
                                              warnAdditives:
                                                  userSettings.warnAdditives,
                                              alertLactose:
                                                  userSettings.alertLactose,
                                              preferredLanguage: currentLang,
                                              ignoreReports: true,
                                            );
                                        await onReportSubmit(
                                          currentProduct.barcode,
                                          {
                                            "type": reportType,
                                            "comments":
                                                reportCommentsController.text,
                                            "originalStatus":
                                                origAnalysis.status.name,
                                          },
                                        );
                                        onSubmitted();
                                        if (sheetCtx.mounted) {
                                          Navigator.pop(sheetCtx);
                                        }
                                        reportCommentsController.clear();
                                      } catch (err) {
                                        debugPrint('Report submit error: $err');
                                      } finally {
                                        setSheetState(
                                          () => submittingReport = false,
                                        );
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: submittingReport
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onError.withValues(
                                          alpha: 0.5,
                                        ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "product.reportSheet.submit".tr(),
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
          );
        },
      );
    },
  );
}
