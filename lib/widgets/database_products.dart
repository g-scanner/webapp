import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gscanner/services/db_service.dart';
import 'package:gscanner/widgets/report_detail_card.dart';
import '../models/types.dart';
import 'package:skeletonizer/skeletonizer.dart';

// --- Colori estratti dal tuo Tailwind Config ---
const Color bgBackground = Color(0xFFFAF9FC);
const Color surfaceLowest = Color(0xFFFFFFFF);
const Color onSurface = Color(0xFF1B1B1E);
const Color onSurfaceVariant = Color(0xFF40493D);
const Color surfaceContainer = Color(0xFFEFEDF1);
const Color surfaceContainerHigh = Color(0xFFE9E7EB);
const Color surfaceContainerLow = Color(0xFFF5F3F7);
const Color outlineVariant = Color(0xFFBFCABA);

const Color primary = Color(0xFF0D631B);
const Color error = Color(0xFFBA1A1A);
const Color warningText = Color(0xFF884200);

// --- Colori per il Filtro Selezionato ---
const Color secondaryContainer = Color(0xFF54A0FE);
const Color onSecondaryContainer = Color(0xFF003567);

class DatabaseProducts extends StatefulWidget {
  final List<Product> products;
  final List<String> reportedBarcodes;
  final Function(String) onSelectItem;
  final Future<void> Function() onRefresh;
  final bool isSynced;
  final UserSettings? userSettings;
  final List<ProductReport>? userReports;
  final Future<void> Function(String reportId)? onDeleteReport;

  const DatabaseProducts({
    super.key,
    required this.products,
    required this.reportedBarcodes,
    required this.onSelectItem,
    required this.onRefresh,
    required this.isSynced,
    this.userSettings,
    this.userReports,
    this.onDeleteReport,
  });

  @override
  State<DatabaseProducts> createState() => _DatabaseProductsState();
}

class _DatabaseProductsState extends State<DatabaseProducts> {
  String _searchTerm = "";
  String _reportFilter = "Tutte"; // "Tutte" o "Mie"

  late FocusNode _searchFocusNode;
  late TextEditingController _searchController;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  TextStyle _dropdownItemTextStyle(Color color) {
    return TextStyle(color: color, fontWeight: FontWeight.w600);
  }

