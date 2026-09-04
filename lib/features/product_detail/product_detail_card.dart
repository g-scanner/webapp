// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/models.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/utils.dart';
import '../../services/analyzer_service.dart';
import 'widgets/widgets.dart';

export 'widgets/widgets.dart';

class ProductDetailCard extends StatefulWidget {
  final Product product;
  final ValueNotifier<Product?>? productNotifier;
  final ValueNotifier<String?>? reportIdNotifier;
  final bool isLoading;
  final VoidCallback onBack;
  final Future<void> Function(String barcode, Map<String, dynamic> reportData)
  onReportSubmit;
  final Future<void> Function(Product updatedProduct) onProductUpdate;
  final UserSettings userSettings;
  final Future<void> Function(String barcode)? onDeleteHistoryByBarcode;
  final ValueNotifier<bool>? isInHistoryNotifier;
  final bool hasReportedThisSession;
  final String? userReportId;
  final Future<void> Function(String reportId)? onDeleteReport;
  final bool useResponsiveWrapper;
  final bool showReportLink;
  final bool showScanDate;
  final String? scannedAt;
  final void Function(Product product)? onViewReport;

  const ProductDetailCard({
    super.key,
    required this.product,
    this.productNotifier,
    this.reportIdNotifier,
    this.isLoading = false,
    required this.onBack,
    required this.onReportSubmit,
    required this.onProductUpdate,
    required this.userSettings,
    this.onDeleteHistoryByBarcode,
    this.isInHistoryNotifier,
    this.hasReportedThisSession = false,
    this.userReportId,
    this.onDeleteReport,
    this.useResponsiveWrapper = true,
    this.showReportLink = true,
    this.showScanDate = true,
    this.scannedAt,
    this.onViewReport,
  });

  @override
  State<ProductDetailCard> createState() => _ProductDetailCardState();
}

class _ProductDetailCardState extends State<ProductDetailCard> {
  final ScrollController _scrollController = ScrollController();
  bool _hasJustReported = false;

  Product get currentProduct => widget.productNotifier?.value ?? widget.product;

  bool get _hasUserReported {
    if (widget.reportIdNotifier != null) {
      return widget.reportIdNotifier!.value != null;
    }
    return widget.hasReportedThisSession || _hasJustReported;
  }

  String? get _effectiveUserReportId {
    if (widget.reportIdNotifier != null) {
      return widget.reportIdNotifier!.value;
    }
    return widget.userReportId;
  }

  @override
  void initState() {
    super.initState();
    widget.productNotifier?.addListener(_onProductNotifierChanged);
    widget.reportIdNotifier?.addListener(_onReportIdNotifierChanged);
    widget.isInHistoryNotifier?.addListener(_onIsInHistoryChanged);
  }

