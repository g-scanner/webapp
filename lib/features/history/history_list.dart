// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../services/analyzer_service.dart';
import 'widgets/widgets.dart';

export 'widgets/widgets.dart';

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
          "history.actions.clearAllConfirmTitle".tr(),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          "history.actions.clearAllConfirmBody".tr(),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
            child: Text("common.actions.cancel".tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeleteHistoryItem(id);
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: Text("common.actions.delete".tr()),
          ),
        ],
      ),
    );
  }

  // Helper per analizzare un item di cronologia al volo (Pure-Data / Zero-DB)
  AnalyzedItemData _analyzeHistoryItem(ScanHistoryItem item) {
    final lang = widget.userSettings.preferredLanguage;
    final Product? product = widget.liveProducts.cast<Product?>().firstWhere(
      (p) => p?.barcode == item.barcode,
      orElse: () => null,
    );

    if (product == null) {
      return AnalyzedItemData(
        productName: "history.loading.productFallbackName".tr(
          namedArgs: {"barcode": item.barcode},
        ),
        brand: "history.loading.brandLoading".tr(),
        status: GlutenSafetyStatus.sconosciuto,
        hasLactose: false,
      );
    }

    final name = product.getName(lang);
    final brand = product.getBrand(lang);
    final ingredients = product.getIngredients(lang);
    final allergens = product.getAllergens(lang);

    final bool isUserReported = widget.userSettings.reportedBarcodes.contains(
      item.barcode,
    );

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

    final GlutenSafetyStatus finalStatus =
        (isUserReported || product.pendingReportsCount > 0)
        ? GlutenSafetyStatus.incerto
        : analysis.status;

    final bool hasLactose = AnalyzerService.checkLactose(
      ingredients,
      allergens,
    );

    return AnalyzedItemData(
      productName: name,
      brand: brand.isNotEmpty ? brand : "product.status.unknownBrand".tr(),
      status: finalStatus,
      hasLactose: hasLactose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    final bool showSkeleton = widget.history.isEmpty && !widget.isSynced;

    // Calcolo in memoria per ricerca e filtri o paginazione standard
    List<MapEntry<ScanHistoryItem, AnalyzedItemData>> processedList = [];

    int safeCount = 0;
    int dangerCount = 0;
    int uncertainCount = 0;

    for (var item in widget.history) {
      final data = _analyzeHistoryItem(item);
      if (data.status == GlutenSafetyStatus.adatto) safeCount++;
      if (data.status == GlutenSafetyStatus.nonAdatto) dangerCount++;
      if (data.status == GlutenSafetyStatus.incerto) uncertainCount++;

      final matchesSearch =
          _search.isEmpty ||
          data.productName.toLowerCase().contains(_search.toLowerCase()) ||
          data.brand.toLowerCase().contains(_search.toLowerCase()) ||
          item.barcode.contains(_search);
      final matchesFilter = _filter == null || data.status == _filter;

      if (matchesSearch && matchesFilter) {
        processedList.add(MapEntry(item, data));
      }
    }

    final bool isFiltering = _search.isNotEmpty || _filter != null;
    final List<MapEntry<ScanHistoryItem, AnalyzedItemData>> displayItems =
        isFiltering
        ? processedList
        : processedList.take(_displayedItemsCount).toList();

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
            const HistoryHeader(),
            const SizedBox(height: 24),

            // ── Bento Grid (Statistiche In-Memory) ─────────────────────
            if (widget.history.isNotEmpty || showSkeleton) ...[
              HistoryBentoStats(
                safeCount: safeCount,
                uncertainCount: uncertainCount,
                dangerCount: dangerCount,
                showSkeleton: showSkeleton,
              ),
              const SizedBox(height: 24),
            ],

            // ── Ricerca e Filtri ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: HistorySearchBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    isFocused: _isSearchFocused,
                    searchQuery: _search,
                    onChanged: (val) => setState(() => _search = val),
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _search = "";
                      });
                      _searchFocusNode.requestFocus();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 2,
                  child: HistoryFilterChips(
                    filter: _filter,
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
                    return const HistoryItemSkeleton();
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
                  return HistoryItemTile(
                    item: entry.key,
                    data: entry.value,
                    onSelectItem: widget.onSelectItem,
                    onLongPress: () => _confirmDelete(entry.key.id),
                    alertLactose: widget.userSettings.alertLactose,
                  );
                },
              )
            else ...[
              HistoryEmptyView(
                searchQuery: _search,
                filter: _filter,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
