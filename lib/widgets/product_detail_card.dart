import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/types.dart';
import 'responsive_wrapper.dart';
import '../services/analyzer_service.dart';

// --- Material 3 Design Colors (dal Tailwind Config) ---
const Color bgBackground = Color(0xFFFAF9FC);
const Color surfaceLowest = Color(0xFFFFFFFF);
const Color surfaceLow = Color(0xFFF5F3F7);
const Color surfaceContainer = Color(0xFFEFEDF1);
const Color outlineVariant = Color(0xFFBFCABA);
const Color onSurface = Color(0xFF1B1B1E);
const Color onSurfaceVariant = Color(0xFF40493D);

const Color primary = Color(0xFF0D631B);
const Color primaryContainer = Color(0xFF2E7D32);

const Color error = Color(0xFFBA1A1A);
const Color errorContainer = Color(0xFFFFDAD6);

const Color warningText = Color(0xFF884200);
const Color warningContainer = Color(0xFFFFDCC6);

const Color secondaryContainer = Color(0xFF54A0FE);
const Color onSecondaryContainer = Color(0xFF003567);

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
  final bool hasReportedThisSession;
  final String? userReportId;
  final Future<void> Function(String reportId)? onDeleteReport;
  final bool useResponsiveWrapper;
  final bool showReportLink;
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
    this.hasReportedThisSession = false,
    this.userReportId,
    this.onDeleteReport,
    this.useResponsiveWrapper = true,
    this.showReportLink = true,
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
  }

  @override
  void dispose() {
    widget.productNotifier?.removeListener(_onProductNotifierChanged);
    widget.reportIdNotifier?.removeListener(_onReportIdNotifierChanged);
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

  String _translateGlutenStatus(GlutenSafetyStatus status) {
    switch (status) {
      case GlutenSafetyStatus.adatto:
        return "Sicuro";
      case GlutenSafetyStatus.nonAdatto:
        return "Vietato";
      case GlutenSafetyStatus.incerto:
        return "Incerto";
      case GlutenSafetyStatus.sconosciuto:
        return "Sconosciuto";
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
                decoration: const BoxDecoration(
                  color: surfaceLowest, // Sfondo bianco pulito M3
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ), // Raggio M3 molto morbido
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
                          color: outlineVariant.withValues(alpha: 0.4),
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
                            color: error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flag_rounded,
                            color: error,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            "Segnala dati errati",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Aiuta la community segnalando informazioni inesatte o etichette poco chiare.",
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Dropdown M3 ---
                    const Text(
                      "Motivo della segnalazione",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _reportType,
                      icon: const Icon(
                        Icons.expand_more,
                        color: onSurfaceVariant,
                      ),
                      dropdownColor: surfaceLowest,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(24),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: surfaceContainer, // Grigio morbido
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "label_unclear",
                          child: Text("Etichetta poco chiara o ambigua"),
                        ),
                        DropdownMenuItem(
                          value: "outdated",
                          child: Text("Informazione obsoleta"),
                        ),
                        DropdownMenuItem(
                          value: "incorrect_status",
                          child: Text("Stato glutine errato"),
                        ),
                        DropdownMenuItem(value: "other", child: Text("Altro")),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => _reportType = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- TextField M3 ---
                    const Text(
                      "Dettagli (Opzionale)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reportCommentsController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 15, color: onSurface),
                      decoration: InputDecoration(
                        hintText:
                            "Es: Sulla confezione dice 'può contenere tracce'...",
                        hintStyle: TextStyle(
                          color: onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: surfaceContainer,
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
                        TextButton(
                          onPressed: _submittingReport
                              ? null
                              : () => Navigator.pop(sheetCtx),
                          style: TextButton.styleFrom(
                            foregroundColor: onSurfaceVariant,
                            minimumSize: const Size(
                              0,
                              48,
                            ), // Touch target standard M3
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Text(
                            "Annulla",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 185,
                          height: 48,
                          child: FilledButton(
                            onPressed: _submittingReport
                                ? null
                                : () async {
                                    setSheetState(() => _submittingReport = true);
                                    try {
                                      await widget.onReportSubmit(
                                        currentProduct.barcode,
                                        {
                                          "type": _reportType,
                                          "comments":
                                              _reportCommentsController.text,
                                          "originalStatus":
                                              currentProduct.status.name,
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
                                      setSheetState(() => _submittingReport = false);
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: error,
                              foregroundColor: surfaceLowest,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  999,
                                ), // Pill shape M3
                              ),
                            ),
                            child: _submittingReport
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: surfaceLowest.withValues(alpha: 0.5),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Invia segnalazione",
                                    style: TextStyle(fontWeight: FontWeight.w600),
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
    final Product currentProduct = widget.productNotifier?.value ?? widget.product;
    final bool showSkeleton = widget.isLoading && widget.productNotifier?.value == null;

    final String currentLang = widget.userSettings.preferredLanguage;
    final String rawIngredients = currentProduct.ingredientsMap?[currentLang] ?? currentProduct.ingredients;
    final String displayedIngredients = rawIngredients.replaceAll('\$', '').trim();
    final List<String> rawAllergens = currentProduct.allergensMap?[currentLang] ?? 
        AnalyzerService.translateAllergens(currentProduct.allergens, currentLang);
    final List<String> displayedAllergens = rawAllergens.map((a) => a.replaceAll('\$', '').trim()).toList();
    final bool isReported = (currentProduct.reportCount ?? 0) > 0 || _hasUserReported;
    final String rawReason = isReported
        ? currentProduct.reason
        : (currentProduct.reasonsMap?[currentLang] ?? currentProduct.reason);
    final String displayedReason = rawReason.replaceAll('\$', '').trim();
    final List<IngredientAnalyzed> rawIngredientsAnalyzed = currentProduct.ingredientsAnalyzedMap?[currentLang] ?? 
        currentProduct.ingredientsAnalyzed ?? [];

    final List<IngredientAnalyzed> displayedIngredientsAnalyzed = [];
    final Set<String> seenIngredients = {};
    for (var item in rawIngredientsAnalyzed) {
      final cleanName = item.ingredient.replaceAll('\$', '').trim();
      final cleanReason = item.reason.replaceAll('\$', '').trim();
      final key = cleanName.toLowerCase();
      if (!seenIngredients.contains(key) && cleanName.isNotEmpty) {
        seenIngredients.add(key);
        displayedIngredientsAnalyzed.add(
          IngredientAnalyzed(
            ingredient: cleanName,
            dangerLevel: item.dangerLevel,
            reason: cleanReason,
          ),
        );
      }
    }

    final bool containsLactose = AnalyzerService.checkLactose(
      displayedIngredients,
      displayedAllergens,
    );

    final bool showLactoseWarning =
        widget.userSettings.alertLactose && containsLactose;

    Color heroBgColor;
    Color heroTextColor;
    String statusBigText;
    IconData statusIcon;

    switch (currentProduct.status) {
      case GlutenSafetyStatus.adatto:
        heroBgColor = primary.withValues(alpha: 0.05);
        heroTextColor = primary;
        statusBigText = "SICURO";
        statusIcon = Icons.check_circle;
        break;
      case GlutenSafetyStatus.nonAdatto:
        heroBgColor = error.withValues(alpha: 0.08);
        heroTextColor = error;
        statusBigText = "VIETATO";
        statusIcon = Icons.cancel;
        break;
      case GlutenSafetyStatus.incerto:
        heroBgColor = warningContainer.withValues(alpha: 0.3);
        heroTextColor = warningText;
        statusBigText = "INCERTO";
        statusIcon = Icons.warning;
        break;
      case GlutenSafetyStatus.sconosciuto:
        heroBgColor = onSurfaceVariant.withValues(alpha: 0.05);
        heroTextColor = onSurfaceVariant;
        statusBigText = "SCONOSCIUTO";
        statusIcon = Icons.help;
        break;
    }

    // Utilizziamo uno Scaffold interno per gestire la sua AppBar personale
    final scaffold = Scaffold(
        backgroundColor: bgBackground,
        appBar: AppBar(
          backgroundColor: surfaceLowest,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: onSurface),
            onPressed: widget.onBack,
          ),
          title: Center(
            child: const Text(
              "Dettaglio scansione",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: onSurface,
              ),
            ),
          ),
          actions: [
            // I Tre Puntini per le impostazioni
            if (widget.onDeleteHistoryByBarcode != null ||
                _effectiveUserReportId != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: onSurfaceVariant),
                color: surfaceLowest,
                onSelected: (value) {
                  if (value == 'delete_history') {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: surfaceLowest,
                        title: const Text("Eliminare scansione?"),
                        content: const Text(
                          "Sei sicuro di voler eliminare questa scansione dalla tua cronologia locale?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              foregroundColor: onSurfaceVariant,
                            ),
                            child: const Text("Annulla"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.onDeleteHistoryByBarcode!(
                                currentProduct.barcode,
                              );
                              widget.onBack();
                            },
                            style: TextButton.styleFrom(foregroundColor: error),
                            child: const Text("Elimina"),
                          ),
                        ],
                      ),
                    );
                  } else if (value == 'delete_report') {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: surfaceLowest,
                        title: const Text("Eliminare segnalazione?"),
                        content: const Text(
                          "Sei sicuro di voler eliminare questa segnalazione?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              foregroundColor: onSurfaceVariant,
                            ),
                            child: const Text("Annulla"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              if (_effectiveUserReportId != null) {
                                await widget.onDeleteReport!(_effectiveUserReportId!);
                              }
                            },
                            style: TextButton.styleFrom(foregroundColor: error),
                            child: const Text("Elimina"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  if (widget.onDeleteHistoryByBarcode != null)
                    const PopupMenuItem(
                      value: 'delete_history',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: error, size: 20),
                          SizedBox(width: 12),
                          Text(
                            "Elimina dalla cronologia",
                            style: TextStyle(color: error),
                          ),
                        ],
                      ),
                    ),
                  if (_effectiveUserReportId != null &&
                      _effectiveUserReportId!.isNotEmpty &&
                      widget.onDeleteReport != null)
                    const PopupMenuItem(
                      value: 'delete_report',
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: error, size: 20),
                          SizedBox(width: 12),
                          Text(
                            "Elimina segnalazione",
                            style: TextStyle(color: error),
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
                      currentProduct.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentProduct.brand,
                      style: const TextStyle(
                        fontSize: 16,
                        color: onSurfaceVariant,
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
                    const SizedBox(height: 4),
                    Text(
                      "Scansionato il: ${formatRelativeDate(currentProduct.lastUpdated)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Valutazione Glutine ───────────────────────────────────
              Builder(
                builder: (context) {
                  final bool hasActiveReport = widget.showReportLink &&
                      widget.onViewReport != null &&
                      ((currentProduct.reportCount ?? 0) > 0 || _hasUserReported);

                  // Costruiamo la stringa con il vecchio stato se presente
                  String displayedReasonWithOldStatus = displayedReason;
                  if (hasActiveReport &&
                      currentProduct.originalStatus != null &&
                      currentProduct.originalStatus != currentProduct.status) {
                    final String oldStatusTranslated = _translateGlutenStatus(currentProduct.originalStatus!);
                    String cleanReason = displayedReason.trim();
                    if (cleanReason.endsWith('.')) {
                      cleanReason = cleanReason.substring(0, cleanReason.length - 1);
                    }
                    displayedReasonWithOldStatus = "$cleanReason. Stato precedente alla segnalazione: $oldStatusTranslated.";
                  }

                  final Widget cardContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.leaderboard,
                              size: 18,
                              color: onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "VALUTAZIONE GLUTINE",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                color: onSurfaceVariant,
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
                          style: const TextStyle(fontSize: 16, color: onSurface),
                        ),
                      ),
                      if (hasActiveReport) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: warningText.withValues(alpha: 0.04),
                            border: Border(
                              top: BorderSide(color: outlineVariant.withValues(alpha: 0.2)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Vai alla segnalazione",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: warningText,
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(6, 0),
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: warningText,
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
                      color: surfaceLowest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: outlineVariant.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
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
                }
              ),
              const SizedBox(height: 24),

              // ── Avviso Lattosio (se presente) ─────────────────────────
              if (showLactoseWarning) ...[
                _buildSectionCard(
                  title: "PRESENZA LATTOSIO",
                  icon: Icons.water_drop,
                  isLactose: true,
                  bgColor: secondaryContainer.withValues(alpha: 0.08),
                  child: Text(
                    "Questo prodotto contiene ingredienti o allergeni che indicano la presenza di lattosio. Non adatto agli intolleranti.",
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // ── Allergeni Dichiarati ──────────────────────────────────
              _buildSectionCard(
                title: "ALLERGENI DICHIARATI",
                icon: Icons.coronavirus,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: displayedAllergens.isNotEmpty
                      ? displayedAllergens.map((alg) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceContainer,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              alg,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList()
                      : [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceContainer,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              "Nessuno dichiarato",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Analisi Ingredienti ───────────────────────────────────
              _buildSectionCard(
                title: "ANALISI INGREDIENTI",
                icon: Icons.science,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayedIngredients,
                      style: const TextStyle(
                        fontSize: 14,
                        color: onSurface,
                        height: 1.5,
                      ),
                    ),
                    if (displayedIngredientsAnalyzed.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...displayedIngredientsAnalyzed.map((item) {
                        Color pillBg;
                        Color pillText;
                        String pillLabel;

                        if (item.dangerLevel == "danger") {
                          pillBg = error.withValues(alpha: 0.1);
                          pillText = error;
                          pillLabel = "Pericolo";
                        } else if (item.dangerLevel == "warning") {
                          print("Warning ingredient: ${item.ingredient}");
                          pillBg = warningContainer;
                          pillText = warningText;
                          pillLabel = "Attenzione";
                        } else {
                          pillBg = primary.withValues(alpha: 0.1);
                          pillText = primary;
                          pillLabel = "Sicuro";
                        }

                        return Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
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
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: onSurface,
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
                              const SizedBox(height: 4),
                              Text(
                                item.reason,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Blocco Info / Avvertenze ─────────────────────────────
              _buildSectionCard(
                title: "INFORMAZIONI E AVVERTENZE",
                icon: Icons.info_outline,
                isCaution: true,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: onSurfaceVariant,
                    ),
                    children: <TextSpan>[
                      const TextSpan(
                        text: "I dati sono forniti dalla community di ",
                      ),
                      const TextSpan(
                        text: "Open Food Facts",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text:
                            ". Verifica SEMPRE fisicamente l'etichetta e le scritte sul prodotto prima di consumarlo. L'app non sostituisce il parere medico.",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Pulsante Segnalazione ──────────────────────────
              if (_hasUserReported ||
                  (currentProduct.reportCount ?? 0) > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: error, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Prodotto già segnalato",
                        style: TextStyle(
                          color: error,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _showReportBottomSheet(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: error,
                    side: const BorderSide(color: error, width: 1.5),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  icon: const Icon(Icons.flag_outlined, size: 20),
                  label: const Text(
                    "Segnala dati errati o poco chiari",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor ?? (isCaution ? surfaceContainer : surfaceLowest),
        borderRadius: BorderRadius.circular(24),
        border: isCaution || isLactose
            ? null
            : Border.all(color: outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          if (isCaution == false &&
              (bgColor == null || bgColor == surfaceLowest))
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
                      ? onSurface
                      : isLactose
                      ? onSecondaryContainer
                      : onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: isCaution
                      ? onSurface
                      : isLactose
                      ? onSecondaryContainer
                      : onSurfaceVariant,
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