  @override
  void dispose() {
    widget.productNotifier?.removeListener(_onProductNotifierChanged);
    widget.reportIdNotifier?.removeListener(_onReportIdNotifierChanged);
    widget.isInHistoryNotifier?.removeListener(_onIsInHistoryChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onProductNotifierChanged() {
    if (mounted) setState(() {});
  }

  void _onReportIdNotifierChanged() {
    if (mounted) setState(() {});
  }

  void _onIsInHistoryChanged() {
    if (mounted) setState(() {});
  }

  String _translateGlutenStatus(GlutenSafetyStatus status) {
    switch (status) {
      case GlutenSafetyStatus.adatto:
        return "product.glutenStatus.safe".tr();
      case GlutenSafetyStatus.nonAdatto:
        return "product.glutenStatus.unsafe".tr();
      case GlutenSafetyStatus.incerto:
        return "product.glutenStatus.uncertain".tr();
      case GlutenSafetyStatus.sconosciuto:
        return "product.glutenStatus.noData".tr();
    }
  }

  void _showReportBottomSheet(BuildContext parentContext) {
    showSubmitReportBottomSheet(
      context: parentContext,
      currentProduct: currentProduct,
      userSettings: widget.userSettings,
      onReportSubmit: widget.onReportSubmit,
      onSubmitted: () {
        if (mounted) {
          setState(() {
            _hasJustReported = true;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Product currentProduct =
        widget.productNotifier?.value ?? widget.product;
    final bool showSkeleton =
        widget.isLoading && widget.productNotifier?.value == null;

    final String currentLang = widget.userSettings.preferredLanguage;
    final String productName = currentProduct.getName(currentLang);
    final String productBrand = currentProduct.getBrand(currentLang);
    final String displayedIngredients = currentProduct
        .getIngredients(currentLang)
        .replaceAll('\$', '')
        .trim();
    final List<String> rawAllergens = currentProduct
        .getAllergens(currentLang)
        .map((a) => a.replaceAll('\$', '').trim())
        .toList();

    // BUG 2 FIX: distinzione semantica tra dati mancanti e dati noti ma vuoti.
    // hasAllergenData = true → allergensMap ha almeno una chiave lingua (anche con lista vuota = "nessuno dichiarato")
    // hasAllergenData = false → allergensMap è completamente assente = Ghost Product / dati non acquisiti
    final bool hasAllergenData = currentProduct.hasAllergenData;
    final bool hasIngredientData = currentProduct.hasIngredientData;

    final bool isReported =
        (currentProduct.pendingReportsCount > 0) || _hasUserReported;

    final analysis = AnalyzerService.analyzeGlutenSafety(
      name: productName,
      brand: productBrand,
      ingredients: displayedIngredients,
      allergensList: rawAllergens,
      reportCount: currentProduct.pendingReportsCount,
      categoriesTags: const [],
      strictMode: widget.userSettings.strictMode,
      warnAdditives: widget.userSettings.warnAdditives,
      alertLactose: widget.userSettings.alertLactose,
      preferredLanguage: currentLang,
    );

    final List<String> displayedAllergens = analysis.allergens;

    final GlutenSafetyStatus effectiveStatus = showSkeleton
        ? GlutenSafetyStatus.sconosciuto
        : (isReported ? GlutenSafetyStatus.incerto : analysis.status);
    final String displayedReason = showSkeleton
        ? "product.analysis.unknown".tr()
        : (isReported
              ? "product.alert.activeReportWarning".tr()
              : analysis.reason);
    final List<IngredientAnalyzed> displayedIngredientsAnalyzed =
        analysis.ingredientsAnalyzed;

    final bool containsLactose = AnalyzerService.checkLactose(
      displayedIngredients,
      displayedAllergens,
    );

    final bool showLactoseWarning =
        widget.userSettings.alertLactose && containsLactose;

    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    final bool canDeleteHistory =
        widget.onDeleteHistoryByBarcode != null &&
        (widget.isInHistoryNotifier?.value ?? true);
    final bool canDeleteReport =
        widget.onDeleteReport != null &&
        _effectiveUserReportId != null &&
        _effectiveUserReportId!.isNotEmpty;
    final bool showActionsSkeleton =
        widget.isInHistoryNotifier != null &&
        !widget.isInHistoryNotifier!.value &&
        _effectiveUserReportId == null;

    // Utilizziamo uno Scaffold interno per gestire la sua AppBar personale
    final scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
          onPressed: widget.onBack,
        ),
        title: Center(
          child: Text(
            "product.titles.scanDetail".tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          // Durante il caricamento (prodotto non ancora in cronologia): shimmer skeleton.
          // Una volta salvato in history o se c'è già una segnalazione: bottone reale.
          if (showActionsSkeleton)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Skeletonizer(
                enabled: true,
                child: IconButton(
                  color: cardBg,
                  onPressed: () {},
                  icon: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else if (canDeleteHistory || canDeleteReport)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              color: cardBg,
              onSelected: (value) {
                if (value == 'delete_history') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: cardBg,
                      title: Text(
                        "product.deleteHistory.confirmTitle".tr(),
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      content: Text(
                        "product.deleteHistory.confirmBody".tr(),
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                          child: Text("common.actions.cancel".tr()),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onDeleteHistoryByBarcode!(
                              currentProduct.barcode,
                            );
                            widget.onBack();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.error,
                          ),
                          child: Text("common.actions.delete".tr()),
                        ),
                      ],
                    ),
                  );
                } else if (value == 'delete_report') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: cardBg,
                      title: Text(
                        "product.deleteReport.confirmTitle".tr(),
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      content: Text(
                        "product.deleteReport.confirmBody".tr(),
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                          child: Text("common.actions.cancel".tr()),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            if (_effectiveUserReportId != null) {
                              await widget.onDeleteReport!(
                                _effectiveUserReportId!,
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.error,
                          ),
                          child: Text("common.actions.delete".tr()),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                if (canDeleteHistory)
                  PopupMenuItem(
                    value: 'delete_history',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: colorScheme.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "product.deleteHistory.menuLabel".tr(),
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (canDeleteReport)
                  PopupMenuItem(
                    value: 'delete_report',
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: colorScheme.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "product.deleteReport.menuLabel".tr(),
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: Skeletonizer(
        enabled: showSkeleton,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero Section (Stato Globale) ──────────────────────────
              SafetyStatusCard(
                effectiveStatus: effectiveStatus,
                productName: productName,
                productBrand: productBrand,
                barcode: currentProduct.barcode,
                showScanDate: widget.showScanDate,
                scannedAt: widget.scannedAt,
                lastUpdated: currentProduct.lastUpdated,
              ),
              const SizedBox(height: 24),

              // ── Valutazione Glutine ───────────────────────────────────
              Builder(
                builder: (context) {
                  final bool hasActiveReport =
                      widget.showReportLink &&
                      widget.onViewReport != null &&
                      (currentProduct.pendingReportsCount > 0 ||
                          _hasUserReported);

                  // On-the-fly: calcola lo stato originale ignorando report
                  String displayedReasonWithOldStatus = displayedReason;
                  if (hasActiveReport) {
                    final origAnalysisCopy =
                        AnalyzerService.analyzeGlutenSafety(
                          name: productName,
                          brand: productBrand,
                          ingredients: displayedIngredients,
                          allergensList: displayedAllergens,
                          reportCount: 0,
                          categoriesTags: const [],
                          strictMode: widget.userSettings.strictMode,
                          warnAdditives: widget.userSettings.warnAdditives,
                          alertLactose: widget.userSettings.alertLactose,
                          preferredLanguage: currentLang,
                          ignoreReports: true,
                        );
                    if (origAnalysisCopy.status != effectiveStatus) {
                      final String oldStatusTranslated = _translateGlutenStatus(
                        origAnalysisCopy.status,
                      );
                      String cleanReason = displayedReason.trim();
                      if (cleanReason.endsWith('.')) {
                        cleanReason = cleanReason.substring(
                          0,
                          cleanReason.length - 1,
                        );
                      }
                      final String prevStatusText =
                          "product.alert.previousStatus".tr(
                            namedArgs: {"status": oldStatusTranslated},
                          );
                      displayedReasonWithOldStatus =
                          "$cleanReason. $prevStatusText";
                    }
                  }

                  return GlutenEvaluationCard(
                    displayedReason: displayedReasonWithOldStatus,
                    hasActiveReport: hasActiveReport,
                    onViewReport: () => widget.onViewReport!(currentProduct),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Avviso Lattosio (se presente) ─────────────────────────
              if (showLactoseWarning) ...[
                const LactoseAlertSection(),
                const SizedBox(height: 24),
              ],

              // ── Allergeni Dichiarati ──────────────────────────────────
              AllergenTagsSection(
                hasAllergenData: hasAllergenData,
                displayedAllergens: displayedAllergens,
              ),
              const SizedBox(height: 24),

              // ── Analisi Ingredienti ───────────────────────────────────
              IngredientsAnalysisView(
                displayedIngredients: displayedIngredients,
                displayedIngredientsAnalyzed: displayedIngredientsAnalyzed,
                hasIngredientData: hasIngredientData,
              ),
              const SizedBox(height: 24),

              // ── Blocco Info / Avvertenze ─────────────────────────────
              const ProductWarningCard(),
              const SizedBox(height: 24),

              // ── Pulsante Segnalazione ──────────────────────────
              ReportActionButton(
                hasUserReported: _hasUserReported,
                pendingReportsCount: currentProduct.pendingReportsCount,
                onReportPressed: () => _showReportBottomSheet(context),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );

    if (widget.useResponsiveWrapper) {
      return ResponsiveMaxCardWidth(child: scaffold);
    }
    return scaffold;
  }
}
