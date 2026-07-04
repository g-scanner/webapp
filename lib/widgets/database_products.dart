import 'package:flutter/material.dart';
import 'package:gscanner/services/db_service.dart';
import 'package:gscanner/widgets/report_detail_card.dart';
import '../models/types.dart';

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

  const DatabaseProducts({
    super.key,
    required this.products,
    required this.reportedBarcodes,
    required this.onSelectItem,
    required this.onRefresh,
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


  @override
  Widget build(BuildContext context) {
    // Estrai i prodotti con segnalazioni
    final reportedProducts = widget.products
        .where((p) => (p.reportCount ?? 0) > 0)
        .toList();

    // Filtra per ricerca testuale e tipo di segnalazione
    final filtered = reportedProducts.where((p) {
      final queryMatches =
          p.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.brand.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.barcode.contains(_searchTerm);

      final filterMatches = _reportFilter == "Tutte" ? true : widget.reportedBarcodes.contains(p.barcode);

      return queryMatches && filterMatches;
    }).toList();

    final bool showClearIcon = _isSearchFocused && _searchTerm.isNotEmpty;

    // --- Variabili di Stile Dinamiche per il Filtro ---
    final bool isMineSelected = _reportFilter == "Mie";
    final Color filterBgColor = isMineSelected
        ? secondaryContainer.withOpacity(0.15)
        : surfaceContainer;
    final Color filterTextColor = isMineSelected
        ? onSecondaryContainer
        : onSurface;
    final Color filterIconColor = isMineSelected
        ? onSecondaryContainer
        : onSurfaceVariant;

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
                fontWeight: FontWeight.w500,
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
            if (reportedProducts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: surfaceLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: outlineVariant.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: onSurface.withOpacity(0.02),
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
                        color: warningText.withOpacity(0.12),
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
                        color: warningText,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${reportedProducts.length}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: surfaceLowest,
                        ),
                      ),
                    ),
                  ],
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
                        color: onSurfaceVariant.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      prefixIcon: AnimatedSwitcher(
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
                            : const Icon(
                                key: ValueKey('searchIcon'),
                                Icons.search,
                                color: onSurfaceVariant,
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
                    value: _reportFilter,
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
                    items: const [
                      DropdownMenuItem(value: "Tutte", child: Text("Tutte")),
                      DropdownMenuItem(value: "Mie", child: Text("Le mie")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _reportFilter = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Lista Prodotti ────────────────────────────────────────
            if (filtered.isEmpty)
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
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final prod = filtered[index];
                  return _buildReportCard(prod);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Costruzione Card Prodotto Segnalato ──
  Widget _buildReportCard(Product prod) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: surfaceLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: outlineVariant.withOpacity(0.3)),
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
              ),
            ),
          );
        },
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
                            color: onSurfaceVariant.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              prod.brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurfaceVariant.withOpacity(0.9),
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
                            color: onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatRelativeDate(prod.lastUpdated),
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurfaceVariant.withOpacity(0.7),
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
                            color: onSurfaceVariant.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            prod.barcode,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: onSurfaceVariant.withOpacity(0.8),
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
                color: warningText.withOpacity(0.04),
                border: Border(
                  top: BorderSide(color: outlineVariant.withOpacity(0.2)),
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
                      color: warningText.withOpacity(0.8),
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
