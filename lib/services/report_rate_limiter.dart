// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: GlutiEnd — See LICENSE file in root for terms.

import 'package:shared_preferences/shared_preferences.dart';

/// Gestisce il rate limiting scalare per l'invio delle segnalazioni.
///
/// Regole:
/// - Intervallo minimo tra singoli invii: 10 secondi (anti rage-click / doppio click).
/// - Burst consentito: fino a 5 segnalazioni veloci.
/// - Alla 5ª segnalazione consecutiva (o invio a ridosso dello sblocco), scattano i blocchi scalari:
///     * Tier 1: 1 minuto (60s)    -> Finestra di reset dinamica: 3 minuti (180s)
///     * Tier 2: 10 minuti (600s)  -> Finestra di reset dinamica: 15 minuti (900s)
///     * Tier 3: 30 minuti (1800s) -> Finestra di reset dinamica: 45 minuti (2700s)
///     * Tier 4: 60 minuti (3600s) -> Finestra di reset dinamica: 90 minuti (5400s)
/// - Se l'utente non invia segnalazioni per l'intera finestra di reset dopo lo sblocco,
///   il livello di penalità e il contatore di burst tornano a 0 (piena riabilitazione).
class ReportRateLimiter {
  static const String keyLastSubmissionMs = 'report_rate_limit_last_submission_ms';
  static const String keyBurstCount = 'report_rate_limit_burst_count';
  static const String keyPenaltyTier = 'report_rate_limit_penalty_tier';
  static const String keyCooldownUntilMs = 'report_rate_limit_cooldown_until_ms';

  static const int minIntervalSeconds = 10;
  static const int maxBurstCount = 5;

  /// Durata del cooldown in secondi per ciascun livello di penalità (1-based: tier 1..4).
  static const Map<int, int> tierCooldownSeconds = {
    1: 60, // 1 minuto
    2: 600, // 10 minuti
    3: 1800, // 30 minuti
    4: 3600, // 60 minuti
  };

  /// Finestra di buona condotta dinamica (in secondi) post-cooldown per azzerare la penalità.
  static const Map<int, int> tierResetWindowSeconds = {
    1: 180, // 3 minuti
    2: 900, // 15 minuti
    3: 2700, // 45 minuti
    4: 5400, // 90 minuti
  };

  /// Clock configurabile per i test unitari.
  static DateTime Function() clock = () => DateTime.now();

  /// Restituisce i secondi rimanenti di cooldown prima di poter inviare una nuova segnalazione.
  /// Ritorna 0 se l'invio è consentito immediatamente.
  static Future<int> getRemainingCooldownSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final nowMs = clock().millisecondsSinceEpoch;

    final cooldownUntilMs = prefs.getInt(keyCooldownUntilMs) ?? 0;
    if (cooldownUntilMs > nowMs) {
      final diff = ((cooldownUntilMs - nowMs) / 1000).ceil();
      return diff > 0 ? diff : 0;
    }

    // Controlla l'intervallo minimo base di 10 secondi dall'ultimo invio
    final lastSubmissionMs = prefs.getInt(keyLastSubmissionMs) ?? 0;
    if (lastSubmissionMs > 0) {
      final elapsedSinceLastSec = ((nowMs - lastSubmissionMs) / 1000).floor();
      if (elapsedSinceLastSec < minIntervalSeconds) {
        return minIntervalSeconds - elapsedSinceLastSec;
      }
    }

    return 0;
  }

  /// Verifica se è attualmente attivo un blocco/cooldown.
  static Future<bool> isBlocked() async {
    final remaining = await getRemainingCooldownSeconds();
    return remaining > 0;
  }

  /// Registra una segnalazione inviata con successo e aggiorna la macchina a stati.
  static Future<void> recordSubmission() async {
    final prefs = await SharedPreferences.getInstance();
    final now = clock();
    final nowMs = now.millisecondsSinceEpoch;

    var tier = prefs.getInt(keyPenaltyTier) ?? 0;
    var burst = prefs.getInt(keyBurstCount) ?? 0;
    final cooldownUntilMs = prefs.getInt(keyCooldownUntilMs) ?? 0;

    // Se eravamo in una penalità precedente, verifichiamo se è trascorsa la finestra di reset dinamica
    if (tier > 0) {
      final resetWindowSec = tierResetWindowSeconds[tier] ?? 180;
      final fullResetThresholdMs = cooldownUntilMs + (resetWindowSec * 1000);

      if (nowMs >= fullResetThresholdMs) {
        // Buona condotta rispettata: reset completo
        tier = 0;
        burst = 0;
      }
    } else if (burst > 0) {
      // Se era Tier 0 ma aveva fatto segnalazioni precedenti, controlliamo se sono passati più di 3 minuti
      // dall'ultima segnalazione per azzerare il burst di 5.
      final lastMs = prefs.getInt(keyLastSubmissionMs) ?? 0;
      if (nowMs - lastMs > (3 * 60 * 1000)) {
        burst = 0;
      }
    }

    burst++;

    int newCooldownUntilMs = 0;

    // Se l'utente ha esaurito il burst consentito OPPURE ha già un tier attivo
    if (burst >= maxBurstCount || tier > 0) {
      // Avanza al tier successivo (fino al massimo tier 4)
      tier = (tier + 1).clamp(1, 4);
      final cooldownSec = tierCooldownSeconds[tier] ?? 60;
      newCooldownUntilMs = nowMs + (cooldownSec * 1000);
      burst = 0; // Reset del burst per il prossimo ciclo post-blocco
    } else {
      // Normale intervallo minimo di 10 secondi
      newCooldownUntilMs = nowMs + (minIntervalSeconds * 1000);
    }

    await prefs.setInt(keyLastSubmissionMs, nowMs);
    await prefs.setInt(keyBurstCount, burst);
    await prefs.setInt(keyPenaltyTier, tier);
    await prefs.setInt(keyCooldownUntilMs, newCooldownUntilMs);
  }

  /// Formatta i secondi rimanenti in una stringa leggibile (es. "45s" o "8 min").
  static String formatRemainingTime(int seconds) {
    if (seconds <= 0) return '0s';
    if (seconds < 60) return '${seconds}s';
    final minutes = (seconds / 60).ceil();
    return '$minutes min';
  }

  /// Reset manuale (utile per test o logout).
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyLastSubmissionMs);
    await prefs.remove(keyBurstCount);
    await prefs.remove(keyPenaltyTier);
    await prefs.remove(keyCooldownUntilMs);
  }
}
