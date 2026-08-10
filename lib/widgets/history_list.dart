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
  final List<Product> liveProducts;
  final Function(String) onSelectItem;
  final Future<void> Function() onClearHistory;
  final Future<void> Function(String) onDeleteHistoryItem;
  final Future<void> Function() onRefresh;
  final UserSettings userSettings;
  final bool isSynced;

  const HistoryList({
    super.key,
    required this.history,
    required this.liveProducts,
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
  final ScrollController _scrollController = ScrollController();

  bool _isSearchFocused = false;
  int _displayedItemsCount = 20;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  void _onScroll() {
    if (_search.isNotEmpty || _filter != null) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_displayedItemsCount < widget.history.length) {
        setState(() {
          _displayedItemsCount += 20;
        });
      }
    }
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

  // Helper per analizzare un item di cronologia al volo (Pure-Data / Zero-DB)
  _AnalyzedItemData _analyzeHistoryItem(ScanHistoryItem item) {
    final lang = widget.userSettings.preferredLanguage;
    final Product? product = widget.liveProducts.cast<Product?>().firstWhere(
      (p) => p?.barcode == item.barcode,
      orElse: () => null,
    );

    if (product == null) {
      return _AnalyzedItemData(
        productName: "Prodotto #${item.barcode}",
        brand: "Caricamento in corso...",
        status: GlutenSafetyStatus.sconosciuto,
        hasLactose: false,
      );
    }

    final name = product.getName(lang);
    final brand = product.getBrand(lang);
    final ingredients = product.getIngredients(lang);
    final allergens = product.getAllergens(lang);

    final bool isUserReported = widget.userSettings.reportedBarcodes.contains(item.barcode);

    final analysis = AnalyzerService.analyzeGlutenSafety(
      name: name,
      brand: brand,
      ingredients: ingredients,
      allergensList: allergens,
      reportCount: product.pendingReportsCount,
      categoriesTags: const [],
      strictMode: widget.userSettings.strictMode,
      warnAdditives: widget.userSettings.warnAdditives,
      alertLactose: widget.userSettings.alertLactose,
      preferredLanguage: lang,
    );

    final GlutenSafetyStatus finalStatus = (isUserReported || product.pendingReportsCount > 0)
        ? GlutenSafetyStatus.incerto
        : analysis.status;

    final bool hasLactose = AnalyzerService.checkLactose(ingredients, allergens);

    return _AnalyzedItemData(
      productName: name,
      brand: brand,
      status: finalStatus,
      hasLactose: hasLactose,
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

    final bool showSkeleton = widget.history.isEmpty && !widget.isSynced;

    // Calcolo in memoria per ricerca e filtri o paginazione standard
    List<MapEntry<ScanHistoryItem, _AnalyzedItemData>> processedList = [];

    int safeCount = 0;
    int dangerCount = 0;
    int uncertainCount = 0;

    for (var item in widget.history) {
      final data = _analyzeHistoryItem(item);
      if (data.status == GlutenSafetyStatus.adatto) safeCount++;
      if (data.status == GlutenSafetyStatus.nonAdatto) dangerCount++;
      if (data.status == GlutenSafetyStatus.incerto) uncertainCount++;

      final matchesSearch = _search.isEmpty ||
          data.productName.toLowerCase().contains(_search.toLowerCase()) ||
          data.brand.toLowerCase().contains(_search.toLowerCase()) ||
          item.barcode.contains(_search);
      final matchesFilter = _filter == null || data.status == _filter;

      if (matchesSearch && matchesFilter) {
        processedList.add(MapEntry(item, data));
      }
    }

    final bool isFiltering = _search.isNotEmpty || _filter != null;
    final List<MapEntry<ScanHistoryItem, _AnalyzedItemData>> displayItems =
        isFiltering
            ? processedList
            : processedList.take(_displayedItemsCount).toList();

    final bool showClearIcon = _isSearchFocused && _search.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _displayedItemsCount = 20;
        });
        await widget.onRefresh();
      },
      color: colorScheme.primary,
      backgroundColor: cardBg,
      displacement: 15.0,
      child: SingleChildScrollView(
        controller: _scrollController,
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

            // ── Bento Grid (Statistiche In-Memory) ─────────────────────
            if (widget.history.isNotEmpty || showSkeleton) ...[
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
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildDummySkeletonCard();
                  },
                ),
              )
            else if (displayItems.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = displayItems[index];
                  return _buildHistoryCard(entry.key, entry.value);
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

  Widget _buildDummySkeletonCard() {
    final colorScheme = context.colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 120, height: 16, color: colorScheme.surfaceContainerHighest),
            const SizedBox(height: 8),
            Container(width: 200, height: 20, color: colorScheme.surfaceContainerHighest),
            const SizedBox(height: 6),
            Container(width: 100, height: 14, color: colorScheme.surfaceContainerHighest),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ScanHistoryItem item, _AnalyzedItemData data) {
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
                        _buildStatusTag(data.status),
                        if (widget.userSettings.alertLactose && data.hasLactose)
                          _buildLactoseTag(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.productName,
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
                                data.brand,
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

class _AnalyzedItemData {
  final String productName;
  final String brand;
  final GlutenSafetyStatus status;
  final bool hasLactose;

  _AnalyzedItemData({
    required this.productName,
    required this.brand,
    required this.status,
    required this.hasLactose,
  });
}
