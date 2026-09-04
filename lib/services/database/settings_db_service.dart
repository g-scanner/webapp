// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';

class SettingsDbService {
  static const String settingsKey = 'celiac_settings';
  static const String reportedBarcodesKey = 'celiac_reported_barcodes';
  static const String termsAcceptedKey = 'gscanner_terms_accepted';

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
    );
    await saveLocalSettings(defaultSettings);
    return defaultSettings;
  }

  static Future<void> saveLocalSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(settingsKey, json.encode(settings.toJson()));
  }

  static Future<void> saveSettings(
    FirebaseFirestore db,
    FirebaseAuth auth,
    UserSettings settings,
  ) async {
    final user = auth.currentUser;

    final effectiveSettings = user != null && !user.isAnonymous
        ? UserSettings(
            userId: user.uid,
            strictMode: settings.strictMode,
            alertLactose: settings.alertLactose,
            warnAdditives: settings.warnAdditives,
            autoSaveHistory: settings.autoSaveHistory,
            preferredLanguage: settings.preferredLanguage,
            preferredTheme: settings.preferredTheme,
            reportedBarcodes: settings.reportedBarcodes,
          )
        : settings;

    await saveLocalSettings(effectiveSettings);

    if (user != null && !user.isAnonymous) {
      try {
        await db
            .collection("users")
            .doc(user.uid)
            .set(effectiveSettings.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint("Failed saving settings to Firestore: $e");
      }
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
      if (docSnap.exists && docSnap.data() != null) {
        final firestoreSettings = UserSettings.fromJson(docSnap.data()!);

        final localBarcodes = localSettings.reportedBarcodes;
        final remoteBarcodes = firestoreSettings.reportedBarcodes;
        final mergedBarcodes = {...localBarcodes, ...remoteBarcodes}.toList();

        final mergedSettings = UserSettings(
          userId: user.uid,
          strictMode: firestoreSettings.strictMode,
          alertLactose: firestoreSettings.alertLactose,
          warnAdditives: firestoreSettings.warnAdditives,
          autoSaveHistory: firestoreSettings.autoSaveHistory,
          preferredLanguage: firestoreSettings.preferredLanguage,
          preferredTheme: firestoreSettings.preferredTheme,
          reportedBarcodes: mergedBarcodes,
        );

        await saveLocalSettings(mergedSettings);
        return mergedSettings;
      }
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
