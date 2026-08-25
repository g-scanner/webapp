// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/types.dart';
import 'responsive_wrapper.dart';
import '../services/analyzer_service.dart';

import '../theme/app_theme.dart';

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
  String _reportType = "label_unclear";
  final TextEditingController _reportCommentsController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _submittingReport = false;
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
    _reportCommentsController.dispose();
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
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      useSafeArea: true, // Rispetta la status bar in M3
      useRootNavigator: false,
      constraints: const BoxConstraints(maxWidth: 500),
      backgroundColor:
          Colors.transparent, // Lo sfondo arrotondato lo diamo al Container
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
                      initialValue: _reportType,
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
                        if (val != null) setSheetState(() => _reportType = val);
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
                      controller: _reportCommentsController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 15,
                        color: sheetCtx.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            "Es: Sulla confezione dice 'può contenere tracce'...",
                        hintStyle: TextStyle(
                          color: sheetCtx.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
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
                            onPressed: _submittingReport
                                ? null
                                : () => Navigator.pop(sheetCtx),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  sheetCtx.colorScheme.onSurfaceVariant,
                              minimumSize: const Size(0, 48),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Text(
                              "common.actions.cancel".tr(),
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                            onPressed: _submittingReport
                                ? null
                                : () async {
                                    setSheetState(
                                      () => _submittingReport = true,
                                    );
                                    try {
                                      final currentLang =
                                          widget.userSettings.preferredLanguage;
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
                                      await widget.onReportSubmit(
                                        currentProduct.barcode,
                                        {
                                          "type": _reportType,
                                          "comments":
                                              _reportCommentsController.text,
                                          "originalStatus":
                                              origAnalysis.status.name,
                                        },
                                      );
                                      setState(() {
                                        _hasJustReported = true;
                                      });
                                      if (sheetCtx.mounted) {
                                        Navigator.pop(sheetCtx);
                                      }
                                      _reportCommentsController.clear();
                                    } catch (err) {
                                      print(err);
                                    } finally {
                                      setSheetState(
                                        () => _submittingReport = false,
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
                            child: _submittingReport
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
    final List<String> displayedAllergens = currentProduct
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
      allergensList: displayedAllergens,
      reportCount: currentProduct.pendingReportsCount,
      categoriesTags: const [],
      strictMode: widget.userSettings.strictMode,
      warnAdditives: widget.userSettings.warnAdditives,
      alertLactose: widget.userSettings.alertLactose,
      preferredLanguage: currentLang,
    );

    final GlutenSafetyStatus effectiveStatus = showSkeleton
        ? GlutenSafetyStatus.sconosciuto
        : (isReported
            ? GlutenSafetyStatus.incerto
            : analysis.status);
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

    Color heroBgColor;
    Color heroTextColor;
    String statusBigText;
    IconData statusIcon;

    switch (effectiveStatus) {
      case GlutenSafetyStatus.adatto:
        heroBgColor = colorScheme.primaryContainer.withValues(alpha: 0.15);
        heroTextColor = colorScheme.primary;
        statusBigText = "product.bigStatus.safe".tr();
        statusIcon = Icons.check_circle;
        break;
      case GlutenSafetyStatus.nonAdatto:
        heroBgColor = colorScheme.errorContainer.withValues(alpha: 0.15);
        heroTextColor = colorScheme.error;
        statusBigText = "product.bigStatus.unsafe".tr();
        statusIcon = Icons.cancel;
        break;
      case GlutenSafetyStatus.incerto:
        heroBgColor = colorScheme.tertiaryContainer.withValues(alpha: 0.15);
        heroTextColor = colorScheme.tertiary;
        statusBigText = "product.bigStatus.uncertain".tr();
        statusIcon = Icons.warning;
        break;
      case GlutenSafetyStatus.sconosciuto:
        heroBgColor = colorScheme.surfaceContainerHighest;
        heroTextColor = colorScheme.onSurfaceVariant;
        statusBigText = "product.bigStatus.unknown".tr();
        statusIcon = Icons.help;
        break;
    }

    final bool canDeleteHistory = widget.onDeleteHistoryByBarcode != null &&
        (widget.isInHistoryNotifier?.value ?? true);
    final bool canDeleteReport = widget.onDeleteReport != null &&
        _effectiveUserReportId != null &&
        _effectiveUserReportId!.isNotEmpty;
    final bool showActionsSkeleton = widget.isInHistoryNotifier != null &&
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
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: heroBgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: heroTextColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: heroTextColor, size: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      statusBigText,
                      style: TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.w400,
                        color: heroTextColor,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      productName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      productBrand.isEmpty
                          ? "product.status.unknownBrand".tr()
                          : productBrand,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pillola Barcode
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: heroTextColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code, size: 16, color: heroTextColor),
                          const SizedBox(width: 8),
                          SelectableText(
                            currentProduct.barcode,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: heroTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // DATA AGGIUNTA DA RICHIESTA
                    if (widget.showScanDate) ...[
                      const SizedBox(height: 4),
                      Text(
                        formatScanDate(
                          widget.scannedAt ?? currentProduct.lastUpdated,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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

                  final Widget cardContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 24,
                          left: 24,
                          right: 24,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.leaderboard,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "product.titles.glutenEvaluation".tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          bottom: hasActiveReport ? 20 : 24,
                        ),
                        child: Text(
                          displayedReasonWithOldStatus,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (hasActiveReport) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary.withValues(alpha: 0.04),
                            border: Border(
                              top: BorderSide(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "product.report.goToReport".tr(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(6, 0),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );

                  return Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasActiveReport
                        ? InkWell(
                            onTap: () => widget.onViewReport!(currentProduct),
                            child: cardContent,
                          )
                        : cardContent,
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Avviso Lattosio (se presente) ─────────────────────────
              if (showLactoseWarning) ...[
                _buildSectionCard(
                  title: "product.titles.lactosePresence".tr(),
                  icon: Icons.water_drop,
                  isLactose: true,
                  bgColor: colorScheme.secondaryContainer.withValues(
                    alpha: 0.15,
                  ),
                  child: Text(
                    "product.warnings.lactoseAlertBody".tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // ── Allergeni Dichiarati ──────────────────────────────────
              // Tre stati semantici:
              // 1. hasAllergenData=false → dati non disponibili (Ghost Product)
              // 2. hasAllergenData=true, lista vuota → nessun allergene dichiarato
              // 3. hasAllergenData=true, lista non vuota → mostra gli allergeni
              _buildSectionCard(
                title: "product.titles.declaredAllergens".tr(),
                icon: Icons.coronavirus,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: !hasAllergenData
                      // Stato 1: Nessun dato — informazioni non disponibili (stessa pillola neutrale degli allergeni)
                      ? [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              "product.ingredients.insufficientDataLabel".tr(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ]
                      : displayedAllergens.isNotEmpty
                      // Stato 3: Allergeni dichiarati → mostra chips
                      ? displayedAllergens.map((alg) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              alg,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList()
                      // Stato 2: Dati presenti ma lista vuota → nessuno dichiarato (sicuro)
                      : [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              "product.ingredients.noneLabel".tr(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Analisi Ingredienti ───────────────────────────────────
              _buildSectionCard(
                title: "product.titles.ingredientsAnalysis".tr(),
                icon: Icons.science,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (displayedIngredients.trim().isNotEmpty) ...[
                      Text(
                        displayedIngredients,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                      if (displayedIngredientsAnalyzed.isNotEmpty)
                        const SizedBox(height: 16),
                    ],
                    if (displayedIngredientsAnalyzed.isNotEmpty) ...[
                      ...displayedIngredientsAnalyzed.asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final item = entry.value;
                        final bool showTopDivider =
                            displayedIngredients.trim().isNotEmpty || index > 0;

                        Color pillBg;
                        Color pillText;
                        String pillLabel;

                        switch (item.dangerLevel) {
                          case "danger":
                            pillBg = colorScheme.errorContainer.withValues(
                              alpha: 0.2,
                            );
                            pillText = colorScheme.error;
                            pillLabel = "product.ingredients.dangerBadge".tr();
                            break;
                          case "warning":
                            pillBg = colorScheme.tertiaryContainer.withValues(
                              alpha: 0.2,
                            );
                            pillText = colorScheme.tertiary;
                            pillLabel = "product.ingredients.warningBadge".tr();
                            break;
                          case "uncertain":
                            pillBg = colorScheme.tertiaryContainer.withValues(
                              alpha: 0.15,
                            );
                            pillText = colorScheme.tertiary;
                            pillLabel = "product.ingredients.uncertainBadge"
                                .tr();
                            break;
                          case "safe":
                          default:
                            pillBg = colorScheme.primaryContainer.withValues(
                              alpha: 0.2,
                            );
                            pillText = colorScheme.primary;
                            pillLabel = "product.ingredients.safeBadge".tr();
                            break;
                        }

                        return Container(
                          margin: EdgeInsets.only(top: showTopDivider ? 12 : 0),
                          padding: EdgeInsets.only(
                            top: showTopDivider ? 12 : 0,
                          ),
                          decoration: BoxDecoration(
                            border: showTopDivider
                                ? Border(
                                    top: BorderSide(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                  )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.ingredient,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: pillBg,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      pillLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: pillText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.reason.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.reason,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ] else if (displayedIngredients.trim().isEmpty) ...[
                      Text(
                        // hasIngredientData=false → ghost product: dati non disponibili
                        // hasIngredientData=true ma ingredienti vuoti → prodotto pulito, nessun rischio
                        !hasIngredientData
                            ? "product.ingredients.insufficientDataLabel".tr()
                            : "product.ingredients.noRisksDetected".tr(),
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Blocco Info / Avvertenze ─────────────────────────────
              _buildSectionCard(
                title: "product.warnings.infoTitle".tr(),
                icon: Icons.info_outline,
                isCaution: true,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    children: <TextSpan>[
                      TextSpan(text: "product.warnings.infoPre".tr()),
                      TextSpan(
                        text: "product.warnings.infoSource".tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: "product.warnings.infoPost".tr()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Pulsante Segnalazione ──────────────────────────
              if (_hasUserReported || currentProduct.pendingReportsCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "product.actions.alreadyReported".tr(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _showReportBottomSheet(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error, width: 1.5),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  icon: const Icon(Icons.flag_outlined, size: 20),
                  label: Text(
                    "product.actions.reportError".tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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

  Widget _buildSectionCard({
    required String title,
    IconData? icon,
    required Widget child,
    Color? bgColor,
    bool isCaution = false,
    bool isLactose = false,
  }) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            bgColor ??
            (isCaution ? colorScheme.surfaceContainerHighest : cardBg),
        borderRadius: BorderRadius.circular(24),
        border: isCaution || isLactose
            ? null
            : Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
        boxShadow: [
          if (isCaution == false && (bgColor == null || bgColor == cardBg))
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isCaution
                      ? colorScheme.onSurface
                      : isLactose
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: isCaution
                        ? colorScheme.onSurface
                        : isLactose
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
