// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';

/// Contenitore indicizzato per le 4 schermate principali dell'applicazione.
class MainIndexedStack extends StatelessWidget {
  final int currentIndex;
  final List<Widget> children;

  const MainIndexedStack({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentIndex > 3 ? 3 : currentIndex,
      children: children,
    );
  }
}
