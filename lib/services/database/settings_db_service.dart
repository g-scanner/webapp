// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import 'offline_db_service.dart';

class SettingsDbService {
  static const String settingsKey = 'celiac_settings';
  static const String reportedBarcodesKey = 'celiac_reported_barcodes';
  static const String termsAcceptedKey = 'gscanner_terms_accepted';
  static const String hasAnonymousSettingsKey = 'has_anonymous_settings';

  static final StreamController<UserSettings> _settingsUpdateController =
      StreamController<UserSettings>.broadcast();

  /// Stream che notifica ogni aggiornamento salvato in locale di [UserSettings].
  static Stream<UserSettings> get settingsStream =>
      _settingsUpdateController.stream;

  static Future<UserSettings> getLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? settingsStr = prefs.getString(settingsKey);
    if (settingsStr != null) {
      try {
        return UserSettings.fromJson(json.decode(settingsStr));
      } catch (e) {
        debugPrint("Error parsing local settings: $e");
      }
    }

    final defaultSettings = UserSettings(
      strictMode: true,
      alertLactose: false,
      warnAdditives: true,
      autoSaveHistory: true,
      preferredLanguage: UserSettings.defaultSystemLanguage,
      preferredTheme: 'system',
      reportedBarcodes: prefs.getStringList(reportedBarcodesKey) ?? const [],
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await saveLocalSettings(defaultSettings);
    return defaultSettings;
  }

