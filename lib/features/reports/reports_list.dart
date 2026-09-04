// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../services/db_service.dart';
import '../../services/analyzer_service.dart';
import '../../models/models.dart';
import '../../core/theme/theme.dart';
import 'report_detail_card.dart';
import 'widgets/widgets.dart';

export 'widgets/widgets.dart';

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

  void _navigateToDetail(Product prod, bool isOwnReport, ProductReport? userReport) {
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
  }

  void _confirmDeleteReport(String? reportId) {
    final cardBg = context.cardBackground;
    final colorScheme = context.colorScheme;

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
              if (reportId != null && widget.onDeleteReport != null) {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    // Estrai i prodotti con segnalazioni, ordinati per data decrescente
    final reportedProducts =
        widget.products.where((p) => p.pendingReportsCount > 0).toList()
          ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    final bool showSkeleton = reportedProducts.isEmpty && !widget.isSynced;

    final lang =
        widget.userSettings?.preferredLanguage ?? context.locale.languageCode;

    // Filtra per ricerca testuale e tipo di segnalazione
    final filtered = reportedProducts.where((p) {
      final queryMatches =
          _searchTerm.trim().isEmpty ||
          p
              .getName(lang)
              .toLowerCase()
              .contains(_searchTerm.trim().toLowerCase()) ||
          p
              .getBrand(lang)
              .toLowerCase()
              .contains(_searchTerm.trim().toLowerCase()) ||
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
            ReportsFilterHeader(
              activeReportsCount: reportedProducts.length,
              showSkeleton: showSkeleton,
              hasReportedProducts: reportedProducts.isNotEmpty,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              isSearchFocused: _isSearchFocused,
              searchTerm: _searchTerm,
              onSearchChanged: (val) => setState(() => _searchTerm = val),
              onSearchClear: () {
                _searchController.clear();
                setState(() => _searchTerm = "");
                _searchFocusNode.requestFocus();
              },
              reportFilter: _reportFilter,
              onFilterChanged: (val) => setState(() => _reportFilter = val),
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
                    return const ReportItemSkeleton();
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
                  final bool isOwnReport =
                      widget.reportedBarcodes.contains(prod.barcode);
                  final userReport =
                      widget.userReports?.cast<ProductReport?>().firstWhere(
                            (r) => r?.barcode == prod.barcode,
                            orElse: () => null,
                          );

                  return ReportItemCard(
                    prod: prod,
                    onTap: () => _navigateToDetail(prod, isOwnReport, userReport),
                    onLongPress: (isOwnReport && widget.onDeleteReport != null)
                        ? () => _confirmDeleteReport(userReport?.id)
                        : null,
                  );
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
}
