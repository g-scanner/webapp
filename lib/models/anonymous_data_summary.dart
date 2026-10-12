// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'scan_history_item.dart';
import 'product_report.dart';

/// Dati anonimi rilevati, suddivisi per categoria.
class AnonymousDataSummary {
  final List<ScanHistoryItem> history;
  final List<ProductReport> reports;
  final bool hasSettings;

  const AnonymousDataSummary({
    this.history = const [],
    this.reports = const [],
    this.hasSettings = false,
  });

  bool get hasHistory => history.isNotEmpty;
  bool get hasReports => reports.isNotEmpty;
  int get categoryCount =>
      (hasHistory ? 1 : 0) + (hasReports ? 1 : 0) + (hasSettings ? 1 : 0);
}

/// Rappresenta le categorie scelte dall'utente per la sincronizzazione.
class SyncChoices {
  final bool syncHistory;
  final bool syncReports;
  final bool syncSettings;

  const SyncChoices({
    this.syncHistory = true,
    this.syncReports = true,
    this.syncSettings = true,
  });

  bool get hasAny => syncHistory || syncReports || syncSettings;
}
