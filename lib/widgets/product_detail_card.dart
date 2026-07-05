import 'package:flutter/material.dart';
import '../models/types.dart';
import 'responsive_wrapper.dart';

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
  final VoidCallback onBack;
  final Future<void> Function(String barcode, Map<String, dynamic> reportData)
  onReportSubmit;
  final Future<void> Function(Product updatedProduct) onProductUpdate;
  final UserSettings userSettings;
  final Future<void> Function(String barcode)? onDeleteHistoryByBarcode;
  final bool hasReportedThisSession;
  final String? userReportId;
  final Future<void> Function(String reportId)? onDeleteReport;

  const ProductDetailCard({
    super.key,
    required this.product,
    required this.onBack,
    required this.onReportSubmit,
    required this.onProductUpdate,
    required this.userSettings,
    this.onDeleteHistoryByBarcode,
    this.hasReportedThisSession = false,
    this.userReportId,
    this.onDeleteReport,
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

  @override
  void dispose() {
    _reportCommentsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showReportBottomSheet(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetCtx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: bgBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: outlineVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.warning, color: error),
                        SizedBox(width: 8),
                        Text(
                          "Segnala Etichetta",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Aiuta la community segnalando dati errati o poco chiari.",
                      style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Motivo della segnalazione",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _reportType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: surfaceLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
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
                        DropdownMenuItem(
                            value: "other", child: Text("Altro")),
                      ],
                      onChanged: (val) {
                        setSheetState(() => _reportType = val!);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Dettagli (Opzionale)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reportCommentsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            "Es: Sulla confezione dice può contenere...",
                        hintStyle: TextStyle(
                          color: onSurfaceVariant.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: surfaceLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          style: TextButton.styleFrom(
                            foregroundColor: onSurfaceVariant,
                          ),
                          child: const Text("Annulla"),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _submittingReport
                              ? null
                              : () async {
                                  setSheetState(
                                      () => _submittingReport = true);
                                  try {
                                    await widget.onReportSubmit(
                                        widget.product.barcode, {
                                      "type": _reportType,
                                      "comments":
                                          _reportCommentsController.text,
                                      "originalStatus":
                                          widget.product.status.name,
                                    });
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
                                    _submittingReport = false;
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: error,
                            foregroundColor: surfaceLowest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: _submittingReport
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Invia"),
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
    final bool containsLactose =
        widget.product.ingredients.toLowerCase().contains("latte") ||
        widget.product.ingredients.toLowerCase().contains("lattosio") ||
        widget.product.ingredients.toLowerCase().contains("burro") ||
        widget.product.ingredients.toLowerCase().contains("panna");

    final bool showLactoseWarning =
        widget.userSettings.alertLactose && containsLactose;

    Color heroBgColor;
    Color heroTextColor;
    String statusBigText;
    IconData statusIcon;

    switch (widget.product.status) {
      case GlutenSafetyStatus.adatto:
        heroBgColor = primary.withOpacity(0.05);
        heroTextColor = primary;
        statusBigText = "SICURO";
        statusIcon = Icons.check_circle;
        break;
      case GlutenSafetyStatus.nonAdatto:
        heroBgColor = error.withOpacity(0.08);
        heroTextColor = error;
        statusBigText = "VIETATO";
        statusIcon = Icons.cancel;
        break;
      case GlutenSafetyStatus.incerto:
        heroBgColor = warningContainer.withOpacity(0.3);
        heroTextColor = warningText;
        statusBigText = "INCERTO";
        statusIcon = Icons.warning;
        break;
      case GlutenSafetyStatus.sconosciuto:
        heroBgColor = onSurfaceVariant.withOpacity(0.05);
        heroTextColor = onSurfaceVariant;
        statusBigText = "SCONOSCIUTO";
        statusIcon = Icons.help;
        break;
    }

    // Utilizziamo uno Scaffold interno per gestire la sua AppBar personale
    return ResponsiveMaxCardWidth(
      child: Scaffold(
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
              widget.userReportId != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: onSurfaceVariant),
              color: surfaceLowest,
              onSelected: (value) {
                if (value == 'delete_history') {
                  widget.onDeleteHistoryByBarcode!(widget.product.barcode);
                  widget.onBack();
                } else if (value == 'delete_report') {
                  widget.onDeleteReport!(widget.userReportId!);
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
                if (widget.userReportId != null &&
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
      body: SingleChildScrollView(
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
                      color: heroTextColor.withOpacity(0.1),
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
                    widget.product.name,
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
                    widget.product.brand,
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
                      color: heroTextColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code, size: 16, color: heroTextColor),
                        const SizedBox(width: 8),
                        SelectableText(
                          widget.product.barcode,
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
                    "Scansionato il: ${formatRelativeDate(widget.product.lastUpdated)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurfaceVariant.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Valutazione Glutine ───────────────────────────────────
            _buildSectionCard(
              title: "VALUTAZIONE GLUTINE",
              icon: Icons.leaderboard,
              child: Text(
                widget.product.reason,
                style: const TextStyle(fontSize: 16, color: onSurface),
              ),
            ),
            const SizedBox(height: 24),

            // ── Avviso Lattosio (se presente) ─────────────────────────
            if (showLactoseWarning) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: secondaryContainer.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Avviso Lattosio",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: onSurface,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Questo prodotto contiene ingredienti derivati dal latte non adatti agli intolleranti.",
                            style: TextStyle(
                              fontSize: 14,
                              color: onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                children: widget.product.allergens.isNotEmpty
                    ? widget.product.allergens.map((alg) {
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
                    widget.product.ingredients,
                    style: const TextStyle(
                      fontSize: 14,
                      color: onSurface,
                      height: 1.5,
                    ),
                  ),
                  if (widget.product.ingredientsAnalyzed != null &&
                      widget.product.ingredientsAnalyzed!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...widget.product.ingredientsAnalyzed!.map((item) {
                      Color pillBg;
                      Color pillText;
                      String pillLabel;

                      if (item.dangerLevel == "danger") {
                        pillBg = error.withOpacity(0.1);
                        pillText = error;
                        pillLabel = "Pericolo";
                      } else if (item.dangerLevel == "warning") {
                        print("Warning ingredient: ${item.ingredient}");
                        pillBg = warningContainer;
                        pillText = warningText;
                        pillLabel = "Attenzione";
                      } else {
                        pillBg = primary.withOpacity(0.1);
                        pillText = primary;
                        pillLabel = "Sicuro";
                      }

                      return Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: outlineVariant.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            if (widget.hasReportedThisSession ||
                _hasJustReported ||
                (widget.product.reportCount ?? 0) > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: errorContainer.withOpacity(0.5),
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
  }

  Widget _buildSectionCard({
    required String title,
    IconData? icon,
    required Widget child,
    Color? bgColor,
    bool isCaution = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor ?? (isCaution ? surfaceContainer : surfaceLowest),
        borderRadius: BorderRadius.circular(24),
        border: isCaution
            ? null
            : Border.all(color: outlineVariant.withOpacity(0.5)),
        boxShadow: [
          if (isCaution == false &&
              (bgColor == null || bgColor == surfaceLowest))
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
                  color: isCaution ? onSurface : onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: isCaution ? onSurface : onSurfaceVariant,
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
