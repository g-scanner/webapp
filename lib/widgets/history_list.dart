// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/types.dart';
import '../services/analyzer_service.dart';
import '../theme/app_theme.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HistoryList extends StatefulWidget {
  final List<ScanHistoryItem> history;
  final List<Product>
  liveProducts; // Aggiunto per sincronizzare lo stato in tempo reale
  final Function(String) onSelectItem;
  final Future<void> Function() onClearHistory;
  final Future<void> Function(String) onDeleteHistoryItem;
  final Future<void> Function() onRefresh;
  final UserSettings userSettings;
  final bool isSynced;

  const HistoryList({
    super.key,
    required this.history,
    required this.liveProducts, // Aggiunto al costruttore
    required this.onSelectItem,
    required this.onClearHistory,
    required this.onDeleteHistoryItem,
    required this.onRefresh,
    required this.userSettings,
    required this.isSynced,
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
    final colorScheme = context.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBackground,
        title: Text(
          "Eliminare scansione?",
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          "Sei sicuro di voler eliminare questa scansione dalla tua cronologia locale?",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeleteHistoryItem(id);
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text("Elimina"),
          ),
        ],
      ),
    );
  }

  bool _hasLactose(ScanHistoryItem item) {
    if (item.hasLactose) return true;
    final liveProd = widget.liveProducts.cast<Product?>().firstWhere(
      (p) => p?.barcode == item.barcode,
      orElse: () => null,
    );
    if (liveProd == null) return false;
    return AnalyzerService.checkLactose(
      liveProd.ingredients,
      liveProd.allergens,
    );
  }

  Widget _buildLactoseTag() {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            "Lattosio",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFilterColor() {
    final colorScheme = context.colorScheme;
    switch (_filter) {
      case GlutenSafetyStatus.adatto:
        return colorScheme.primary.withValues(alpha: 0.12);
      case GlutenSafetyStatus.incerto:
        return colorScheme.tertiary.withValues(alpha: 0.12);
      case GlutenSafetyStatus.nonAdatto:
        return colorScheme.error.withValues(alpha: 0.12);
      case GlutenSafetyStatus.sconosciuto:
        return colorScheme.outlineVariant.withValues(alpha: 0.2);
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _getFilterTextColor() {
    final colorScheme = context.colorScheme;
    switch (_filter) {
      case GlutenSafetyStatus.adatto:
        return colorScheme.primary;
      case GlutenSafetyStatus.incerto:
        return colorScheme.tertiary;
      case GlutenSafetyStatus.nonAdatto:
        return colorScheme.error;
      case GlutenSafetyStatus.sconosciuto:
        return colorScheme.onSurfaceVariant;
      default:
        return colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    }
  }

  Color _getFilterIconColor() {
    final colorScheme = context.colorScheme;
    switch (_filter) {
      case GlutenSafetyStatus.adatto:
        return colorScheme.primary;
      case GlutenSafetyStatus.incerto:
        return colorScheme.tertiary;
      case GlutenSafetyStatus.nonAdatto:
        return colorScheme.error;
      case GlutenSafetyStatus.sconosciuto:
        return colorScheme.onSurfaceVariant;
      default:
        return colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    }
  }

  TextStyle _dropdownItemTextStyle(Color color) {
    return TextStyle(color: color, fontWeight: FontWeight.w600);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    // 1. SINCRONIZZAZIONE LIVE DEGLI STATI
    // Incrocia la cronologia con il database prodotti scaricato all'avvio
    final List<ScanHistoryItem> syncedHistory = widget.history.map((item) {
      final liveProd = widget.liveProducts.cast<Product?>().firstWhere(
        (p) => p?.barcode == item.barcode,
        orElse: () => null,
      );

      // Se troviamo il prodotto nel DB e lo stato, nome o brand sono diversi, restituiamo un item aggiornato
      if (liveProd != null &&
          (liveProd.status != item.status ||
              liveProd.name != item.productName ||
              liveProd.brand != item.brand)) {
        return ScanHistoryItem(
          id: item.id,
          userId: item.userId,
          barcode: item.barcode,
          productName: liveProd
              .name, // Aggiorna anche il nome se la community lo ha corretto
          brand: liveProd.brand,
          status: liveProd.status, // ECCO LA MAGIA: STATO AGGIORNATO AL LIVE
          scannedAt: item.scannedAt,
          hasLactose: item.hasLactose,
        );
      }
      return item; // Se non lo trova o non è cambiato, lascia quello in cronologia
    }).toList();

    final bool showSkeleton = widget.history.isEmpty && !widget.isSynced;

    final List<ScanHistoryItem> displayHistory = showSkeleton
        ? [
            ScanHistoryItem(
              id: 'dummy1',
              barcode: '1234567890123',
              productName: 'Nome Prodotto Esempio Molto Lungo',
              brand: 'Marca Prodotto Esempio',
              status: GlutenSafetyStatus.adatto,
              scannedAt: DateTime.now().toIso8601String(),
            ),
            ScanHistoryItem(
              id: 'dummy2',
              barcode: '9876543210987',
              productName: 'Nome Prodotto Esempio Secondo',
              brand: 'Altra Marca Esempio',
              status: GlutenSafetyStatus.nonAdatto,
              scannedAt: DateTime.now().toIso8601String(),
            ),
          ]
        : syncedHistory;

    // 2. USA IL SYNCED HISTORY PER IL RESTO DELLA LOGICA
    final filteredHistory = syncedHistory.where((item) {
      final matchesSearch =
          item.productName.toLowerCase().contains(_search.toLowerCase()) ||
          item.brand.toLowerCase().contains(_search.toLowerCase()) ||
          item.barcode.contains(_search);
      final matchesFilter = _filter == null || item.status == _filter;
      return matchesSearch && matchesFilter;
    }).toList();

    int safeCount = 0;
    int dangerCount = 0;
    int uncertainCount = 0;

    if (showSkeleton) {
      safeCount = 99;
      dangerCount = 99;
      uncertainCount = 99;
    } else {
      safeCount = syncedHistory
          .where((h) => h.status == GlutenSafetyStatus.adatto)
          .length;
      dangerCount = syncedHistory
          .where((h) => h.status == GlutenSafetyStatus.nonAdatto)
          .length;
      uncertainCount = syncedHistory
          .where((h) => h.status == GlutenSafetyStatus.incerto)
          .length;
    }

    final bool showClearIcon = _isSearchFocused && _search.isNotEmpty;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: colorScheme.primary,
      backgroundColor: cardBg,
      displacement: 15.0,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Intestazione Pagina ─────────────────────────────────────
            Text(
              "Cronologia Scansioni",
              style: TextStyle(
                fontSize: 22,
                fontWeight: kIsWeb ? FontWeight.w600 : FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Rivedi i prodotti che hai scansionato e i loro controlli di sicurezza.",
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // ── Bento Grid (Statistiche) ────────────────────────────────
            if (syncedHistory.isNotEmpty || showSkeleton) ...[
              Skeletonizer(
                enabled: showSkeleton,
                child: Row(
                  children: [
                    _buildStatBox(
                      count: safeCount.toString(),
                      label: "Idonei",
                      color: colorScheme.primary,
                      icon: Icons.check_circle,
                    ),
                    const SizedBox(width: 12),
                    _buildStatBox(
                      count: uncertainCount.toString(),
                      label: "Incerti",
                      color: colorScheme.tertiary,
                      icon: Icons.warning_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildStatBox(
                      count: dangerCount.toString(),
                      label: "Vietati",
                      color: colorScheme.error,
                      icon: Icons.cancel,
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
                    onChanged: (val) => setState(() => _search = val),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: "Cerca prodotto...",
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
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
                                  icon: Icon(
                                    Icons.close,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _search = "";
                                    });
                                    _searchFocusNode.requestFocus();
                                  },
                                )
                              : Icon(
                                  key: const ValueKey('searchIcon'),
                                  Icons.search,
                                  color: _search.isNotEmpty
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurfaceVariant.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
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
                    initialValue: _filter,
                    icon: Icon(
                      Icons.filter_list,
                      color: _getFilterIconColor(),
                      size: 20,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getFilterTextColor(),
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
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          "Tutti",
                          style: _dropdownItemTextStyle(
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: GlutenSafetyStatus.adatto,
                        child: Text(
                          "Sicuri",
                          style: _dropdownItemTextStyle(colorScheme.primary),
                        ),
                      ),
                      DropdownMenuItem(
                        value: GlutenSafetyStatus.incerto,
                        child: Text(
                          "Incerti",
                          style: _dropdownItemTextStyle(colorScheme.tertiary),
                        ),
                      ),
                      DropdownMenuItem(
                        value: GlutenSafetyStatus.nonAdatto,
                        child: Text(
                          "Vietati",
                          style: _dropdownItemTextStyle(colorScheme.error),
                        ),
                      ),
                      DropdownMenuItem(
                        value: GlutenSafetyStatus.sconosciuto,
                        child: Text(
                          "Scon.",
                          style: _dropdownItemTextStyle(
                            colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _filter = val),
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
                  itemCount: displayHistory.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = displayHistory[index];
                    return _buildHistoryCard(item);
                  },
                ),
              )
            else if (filteredHistory.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredHistory.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = filteredHistory[index];
                  return _buildHistoryCard(item);
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
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history,
                        size: 40,
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Nessuna scansione trovata",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Quando scansionerai un prodotto, apparirà qui.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
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
          color: color.withValues(alpha: 0.1),
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
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(GlutenSafetyStatus status) {
    final colorScheme = context.colorScheme;
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case GlutenSafetyStatus.adatto:
        bgColor = colorScheme.primaryContainer.withValues(alpha: 0.15);
        textColor = colorScheme.primary;
        label = "Sicuro - non contiene glutine";
        icon = Icons.check_circle_outline;
        break;
      case GlutenSafetyStatus.nonAdatto:
        bgColor = colorScheme.errorContainer.withValues(alpha: 0.15);
        textColor = colorScheme.error;
        label = "Vietato - contiene glutine";
        icon = Icons.cancel_outlined;
        break;
      case GlutenSafetyStatus.incerto:
        bgColor = colorScheme.tertiaryContainer.withValues(alpha: 0.15);
        textColor = colorScheme.tertiary;
        label = "Incerto - potrebbe contenere glutine";
        icon = Icons.help_outline;
        break;
      case GlutenSafetyStatus.sconosciuto:
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
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
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cardBg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => widget.onSelectItem(item.barcode),
        onLongPress: () => _confirmDelete(item.id),
        hoverColor: colorScheme.surfaceContainerHighest,
        highlightColor: context.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildStatusTag(item.status),
                        if (widget.userSettings.alertLactose &&
                            _hasLactose(item))
                          _buildLactoseTag(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
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
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.brand,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.9),
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
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatRelativeDate(item.scannedAt),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
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
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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
