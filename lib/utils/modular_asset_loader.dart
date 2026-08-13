import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';

class ModularAssetLoader extends AssetLoader {
  const ModularAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final String languageCode = locale.languageCode;
    final Map<String, dynamic> mergedResult = {};

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final jsonAssets = manifest
        .listAssets()
        .where((key) => key.startsWith('assets/locales/$languageCode/') && key.endsWith('.json'));

    for (final assetPath in jsonAssets) {
      final String content = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonMap = json.decode(content) as Map<String, dynamic>;
      mergedResult.addAll(jsonMap);
    }

    return mergedResult;
  }
}