  static Future<void> saveLocalSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final toSave = settings.updatedAt == null
        ? settings.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch)
        : settings;
    await prefs.setString(settingsKey, json.encode(toSave.toJson()));
    if (!_settingsUpdateController.isClosed) {
      _settingsUpdateController.add(toSave);
    }
  }

  /// Salva le impostazioni utente localmente e su Firestore.
  ///
  /// [isOfflineDbChange]: indica che il salvataggio riguarda esclusivamente
  /// campi del DB offline (tier, lastSyncedAt, autoSync, wifiOnly).
  /// Se `true` e `offlineDbCloudSync` è disattivo, le impostazioni vengono
  /// salvate solo in locale preservando l'originale `updatedAt`, senza toccare
  /// Firestore: i campi non sincronizzati non devono alterare né il timestamp
  /// remoto né quello locale (evitando che una sync successiva li propaghi).
  static Future<void> saveSettings(
    FirebaseFirestore db,
    FirebaseAuth auth,
    UserSettings settings, {
    bool isOfflineDbChange = false,
  }) async {
    final user = auth.currentUser;

    final effectiveUserId = user?.uid ?? 'anonymous';
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final isLocalOnlyOfflineChange =
        isOfflineDbChange && !settings.offlineDbCloudSync;

    final effectiveSettings = settings.copyWith(
      userId: effectiveUserId,
      updatedAt: isLocalOnlyOfflineChange ? settings.updatedAt : nowEpoch,
    );

    await saveLocalSettings(effectiveSettings);

    final prefs = await SharedPreferences.getInstance();
    if (user == null || user.isAnonymous) {
      await prefs.setBool(hasAnonymousSettingsKey, true);
    } else {
      await prefs.remove(hasAnonymousSettingsKey);

      // Se il cambio riguarda solo il DB offline e la sincronizzazione cloud
      // è disattivata, salviamo solo in locale: non è necessario aggiornare
      // Firestore né il suo updatedAt per campi che restano su questo dispositivo.
      if (isLocalOnlyOfflineChange) return;

      try {
        final jsonData = effectiveSettings.toJson();
        // Se l'utente ha disattivato la sincronizzazione cloud delle impostazioni
        // DB offline, eliminiamo i campi specifici da Firestore con FieldValue.delete().
        // In questo modo i dati obsoleti/inutili vengono rimossi da Firebase,
        // mentre rimangono offlineDbCloudSync (a false), updatedAt e tutte le
        // impostazioni generali (tema, lingua, ecc.).
        if (!effectiveSettings.offlineDbCloudSync) {
          jsonData['offlineDbTier'] = FieldValue.delete();
          jsonData['offlineDbLastSyncedAt'] = FieldValue.delete();
          jsonData['offlineDbAutoSync'] = FieldValue.delete();
          jsonData['offlineDbWifiOnly'] = FieldValue.delete();
        }
        await db
            .collection("users")
            .doc(user.uid)
            .set(jsonData, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Failed saving settings to Firestore (offline or error): $e");
      }
    }
  }

  static Future<bool> hasAnonymousSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(hasAnonymousSettingsKey) == true) return true;

      final lastAnonUid = prefs.getString('last_anonymous_uid');
      final settingsStr = prefs.getString(settingsKey);
      if (settingsStr != null) {
        final decoded = json.decode(settingsStr) as Map<String, dynamic>;
        final uid = decoded['userId'];
        if (lastAnonUid != null && lastAnonUid.isNotEmpty && uid == lastAnonUid) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<UserSettings> syncSettingsWithFirestore(
    FirebaseFirestore db,
    FirebaseAuth auth,
    UserSettings localSettings,
  ) async {
    final user = auth.currentUser;
    if (user == null || user.isAnonymous) return localSettings;

    try {
      final docSnap = await db.collection("users").doc(user.uid).get();
      if (!docSnap.exists || docSnap.data() == null) {
        // Se non esiste ancora il documento remoto su Firestore, carichiamo le impostazioni locali
        try {
          final jsonData = localSettings.toJson();
          if (!localSettings.offlineDbCloudSync) {
            jsonData.remove('offlineDbTier');
            jsonData.remove('offlineDbLastSyncedAt');
            jsonData.remove('offlineDbAutoSync');
            jsonData.remove('offlineDbWifiOnly');
          }
          await db
              .collection("users")
              .doc(user.uid)
              .set(jsonData, SetOptions(merge: true));
        } catch (_) {}
        return localSettings;
      }

      final firestoreSettings = UserSettings.fromJson(docSnap.data()!);

      final localBarcodes = localSettings.reportedBarcodes;
      final remoteBarcodes = firestoreSettings.reportedBarcodes;
      final mergedBarcodes = {...localBarcodes, ...remoteBarcodes}.toList();

      final localTimestamp = localSettings.updatedAt ?? 0;
      final remoteTimestamp = firestoreSettings.updatedAt ?? 0;

      final UserSettings resolvedSettings;
      bool shouldPushToFirestore = false;

      if (localTimestamp > remoteTimestamp) {
        // La modifica locale è più recente (es. modifiche offline o effettuate su questo dispositivo):
        // manteniamo le impostazioni locali e sincronizziamo verso Firestore.
        resolvedSettings = localSettings.copyWith(
          userId: user.uid,
          reportedBarcodes: mergedBarcodes,
        );
        shouldPushToFirestore = true;
      } else if (remoteTimestamp > localTimestamp) {
        // La modifica remota su Firestore è più recente:
        // adottiamo le impostazioni da Firestore e aggiorniamo la persistenza locale.
        var resolved = firestoreSettings.copyWith(
          userId: user.uid,
          reportedBarcodes: mergedBarcodes,
        );
        // Se la sincronizzazione cloud del DB offline è disattivata (localmente o su Firestore),
        // è la scelta locale a importare: preserviamo le impostazioni offline DB di questo dispositivo,
        // mentre il toggle cloudSync stesso viene sincronizzato da Firestore.
        if (!localSettings.offlineDbCloudSync || !firestoreSettings.offlineDbCloudSync) {
          resolved = resolved.copyWith(
            offlineDbTier: localSettings.offlineDbTier,
            offlineDbLastSyncedAt: localSettings.offlineDbLastSyncedAt,
            offlineDbAutoSync: localSettings.offlineDbAutoSync,
            offlineDbWifiOnly: localSettings.offlineDbWifiOnly,
            offlineDbCloudSync: firestoreSettings.offlineDbCloudSync,
          );
        }
        resolvedSettings = resolved;
        if (mergedBarcodes.length != remoteBarcodes.length) {
          shouldPushToFirestore = true;
        }
      } else {
        // Timestamps identici: già allineati nel tempo.
        // Manteniamo le impostazioni correnti integrando l'eventuale unione dei barcode.
        resolvedSettings = localSettings.copyWith(
          userId: user.uid,
          reportedBarcodes: mergedBarcodes,
        );
        if (mergedBarcodes.length != remoteBarcodes.length) {
          shouldPushToFirestore = true;
        }
      }

      // Se dalle impostazioni finali il database offline è disattivato (Tier.none),
      // eliminiamo fisicamente il file del database locale se presente su questo dispositivo.
      if (resolvedSettings.offlineDbTier == OfflineDbTier.none) {
        final isInstalled = await OfflineDbService.isDatabaseInstalled();
        if (isInstalled) {
          await OfflineDbService.deleteDatabaseFile();
        }
      }

      await saveLocalSettings(resolvedSettings);

      if (shouldPushToFirestore) {
        try {
          final jsonData = resolvedSettings.toJson();
          if (!resolvedSettings.offlineDbCloudSync) {
            jsonData['offlineDbTier'] = FieldValue.delete();
            jsonData['offlineDbLastSyncedAt'] = FieldValue.delete();
            jsonData['offlineDbAutoSync'] = FieldValue.delete();
            jsonData['offlineDbWifiOnly'] = FieldValue.delete();
          }
          await db
              .collection("users")
              .doc(user.uid)
              .set(jsonData, SetOptions(merge: true));
        } catch (e) {
          debugPrint("Failed updating Firestore with resolved settings: $e");
        }
      }

      return resolvedSettings;
    } catch (e) {
      debugPrint("Failed syncing settings: $e");
    }
    return localSettings;
  }

  static Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(termsAcceptedKey) ?? false;
  }

  static Future<void> saveTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(termsAcceptedKey, true);
  }
}
