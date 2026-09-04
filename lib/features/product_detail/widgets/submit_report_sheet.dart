// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme.dart';
import '../../../models/models.dart';
import '../../../services/analyzer_service.dart';

void showSubmitReportBottomSheet({
  required BuildContext context,
  required Product currentProduct,
  required UserSettings userSettings,
  required Future<void> Function(String barcode, Map<String, dynamic> reportData)
  onReportSubmit,
  required VoidCallback onSubmitted,
}) {
  String reportType = "label_unclear";
  final TextEditingController reportCommentsController =
      TextEditingController();
  bool submittingReport = false;

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
                        color: sheetCtx.colorScheme.outlineVariant.withValues(
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
                          color: sheetCtx.colorScheme.error.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.flag_rounded,
                          color: sheetCtx.colorScheme.error,
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
                            color: sheetCtx.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "product.report.communityCallout".tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: sheetCtx.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Dropdown M3 ---
                  Text(
                    "product.report.reasonLabel".tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sheetCtx.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: reportType,
                    icon: Icon(
                      Icons.expand_more,
                      color: sheetCtx.colorScheme.onSurfaceVariant,
                    ),
                    dropdownColor: sheetCtx.cardBackground,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(24),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: sheetCtx.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: "label_unclear",
                        child: Text("product.report.reasonUnclear".tr()),
                      ),
                      DropdownMenuItem(
                        value: "outdated",
                        child: Text("product.report.reasonOutdated".tr()),
                      ),
                      DropdownMenuItem(
                        value: "incorrect_status",
                        child: Text("product.report.reasonWrongStatus".tr()),
                      ),
                      DropdownMenuItem(
                        value: "other",
                        child: Text("product.report.reasonOther".tr()),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setSheetState(() => reportType = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- TextField M3 ---
                  Text(
                    "product.report.detailsHint".tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sheetCtx.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reportCommentsController,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 15,
                      color: sheetCtx.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          "Es: Sulla confezione dice 'può contenere tracce'...",
                      hintStyle: TextStyle(
                        color: sheetCtx.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      filled: true,
                      fillColor: sheetCtx.colorScheme.surfaceContainerHighest,
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
                            foregroundColor:
                                sheetCtx.colorScheme.onSurfaceVariant,
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            "common.actions.cancel".tr(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
                                            strictMode: userSettings.strictMode,
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
                              backgroundColor: sheetCtx.colorScheme.error,
                              foregroundColor: sheetCtx.colorScheme.onError,
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
                                      color: sheetCtx.colorScheme.onError
                                          .withValues(alpha: 0.5),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "product.report.submit".tr(),
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
          );
        },
      );
    },
  );
}
