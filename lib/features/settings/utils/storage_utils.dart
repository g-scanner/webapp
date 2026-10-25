// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

/// Converte una dimensione in byte in una stringa leggibile (B, KB, MB, GB).
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const kb = 1024;
  const mb = 1024 * 1024;
  const gb = 1024 * 1024 * 1024;

  if (bytes < kb) {
    return '$bytes B';
  } else if (bytes < mb) {
    final value = bytes / kb;
    return '${value >= 10 ? value.toStringAsFixed(0) : value.toStringAsFixed(1).replaceAll('.0', '')} KB';
  } else if (bytes < gb) {
    final value = bytes / mb;
    return '${value >= 10 ? value.toStringAsFixed(0) : value.toStringAsFixed(1).replaceAll('.0', '')} MB';
  } else {
    final value = bytes / gb;
    return '${value.toStringAsFixed(1).replaceAll('.0', '')} GB';
  }
}
