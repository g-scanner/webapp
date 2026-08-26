import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';

class ModularAssetLoader extends AssetLoader {
  const ModularAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    String languageCode = locale.languageCode;
    final Map<String, dynamic> mergedResult = {};

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final jsonAssets = manifest
        .listAssets()
        .where((key) => key.startsWith('assets/locales/$languageCode/') && key.endsWith('.json'))
        .toList();

    for (final assetPath in jsonAssets) {
      try {
        final String content = await rootBundle.loadString(assetPath);
        final Map<String, dynamic> jsonMap = json.decode(content) as Map<String, dynamic>;
        mergedResult.addAll(jsonMap);
      } catch (e) {
        debugPrint("ERRORE CRITICO: Il file JSON $assetPath è malformato o mancante! Errore: $e");
      }
    }

    return mergedResult;
  }
}
