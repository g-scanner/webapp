// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';

/// Global ValueNotifier per il tema dell'app.
/// Aggiornarlo cambia il tema istantaneamente senza riavvio.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
