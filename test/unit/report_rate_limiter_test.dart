// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gscanner/services/report_rate_limiter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime simulatedTime;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    simulatedTime = DateTime(2026, 11, 19, 10, 0, 0);
    ReportRateLimiter.clock = () => simulatedTime;
    await ReportRateLimiter.reset();
  });

  tearDown(() {
    ReportRateLimiter.clock = () => DateTime.now();
  });

  group('ReportRateLimiter Tests', () {
    test('initial state allows submission with 0s cooldown', () async {
      final remaining = await ReportRateLimiter.getRemainingCooldownSeconds();
      expect(remaining, 0);
      expect(await ReportRateLimiter.isBlocked(), isFalse);
    });

    test('enforces 10-second minimum interval between reports', () async {
      // 1ª segnalazione
      await ReportRateLimiter.recordSubmission();

      // Subito dopo (0s passati)
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 10);
      expect(await ReportRateLimiter.isBlocked(), isTrue);

      // Dopo 4 secondi
      simulatedTime = simulatedTime.add(const Duration(seconds: 4));
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 6);

      // Dopo 10 secondi esatti
      simulatedTime = simulatedTime.add(const Duration(seconds: 6));
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 0);
      expect(await ReportRateLimiter.isBlocked(), isFalse);
    });

    test('triggers Tier 1 cooldown (1 min) after 5 consecutive rapid reports', () async {
      // 1ª segnalazione a t=0
      await ReportRateLimiter.recordSubmission();

      // 2ª segnalazione a t=10s
      simulatedTime = simulatedTime.add(const Duration(seconds: 10));
      await ReportRateLimiter.recordSubmission();

      // 3ª segnalazione a t=20s
      simulatedTime = simulatedTime.add(const Duration(seconds: 10));
      await ReportRateLimiter.recordSubmission();

      // 4ª segnalazione a t=30s
      simulatedTime = simulatedTime.add(const Duration(seconds: 10));
      await ReportRateLimiter.recordSubmission();

      // 5ª segnalazione a t=40s (raggiunge max burst)
      simulatedTime = simulatedTime.add(const Duration(seconds: 10));
      await ReportRateLimiter.recordSubmission();

      // Scatta Tier 1 (60s di cooldown)
      final remaining = await ReportRateLimiter.getRemainingCooldownSeconds();
      expect(remaining, 60);
      expect(await ReportRateLimiter.isBlocked(), isTrue);

      // A t=70s (30s trascorsi nel cooldown)
      simulatedTime = simulatedTime.add(const Duration(seconds: 30));
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 30);

      // A t=100s (60s trascorsi: cooldown terminato)
      simulatedTime = simulatedTime.add(const Duration(seconds: 30));
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 0);
      expect(await ReportRateLimiter.isBlocked(), isFalse);
    });

    test('progresses through scalar penalty tiers (1m -> 10m -> 30m -> 60m)', () async {
      // 5 segnalazioni iniziali -> entra in Tier 1 (1 min)
      for (int i = 0; i < 5; i++) {
        if (i > 0) simulatedTime = simulatedTime.add(const Duration(seconds: 10));
        await ReportRateLimiter.recordSubmission();
      }

      // Cooldown Tier 1 (60s)
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 60);
      simulatedTime = simulatedTime.add(const Duration(seconds: 60));
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 0);

      // 6ª segnalazione inviata subito dopo Tier 1 (senza pausa di buona condotta) -> scatta Tier 2 (10 min = 600s)
      await ReportRateLimiter.recordSubmission();
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 600);
      simulatedTime = simulatedTime.add(const Duration(seconds: 600));
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 0);

      // 7ª segnalazione subito dopo -> scatta Tier 3 (30 min = 1800s)
      await ReportRateLimiter.recordSubmission();
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 1800);
      simulatedTime = simulatedTime.add(const Duration(seconds: 1800));
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 0);

      // 8ª segnalazione subito dopo -> scatta Tier 4 max (60 min = 3600s)
      await ReportRateLimiter.recordSubmission();
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 3600);
      simulatedTime = simulatedTime.add(const Duration(seconds: 3600));
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 0);

      // Un'altra segnalazione rimane al cap massimo Tier 4 (3600s)
      await ReportRateLimiter.recordSubmission();
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 3600);
    });

    test('dynamic reset window restores user to Tier 0 after good conduct pause', () async {
      // Arriva a Tier 1 (5 segnalazioni -> blocco 60s, reset window dinamica = 180s / 3 minuti)
      for (int i = 0; i < 5; i++) {
        if (i > 0) simulatedTime = simulatedTime.add(const Duration(seconds: 10));
        await ReportRateLimiter.recordSubmission();
      }

      // Fine cooldown a +60s
      simulatedTime = simulatedTime.add(const Duration(seconds: 60));
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 0);

      // Pausa di buona condotta: aspetta più della finestra dinamica di 3 minuti (es. 3 min e 5s)
      simulatedTime = simulatedTime.add(const Duration(seconds: 185));

      // La nuova segnalazione trova lo stato completamente azzerato (Tier 0, burst=1)
      await ReportRateLimiter.recordSubmission();

      // Intervallo normale di 10s (NON Tier 2!)
      expect(await ReportRateLimiter.getRemainingCooldownSeconds(), 10);
    });

    test('formatRemainingTime formats seconds and minutes correctly', () {
      expect(ReportRateLimiter.formatRemainingTime(0), '0s');
      expect(ReportRateLimiter.formatRemainingTime(45), '45s');
      expect(ReportRateLimiter.formatRemainingTime(59), '59s');
      expect(ReportRateLimiter.formatRemainingTime(60), '1 min');
      expect(ReportRateLimiter.formatRemainingTime(600), '10 min');
      expect(ReportRateLimiter.formatRemainingTime(1800), '30 min');
      expect(ReportRateLimiter.formatRemainingTime(3600), '60 min');
    });
  });
}