  @override
  Widget build(BuildContext context) {
    // Estrai i prodotti con segnalazioni, ordinati per data decrescente
    final reportedProducts =
        widget.products.where((p) => (p.reportCount ?? 0) > 0).toList()
          ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    final bool showSkeleton = reportedProducts.isEmpty && !widget.isSynced;

    // Filtra per ricerca testuale e tipo di segnalazione
    final filtered = reportedProducts.where((p) {
      final queryMatches =
          p.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.brand.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.barcode.contains(_searchTerm);

      final filterMatches = _reportFilter == "Tutte"
          ? true
          : widget.reportedBarcodes.contains(p.barcode);

      return queryMatches && filterMatches;
    }).toList();

    final List<Product> displayProducts = showSkeleton
        ? [
            Product(
              barcode: '1234567890123',
              name: 'Nome Prodotto Segnalato Esempio',
              brand: 'Marca Esempio',
              ingredients: 'Dummy ingredients',
              allergens: [],
              status: GlutenSafetyStatus.incerto,
              reason: 'Segnalazione in corso',
              lastUpdated: DateTime.now().toIso8601String(),
              reportCount: 3,
            ),
            Product(
              barcode: '9876543210987',
              name: 'Altro Prodotto Segnalato Esempio',
              brand: 'Altra Marca Esempio',
              ingredients: 'Dummy ingredients',
              allergens: [],
              status: GlutenSafetyStatus.nonAdatto,
              reason: 'Segnalazione in corso',
              lastUpdated: DateTime.now().toIso8601String(),
              reportCount: 1,
            ),
          ]
        : filtered;

    final bool showClearIcon = _isSearchFocused && _searchTerm.isNotEmpty;

    // --- Variabili di Stile Dinamiche per il Filtro ---
    final bool isMineSelected = _reportFilter == "Mie";
    final Color filterBgColor = isMineSelected
        ? secondaryContainer.withValues(alpha: 0.15)
        : surfaceContainer;
    final Color filterTextColor = isMineSelected
        ? onSecondaryContainer
        : onSurface;
    final Color filterIconColor = isMineSelected
        ? onSecondaryContainer
        : onSurfaceVariant.withValues(alpha: 0.6);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: primary,
      backgroundColor: surfaceLowest,
      displacement: 15.0,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Intestazione Pagina ─────────────────────────────────────
            const Text(
              "Segnalazioni",
              style: TextStyle(
                fontSize: 22,
                fontWeight: kIsWeb ? FontWeight.w600 : FontWeight.w500,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Seleziona un prodotto per esaminare i dettagli inviati dalla community e approvare o respingere le modifiche.",
              style: TextStyle(
                fontSize: 14,
                color: onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // ── Card "In attesa" (Separata e indipendente) ───────────────
            if (reportedProducts.isNotEmpty || showSkeleton) ...[
              Skeletonizer(
                enabled: showSkeleton,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: outlineVariant.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: onSurface.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: warningText.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pending_actions,
                          size: 20,
                          color: warningText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Segnalazioni attive",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: showSkeleton
                              ? warningText.withValues(alpha: 0.18)
                              : warningText,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${showSkeleton ? 99 : reportedProducts.length}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: showSkeleton ? warningText : surfaceLowest,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Ricerca e Filtri ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (val) => setState(() => _searchTerm = val),
                    style: const TextStyle(fontSize: 14, color: onSurface),
                    decoration: InputDecoration(
                      hintText: "Cerca prodotto...",
                      hintStyle: TextStyle(
                        color: onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 48,
                        maxWidth: 48,
                        minHeight: 48,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                          child: showClearIcon
                              ? IconButton(
                                  key: const ValueKey('clearIcon'),
                                  icon: const Icon(
                                    Icons.close,
                                    color: onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchTerm = "");
                                    _searchFocusNode.requestFocus();
                                  },
                                )
                              : Icon(
                                  key: const ValueKey('searchIcon'),
                                  Icons.search,
                                  color: _searchTerm.isNotEmpty
                                      ? onSurfaceVariant
                                      : onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                        ),
                      ),
                      filled: true,
                      fillColor: surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _reportFilter,
                    icon: Icon(
                      Icons.filter_list,
                      color: filterIconColor, // Colore Dinamico Icona
                      size: 20,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: filterTextColor, // Colore Dinamico Testo
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: filterBgColor, // Sfondo Dinamico
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: "Tutte",
                        child: Text(
                          "Tutte",
                          style: _dropdownItemTextStyle(
                            onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: "Mie",
                        child: Text(
                          "Le mie",
                          style: _dropdownItemTextStyle(onSecondaryContainer),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _reportFilter = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (showSkeleton)
              Skeletonizer(
                enabled: true,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayProducts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final prod = displayProducts[index];
                    return _buildReportCard(prod);
                  },
                ),
              )
            else if (filtered.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final prod = filtered[index];
                  return _buildReportCard(prod);
                },
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.task_alt,
                        size: 40,
                        color: outlineVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Nessuna segnalazione",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Non ci sono prodotti che richiedono la tua attenzione per i filtri selezionati.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Costruzione Card Prodotto Segnalato ──
  Widget _buildReportCard(Product prod) {
    final bool isOwnReport = widget.reportedBarcodes.contains(prod.barcode);
    final userReport = widget.userReports?.cast<ProductReport?>().firstWhere(
          (r) => r?.barcode == prod.barcode,
          orElse: () => null,
        );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: surfaceLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailCard(
                product: prod,
                originalStatus:
                    prod.originalStatus ?? GlutenSafetyStatus.sconosciuto,
                onBack: () => Navigator.pop(context),
                reportReasonKey: "label_unclear",
                reportComment: prod.reason.isNotEmpty
                    ? prod.reason
                    : "Nessun commento",
                reportDate: formatRelativeDate(prod.lastUpdated),
                onVote: (vote) async {
                  await DbService.voteOnReportByBarcode(prod.barcode, vote);
                },
                onInitVote: () async {
                  return await DbService.getReportVoteDataByBarcode(
                    prod.barcode,
                  );
                },
                userSettings: widget.userSettings,
                isOwnReport: isOwnReport,
                reportId: userReport?.id,
                onDeleteReport: widget.onDeleteReport,
              ),
            ),
          );
        },
        onLongPress: (isOwnReport && widget.onDeleteReport != null)
            ? () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: surfaceLowest,
                    title: const Text("Eliminare segnalazione?"),
                    content: const Text(
                      "Sei sicuro di voler eliminare la tua segnalazione per questo prodotto?",
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
                          final reportId = userReport?.id;
                          if (reportId != null) {
                            await widget.onDeleteReport!(reportId);
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: error),
                        child: const Text("Elimina"),
                      ),
                    ],
                  ),
                );
              }
            : null,
        hoverColor: surfaceContainerHigh,
        highlightColor: surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PARTE SUPERIORE: Dettagli in nuovo formato
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NOME PRODOTTO
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      prod.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 16,
                            color: onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              prod.brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurfaceVariant.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatRelativeDate(prod.lastUpdated),
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 18,
                            color: onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            prod.barcode,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: onSurfaceVariant.withValues(alpha: 0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PARTE INFERIORE: Call To Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    "Esamina dettagli segnalazione",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: warningText,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(6, 0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: warningText.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
