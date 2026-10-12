// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

/// Stato di avanzamento della sincronizzazione del DB offline.
enum OfflineSyncStep {
  idle,
  checkingVersion,
  downloading,
  extracting,
  merging,
  completed,
  error,
}

class OfflineSyncProgress {
  final OfflineSyncStep step;
  final double progress; // 0.0 -> 1.0
  final String? errorMessage;

  const OfflineSyncProgress({
    required this.step,
    this.progress = 0.0,
    this.errorMessage,
  });

  const OfflineSyncProgress.idle()
      : step = OfflineSyncStep.idle,
        progress = 0.0,
        errorMessage = null;

  const OfflineSyncProgress.completed()
      : step = OfflineSyncStep.completed,
        progress = 1.0,
        errorMessage = null;

  const OfflineSyncProgress.error(this.errorMessage)
      : step = OfflineSyncStep.error,
        progress = 0.0;

  bool get isInProgress =>
      step == OfflineSyncStep.checkingVersion ||
      step == OfflineSyncStep.downloading ||
      step == OfflineSyncStep.extracting ||
      step == OfflineSyncStep.merging;
}
