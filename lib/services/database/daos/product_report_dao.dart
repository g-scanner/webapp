// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../../models/models.dart';
import '../app_database.dart';

/// Data Access Object per le segnalazioni inviate e il tracciamento dei barcode segnalati.
class ProductReportDao {
  const ProductReportDao();

  Future<Database> get _db async => AppDatabase.instance.database;

  static const String reportsTable = 'product_reports';
  static const String reportedBarcodesTable = 'reported_barcodes';

  ProductReport _fromMap(Map<String, dynamic> map) {
    final rawJson = map['data_json'] as String;
    return ProductReport.fromJson(
      json.decode(rawJson) as Map<String, dynamic>,
    );
  }

  /// Recupera le segnalazioni dell'utente ordinate per data di invio decrescente.
  Future<List<ProductReport>> getUserReports(String userId) async {
    final db = await _db;
    final rows = await db.query(
      reportsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'submitted_at DESC',
    );
    return rows.map(_fromMap).toList();
  }

  /// Inserisce una nuova segnalazione e registra contestualmente il barcode segnalato.
  Future<void> insertReport(ProductReport report) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(
        reportsTable,
        {
          'id': report.id,
          'user_id': report.userId,
          'barcode': report.barcode,
          'product_name': report.productName,
          'brand': report.brand,
          'type': report.type,
          'status': report.status,
          'submitted_at': report.submittedAt,
          'data_json': json.encode(report.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (report.barcode.isNotEmpty) {
        await txn.insert(
          reportedBarcodesTable,
          {
            'barcode': report.barcode,
            'user_id': report.userId,
            'reported_at': report.submittedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Sovrascrive atomicamente le segnalazioni dell'utente (ad es. dopo sync da Firestore).
  Future<void> setReports(String userId, List<ProductReport> reports) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        reportsTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        reportedBarcodesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final batch = txn.batch();
      for (final report in reports) {
        batch.insert(
          reportsTable,
          {
            'id': report.id,
            'user_id': userId,
            'barcode': report.barcode,
            'product_name': report.productName,
            'brand': report.brand,
            'type': report.type,
            'status': report.status,
            'submitted_at': report.submittedAt,
            'data_json': json.encode(report.toJson()),
          },
        );
        if (report.barcode.isNotEmpty) {
          batch.insert(
            reportedBarcodesTable,
            {
              'barcode': report.barcode,
              'user_id': userId,
              'reported_at': report.submittedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      await batch.commit(noResult: true);
    });
  }

  /// Elimina una singola segnalazione e rimuove il barcode dai segnalati se non ci sono altri report.
  Future<void> deleteReport(String userId, String reportId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query(
        reportsTable,
        columns: ['barcode'],
        where: 'user_id = ? AND id = ?',
        whereArgs: [userId, reportId],
        limit: 1,
      );

      await txn.delete(
        reportsTable,
        where: 'user_id = ? AND id = ?',
        whereArgs: [userId, reportId],
      );

      if (rows.isNotEmpty) {
        final barcode = rows.first['barcode'] as String?;
        if (barcode != null && barcode.isNotEmpty) {
          // Controlla se esistono altri report attivi dell'utente per questo barcode
          final otherReports = await txn.query(
            reportsTable,
            columns: ['id'],
            where: 'user_id = ? AND barcode = ?',
            whereArgs: [userId, barcode],
            limit: 1,
          );
          if (otherReports.isEmpty) {
            await txn.delete(
              reportedBarcodesTable,
              where: 'user_id = ? AND barcode = ?',
              whereArgs: [userId, barcode],
            );
          }
        }
      }
    });
  }

  /// Svuota tutte le segnalazioni e i barcode tracciati per l'utente.
  Future<void> wipeReports(String userId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        reportsTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        reportedBarcodesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });
  }

  /// Verifica se un barcode è già stato segnalato dall'utente.
  Future<bool> isBarcodeReported(String userId, String barcode) async {
    final db = await _db;
    final rows = await db.query(
      reportedBarcodesTable,
      columns: ['barcode'],
      where: 'user_id = ? AND barcode = ?',
      whereArgs: [userId, barcode],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Registra manualmente un barcode segnalato.
  Future<void> addReportedBarcode(String userId, String barcode) async {
    final db = await _db;
    await db.insert(
      reportedBarcodesTable,
      {
        'barcode': barcode,
        'user_id': userId,
        'reported_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Rimuove un barcode dai segnalati dell'utente.
  Future<void> removeReportedBarcode(String userId, String barcode) async {
    final db = await _db;
    await db.delete(
      reportedBarcodesTable,
      where: 'user_id = ? AND barcode = ?',
      whereArgs: [userId, barcode],
    );
  }

  /// Elenca tutti i barcode segnalati dall'utente.
  Future<List<String>> getReportedBarcodes(String userId) async {
    final db = await _db;
    final rows = await db.query(
      reportedBarcodesTable,
      columns: ['barcode'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.map((r) => r['barcode'] as String).toList();
  }

  /// Riassegna le segnalazioni e i barcode anonimi al nuovo UID al login.
  Future<void> reassignAnonymousReports(String newUid) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        reportsTable,
        {'user_id': newUid},
        where: 'user_id = ?',
        whereArgs: ['anonymous'],
      );

      final anonBarcodes = await txn.query(
        reportedBarcodesTable,
        columns: ['barcode', 'reported_at'],
        where: 'user_id = ?',
        whereArgs: ['anonymous'],
      );

      for (final row in anonBarcodes) {
        await txn.insert(
          reportedBarcodesTable,
          {
            'barcode': row['barcode'],
            'user_id': newUid,
            'reported_at': row['reported_at'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await txn.delete(
        reportedBarcodesTable,
        where: 'user_id = ?',
        whereArgs: ['anonymous'],
      );
    });
  }
}
