// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';

/// Barra di ricerca della cronologia (wrapper su [AppSearchBar]).
class HistorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const HistorySearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppSearchBar(
      controller: controller,
      focusNode: focusNode,
      isFocused: isFocused,
      searchQuery: searchQuery,
      onChanged: onChanged,
      onClear: onClear,
    );
  }
}
