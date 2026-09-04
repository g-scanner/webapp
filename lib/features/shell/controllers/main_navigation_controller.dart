// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:gscanner/models/models.dart';

/// Controller reattivo per la gestione dello stato di navigazione della shell.
class MainNavigationController extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isCameraActive = true;
  double maxKeyboardHeight = 0.0;

  final GlobalKey<NavigatorState> contentNavigatorKey =
      GlobalKey<NavigatorState>();
  final Map<String, ValueNotifier<Product?>> openProductNotifiers = {};
  final Map<String, ValueNotifier<String?>> openReportIdNotifiers = {};

  int get currentIndex => _currentIndex;
  bool get isCameraActive => _isCameraActive;

  void selectTab(int index) {
    _currentIndex = index;
    _isCameraActive = index == 0;
    notifyListeners();
  }

  void setCameraActive(bool active) {
    _isCameraActive = active;
    notifyListeners();
  }

  void resetToScanner() {
    _currentIndex = 0;
    _isCameraActive = true;
    notifyListeners();
  }

  void popContentNavigatorUntilFirst() {
    contentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
