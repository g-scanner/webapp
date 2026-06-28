import 'package:flutter/material.dart';
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

class HistoryList extends StatefulWidget {
  final List<ScanHistoryItem> history;
  final List<Product>
  liveProducts; // Aggiunto per sincronizzare lo stato in tempo reale
  final Function(String) onSelectItem;
  final Future<void> Function() onClearHistory;
  final Future<void> Function(String) onDeleteHistoryItem;
  final Future<void> Function() onRefresh;

  const HistoryList({
    super.key,
    required this.history,
    required this.liveProducts, // Aggiunto al costruttore
    required this.onSelectItem,
    required this.onClearHistory,
    required this.onDeleteHistoryItem,
    required this.onRefresh,
  });

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  String _search = "";
  GlutenSafetyStatus? _filter;
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

  void _confirmDelete(String id) {
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
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: onSurfaceVariant),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeleteHistoryItem(id);
            },
            style: TextButton.styleFrom(foregroundColor: error),
            child: const Text("Elimina"),
          ),
        ],
      ),
    );
  }



  Color _getFilterColor() {
    switch (_filter) {
      case GlutenSafetyStatus.adatto:
        return primary.withOpacity(0.12);
      case GlutenSafetyStatus.incerto:
        return warningText.withOpacity(0.12);
      case GlutenSafetyStatus.nonAdatto:
        return error.withOpacity(0.12);
      case GlutenSafetyStatus.sconosciuto:
        return outlineVariant.withOpacity(0.2);
      default:
        return surfaceContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. SINCRONIZZAZIONE LIVE DEGLI STATI
    // Incrocia la cronologia con il database prodotti scaricato all'avvio
    final List<ScanHistoryItem> syncedHistory = widget.history.map((item) {
      final liveProd = widget.liveProducts.cast<Product?>().firstWhere(
        (p) => p?.barcode == item.barcode,
        orElse: () => null,
      );

      // Se troviamo il prodotto nel DB e lo stato è diverso, restituiamo un item aggiornato
      if (liveProd != null && liveProd.status != item.status) {
        return ScanHistoryItem(
          id: item.id,
          userId: item.userId,
          barcode: item.barcode,
          productName: liveProd
              .name, // Aggiorna anche il nome se la community lo ha corretto
          brand: liveProd.brand,
          status: liveProd.status, // ECCO LA MAGIA: STATO AGGIORNATO AL LIVE
          scannedAt: item.scannedAt,
        );
      }
      return item; // Se non lo trova o non è cambiato, lascia quello in cronologia
    }).toList();

    // 2. USA IL SYNCED HISTORY PER IL RESTO DELLA LOGICA
    final filteredHistory = syncedHistory.where((item) {
      final matchesSearch =
          item.productName.toLowerCase().contains(_search.toLowerCase()) ||
          item.brand.toLowerCase().contains(_search.toLowerCase()) ||
          item.barcode.contains(_search);
      final matchesFilter = _filter == null || item.status == _filter;
      return matchesSearch && matchesFilter;
    }).toList();

    int safeCount = syncedHistory
        .where((h) => h.status == GlutenSafetyStatus.adatto)
        .length;
    int dangerCount = syncedHistory
        .where((h) => h.status == GlutenSafetyStatus.nonAdatto)
        .length;
    int uncertainCount = syncedHistory
        .where((h) => h.status == GlutenSafetyStatus.incerto)
        .length;

    final bool showClearIcon = _isSearchFocused && _search.isNotEmpty;

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
              "Cronologia Scansioni",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Rivedi i prodotti che hai scansionato e i loro controlli di sicurezza.",
              style: TextStyle(
                fontSize: 14,
                color: onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // ── Bento Grid (Statistiche) ────────────────────────────────
            if (syncedHistory.isNotEmpty) ...[
              Row(
                children: [
                  _buildStatBox(
                    count: safeCount.toString(),
                    label: "Idonei",
                    color: primary,
                    icon: Icons.check_circle,
                  ),
                  const SizedBox(width: 12),
                  _buildStatBox(
                    count: uncertainCount.toString(),
                    label: "Incerti",
                    color: warningText,
                    icon: Icons.help,
                  ),
                  const SizedBox(width: 12),
                  _buildStatBox(
                    count: dangerCount.toString(),
                    label: "Vietati",
                    color: error,
                    icon: Icons.cancel,
                  ),
                ],
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
                    onChanged: (val) => setState(() => _search = val),
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
                                  setState(() {
                                    _search = "";
                                  });
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
                  child: DropdownButtonFormField<GlutenSafetyStatus?>(
                    value: _filter,
                    icon: const Icon(
                      Icons.filter_list,
                      color: onSurfaceVariant,
                      size: 20,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: onSurface,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _getFilterColor(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text("Tutti")),
                      DropdownMenuItem(
                        value: GlutenSafetyStatus.adatto,
                        child: Text("Sicuri"),
                      ),
                      DropdownMenuItem(
                        value: GlutenSafetyStatus.incerto,
                        child: Text("Incerti"),
                      ),
                      DropdownMenuItem(
                        value: GlutenSafetyStatus.nonAdatto,
                        child: Text("Vietati"),
                      ),
                      DropdownMenuItem(
                        value: GlutenSafetyStatus.sconosciuto,
                        child: Text("Scon."),
                      ),
                    ],
                    onChanged: (val) => setState(() => _filter = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Lista Prodotti ────────────────────────────────────────
            if (filteredHistory.isEmpty)
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
                        Icons.history,
                        size: 40,
                        color: outlineVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Nessuna scansione trovata",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Quando scansionerai un prodotto, apparirà qui.",
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
                itemCount: filteredHistory.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = filteredHistory[index];
                  return _buildHistoryCard(item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(GlutenSafetyStatus status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case GlutenSafetyStatus.adatto:
        bgColor = primary.withOpacity(0.12);
        textColor = primary;
        label = "Sicuro - non contiene glutine";
        icon = Icons.check_circle_outline;
        break;
      case GlutenSafetyStatus.nonAdatto:
        bgColor = error.withOpacity(0.12);
        textColor = error;
        label = "Vietato - contiene glutine";
        icon = Icons.cancel_outlined;
        break;
      case GlutenSafetyStatus.incerto:
        bgColor = warningText.withOpacity(0.12);
        textColor = warningText;
        label = "Incerto - potrebbe contenere glutine";
        icon = Icons.help_outline;
        break;
      case GlutenSafetyStatus.sconosciuto:
        bgColor = outlineVariant.withOpacity(0.2);
        textColor = onSurfaceVariant;
        label = "Sconosciuto - nessuna informazione disponibile";
        icon = Icons.search_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ScanHistoryItem item) {
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
        onTap: () => widget.onSelectItem(item.barcode),
        onLongPress: () => _confirmDelete(item.id),
        hoverColor: surfaceContainerHigh,
        highlightColor: surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusTag(item.status),
                    const SizedBox(height: 8),
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 14,
                              color: onSurfaceVariant.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.brand,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
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
                              Icons.calendar_month_outlined,
                              size: 14,
                              color: onSurfaceVariant.withOpacity(0.4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatRelativeDate(item.scannedAt),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: onSurfaceVariant.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Transform.translate(
                  offset: const Offset(8, 0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: onSurfaceVariant.withOpacity(0.3),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
