// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SyncDataScreen extends StatelessWidget {
  final int historyCount;
  final Function(bool) onDecision;

  const SyncDataScreen({
    super.key,
    required this.historyCount,
    required this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),

            // Icona Animata / Decorativa
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_sync_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),

            // Testi
            Text(
              "Dati Locali Rilevati",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Abbiamo trovato $historyCount scansioni effettuate in precedenza sul tuo telefono.\n\nOra che hai un account, vuoi collegare questi dati al tuo profilo o preferisci iniziare da zero?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const Spacer(),

            // Pulsante 1: Mantieni
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onDecision(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.sync),
                label: const Text(
                  "Unisci i dati al mio account",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pulsante 2: Elimina
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onDecision(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.delete_sweep),
                label: const Text(
                  "Cancella e inizia da zero",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
