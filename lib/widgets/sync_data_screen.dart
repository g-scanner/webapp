import 'package:flutter/material.dart';

const Color surfaceLowest = Color(0xFFFFFFFF);
const Color surfaceVariant = Color(0xFFE3E2E6);
const Color primary = Color(0xFF0D631B);
const Color onPrimary = Color(0xFFFFFFFF);
const Color onSurface = Color(0xFF1B1B1E);
const Color onSurfaceVariant = Color(0xFF40493D);
const Color error = Color(0xFFBA1A1A);

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
                color: primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_sync_outlined,
                size: 64,
                color: primary,
              ),
            ),
            const SizedBox(height: 32),

            // Testi
            const Text(
              "Dati Locali Rilevati",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Abbiamo trovato $historyCount scansioni effettuate in precedenza sul tuo telefono.\n\nOra che hai un account, vuoi collegare questi dati al tuo profilo o preferisci iniziare da zero?",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: onSurfaceVariant,
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
                  backgroundColor: primary,
                  foregroundColor: onPrimary,
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
                  foregroundColor: error,
                  side: const BorderSide(color: error),
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
