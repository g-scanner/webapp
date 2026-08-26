// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner â€” See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gscanner/services/db_service.dart';
import 'package:gscanner/services/analyzer_service.dart';
import 'package:gscanner/widgets/report_detail_card.dart';
import '../models/types.dart';
import '../theme/app_theme.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ReportsList extends StatefulWidget {
  final List<Product> products;
  final List<String> reportedBarcodes;
  final Function(String) onSelectItem;
  final Future<void> Function() onRefresh;
  final bool isSynced;
  final UserSettings? userSettings;
  final List<ProductReport>? userReports;
  final Future<void> Function(String reportId)? onDeleteReport;

  const ReportsList({
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
  State<ReportsList> createState() => _ReportsListState();
}

class _ReportsListState extends State<ReportsList> {
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
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    // Estrai i prodotti con segnalazioni, ordinati per data decrescente
    final reportedProducts =
        widget.products.where((p) => p.pendingReportsCount > 0).toList()
          ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    final bool showSkeleton = reportedProducts.isEmpty && !widget.isSynced;

    final lang = widget.userSettings?.preferredLanguage ?? context.locale.languageCode;

    // Filtra per ricerca testuale e tipo di segnalazione
    final filtered = reportedProducts.where((p) {
      final queryMatches =
          _searchTerm.trim().isEmpty ||
          p.getName(lang).toLowerCase().contains(_searchTerm.trim().toLowerCase()) ||
          p.getBrand(lang).toLowerCase().contains(_searchTerm.trim().toLowerCase()) ||
          p.barcode.contains(_searchTerm.trim());

      final filterMatches = _reportFilter == "Tutte"
          ? true
          : widget.reportedBarcodes.contains(p.barcode);

      return queryMatches && filterMatches;
    }).toList();

    final List<Product> displayProducts = showSkeleton
        ? [
            Product(
              barcode: '1234567890123',
              nameMap: const {'it': 'Nome Prodotto Segnalato Esempio'},
              brandMap: const {'it': 'Marca Esempio'},
              ingredientsMap: const {'it': 'Dummy ingredients'},
              allergensMap: const {'it': []},
              lastUpdated: DateTime.now().toIso8601String(),
              pendingReportsCount: 3,
            ),
            Product(
              barcode: '9876543210987',
              nameMap: const {'it': 'Altro Prodotto Segnalato Esempio'},
              brandMap: const {'it': 'Altra Marca Esempio'},
              ingredientsMap: const {'it': 'Dummy ingredients'},
              allergensMap: const {'it': []},
              lastUpdated: DateTime.now().toIso8601String(),
              pendingReportsCount: 1,
            ),
          ]
        : filtered;

    final bool showClearIcon = _isSearchFocused && _searchTerm.isNotEmpty;

    // --- Variabili di Stile Dinamiche per il Filtro ---
    final bool isMineSelected = _reportFilter == "Mie";
    final Color filterBgColor = isMineSelected
        ? colorScheme.secondaryContainer.withValues(alpha: 0.15)
        : colorScheme.surfaceContainerHighest;
    final Color filterTextColor = isMineSelected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurface;
    final Color filterIconColor = isMineSelected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

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
              "report.listTitle".tr(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: kIsWeb ? FontWeight.w600 : FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "report.subtitle".tr(),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // â”€â”€ Card "In attesa" (Separata e indipendente) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (reportedProducts.isNotEmpty || showSkeleton) ...[
              Skeletonizer(
                enabled: showSkeleton,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.onSurface.withValues(alpha: 0.02),
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
                          color: colorScheme.tertiary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.pending_actions,
                          size: 20,
                          color: colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "report.lists.activeReports".tr(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
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
                              ? colorScheme.tertiary.withValues(alpha: 0.18)
                              : colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${showSkeleton ? 99 : reportedProducts.length}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: showSkeleton
                                ? colorScheme.tertiary
                                : colorScheme.onTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // â”€â”€ Ricerca e Filtri â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (val) => setState(() => _searchTerm = val),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: "database.search.hint".tr(),
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
                                    setState(() => _searchTerm = "");
                                    _searchFocusNode.requestFocus();
                                  },
                                )
                              : Icon(
                                  key: const ValueKey('searchIcon'),
                                  Icons.search,
                                  color: _searchTerm.isNotEmpty
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
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _reportFilter,
                    icon: Icon(
                      Icons.filter_list,
                      color: filterIconColor,
                      size: 20,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: filterTextColor,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: filterBgColor,
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
                          "report.dropdown.all".tr(),
                          style: _dropdownItemTextStyle(
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: "Mie",
                        child: Text(
                          "report.dropdown.mine".tr(),
                          style: _dropdownItemTextStyle(
                            colorScheme.onSecondaryContainer,
                          ),
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
            else ...[
              Builder(builder: (context) {
                final IconData emptyIcon;
                final String emptyTitle;
                final String emptySubtitle;

                final trimmedSearch = _searchTerm.trim();
                if (trimmedSearch.isNotEmpty) {
                  // 1. La ricerca da textfield prevale sempre
                  emptyIcon = Icons.search_off_rounded;
                  emptyTitle = "report.search.noResultsTitle".tr();
                  emptySubtitle = "database.search.noResults".tr(
                    namedArgs: {"query": trimmedSearch},
                  );
                } else if (_reportFilter == "Mie") {
                  // 2. Filtro "Mie" attivo senza segnalazioni dell'utente
                  emptyIcon = Icons.assignment_outlined;
                  emptyTitle = "report.empty.mineTitle".tr();
                  emptySubtitle = "report.empty.mineSubtitle".tr();
                } else {
                  // 3. Nessuna segnalazione nel database di base
                  emptyIcon = Icons.task_alt;
                  emptyTitle = "report.empty.title".tr();
                  emptySubtitle = "report.empty.subtitle".tr();
                }

                return Container(
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
                          emptyIcon,
                          size: 40,
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        emptySubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
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
    );
  }

  // â”€â”€ Costruzione Card Prodotto Segnalato â”€â”€
  Widget _buildReportCard(Product prod) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;
    final bool isOwnReport = widget.reportedBarcodes.contains(prod.barcode);
    final userReport = widget.userReports?.cast<ProductReport?>().firstWhere(
      (r) => r?.barcode == prod.barcode,
      orElse: () => null,
    );

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
        onTap: () {
          final lang = widget.userSettings?.preferredLanguage ?? 'it';
          final origA = AnalyzerService.analyzeGlutenSafety(
            name: prod.getName(lang),
            brand: prod.getBrand(lang),
            ingredients: prod.getIngredients(lang),
            allergensList: prod.getAllergens(lang),
            reportCount: 0,
            categoriesTags: const [],
            strictMode: widget.userSettings?.strictMode ?? false,
            warnAdditives: widget.userSettings?.warnAdditives ?? false,
            alertLactose: widget.userSettings?.alertLactose ?? false,
            preferredLanguage: lang,
            ignoreReports: true,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailCard(
                product: prod,
                originalStatus: origA.status,
                onBack: () => Navigator.pop(context),
                reportReasonKey: "label_unclear",
                reportComment: "Nessun commento",
                reportDate: userReport?.submittedAt ?? "",
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
                useResponsiveWrapper: MediaQuery.of(context).size.width <= 960,
              ),
            ),
          );
        },
        onLongPress: (isOwnReport && widget.onDeleteReport != null)
            ? () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: cardBg,
                    title: Text(
                      "report.ui.deleteConfirmTitle".tr(),
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    content: Text(
                      "report.ui.deleteConfirmBody".tr(),
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
                          final reportId = userReport?.id;
                          if (reportId != null) {
                            await widget.onDeleteReport!(reportId);
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
            : null,
        hoverColor: colorScheme.surfaceContainerHighest,
        highlightColor: context.surfaceContainerLow,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
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
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              prod.brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.9,
                                ),
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
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatRelativeDate(prod.lastUpdated),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
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
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            prod.barcode,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
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
                color: colorScheme.tertiary.withValues(alpha: 0.04),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "report.lists.examineDetails".tr(),
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
                      color: colorScheme.tertiary.withValues(alpha: 0.8),
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
