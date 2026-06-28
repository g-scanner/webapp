import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/types.dart';

// --- Colori estratti dal tuo Tailwind Config ---
const Color bgBackground = Color(0xFFFAF9FC);
const Color surfaceLowest = Color(0xFFFFFFFF);
const Color onSurface = Color(0xFF1B1B1E);
const Color onSurfaceVariant = Color(0xFF40493D);
const Color surfaceContainer = Color(0xFFEFEDF1);
const Color surfaceContainerHigh = Color(0xFFE9E7EB);
const Color outlineVariant = Color(0xFFBFCABA);

const Color primary = Color(0xFF0D631B);
const Color error = Color(0xFFBA1A1A);
const Color errorContainer = Color(0xFFFFDAD6);

class SettingsPanel extends StatefulWidget {
  final UserSettings settings;
  final Future<void> Function(UserSettings) onSettingsChange;
  final Future<void> Function() onResetDB;
  final Future<void> Function() onClearHistory;

  const SettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChange,
    required this.onResetDB,
    required this.onClearHistory,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  bool _clearing = false;

  // Variabile temporanea per il tema (Chiaro/Scuro/Sistema)
  String _selectedTheme = 'system';

  void _triggerToast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: onSurface,
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: surfaceLowest),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: surfaceLowest,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      ),
    );
  }

  Future<void> _handleToggle(bool value, String key) async {
    final updated = UserSettings(
      userId: widget.settings.userId,
      strictMode: key == 'strictMode' ? value : widget.settings.strictMode,
      alertLactose: key == 'alertLactose'
          ? value
          : widget.settings.alertLactose,
      warnAdditives: key == 'warnAdditives'
          ? value
          : widget.settings.warnAdditives,
      autoSaveHistory: widget.settings.autoSaveHistory,
      preferredLanguage: widget.settings.preferredLanguage,
    );
    await widget.onSettingsChange(updated);
    _triggerToast("Preferenze salvate ed applicate!");
  }

  @override
  Widget build(BuildContext context) {
    // Leggiamo lo stato dell'utente corrente da Firebase
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isAnonymous = currentUser?.isAnonymous ?? true;
    final String userEmail = currentUser?.email ?? "";

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Intestazione Pagina ─────────────────────────────────────
          const Text(
            "Impostazioni",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Gestisci il tuo profilo, l'analisi degli ingredienti e i dati salvati.",
            style: TextStyle(
              fontSize: 14,
              color: onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // ── 1. Sezione: Account ──────────────────────────────────────
          _buildSectionHeader(
            icon: Icons.account_circle_outlined,
            title: "Il tuo Account",
            color: primary,
          ),
          const SizedBox(height: 16),
          _buildAccountCard(isAnonymous, userEmail),

          const SizedBox(height: 40),

          // ── 2. Sezione: Allergeni e Sensibilità ────────────────────────
          _buildSectionHeader(
            icon: Icons.tune,
            title: "Regole di Analisi",
            color: primary,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceLowest,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: outlineVariant.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _buildToggleItem(
                  title: "Avvertimento Additivi",
                  subtitle:
                      "Genera un avviso per amidi modificati o aromi senza origine specificata.",
                  value: widget.settings.warnAdditives,
                  onChanged: (val) => _handleToggle(val, 'warnAdditives'),
                  isLast: true,
                ),
                _buildToggleItem(
                  title: "Filtro Rigido Contaminazioni",
                  subtitle:
                      "Segnala come 'Vietato' qualsiasi alimento con dicitura \"può contenere tracce di glutine\".",
                  value: widget.settings.strictMode,
                  onChanged: (val) => _handleToggle(val, 'strictMode'),
                  isFirst: true,
                ),
                _buildToggleItem(
                  title: "Intolleranza al Lattosio",
                  subtitle:
                      "Verifica la presenza di lattosio, burro, polvere di latte o siero.",
                  value: widget.settings.alertLactose,
                  onChanged: (val) => _handleToggle(val, 'alertLactose'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // ── 3. Sezione: Aspetto ─────────────────────────────────────────
          _buildSectionHeader(
            icon: Icons.palette_outlined,
            title: "Aspetto",
            color: primary,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceLowest,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: outlineVariant.withOpacity(0.3)),
            ),
            child: _buildThemeSelector(),
          ),

          const SizedBox(height: 40),

          // ── 4. Sezione: Dati Locali ────────────────────────────────────
          _buildSectionHeader(
            icon: Icons.storage,
            title: "Dati Locali",
            color: primary,
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: _clearing
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: surfaceLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        title: const Text(
                          "Svuota Cronologia",
                          style: TextStyle(color: onSurface),
                        ),
                        content: const Text(
                          "Sei sicuro di voler eliminare tutte le scansioni salvate sul tuo dispositivo? L'azione non è reversibile.",
                          style: TextStyle(color: onSurfaceVariant),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: TextButton.styleFrom(
                              foregroundColor: onSurfaceVariant,
                            ),
                            child: const Text("Annulla"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: error),
                            child: const Text("Svuota"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      setState(() => _clearing = true);
                      try {
                        await widget.onClearHistory();
                        _triggerToast("Cronologia svuotata con successo!");
                      } finally {
                        if (mounted) setState(() => _clearing = false);
                      }
                    }
                  },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: errorContainer),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: _clearing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: error,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.delete_outline,
                            color: error,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Svuota Cronologia",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: error,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Elimina le ultime scansioni dal telefono",
                          style: TextStyle(fontSize: 13, color: error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Helper per la Card Account
  Widget _buildAccountCard(bool isAnonymous, String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isAnonymous
                      ? surfaceContainerHigh
                      : primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAnonymous ? Icons.person_outline : Icons.person,
                  color: isAnonymous ? onSurfaceVariant : primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAnonymous ? "Utente Anonimo" : email,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAnonymous
                          ? "Le tue scansioni sono salvate solo sul dispositivo."
                          : "Account sincronizzato sul cloud in sicurezza.",
                      style: const TextStyle(
                        fontSize: 13,
                        color: onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _triggerToast(
                  "Il Login multi-dispositivo arriverà nel prossimo aggiornamento!",
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: onSurface,
                side: BorderSide(color: outlineVariant.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: Icon(
                isAnonymous ? Icons.login : Icons.manage_accounts,
                size: 18,
                color: onSurfaceVariant,
              ),
              label: Text(
                isAnonymous ? "Accedi o Registrati" : "Gestisci Account",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper per l'intestazione delle sezioni
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ],
    );
  }

  // Helper per il selettore del tema
  Widget _buildThemeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tema dell'app",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: onSurface,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Chiaro, scuro o uguale al sistema",
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTheme,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: onSurfaceVariant,
                ),
                dropdownColor: surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
                items: const [
                  DropdownMenuItem(value: 'system', child: Text("Sistema")),
                  DropdownMenuItem(value: 'light', child: Text("Chiaro")),
                  DropdownMenuItem(value: 'dark', child: Text("Scuro")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedTheme = val);
                    // TODO: Qui aggiungeremo il salvataggio nelle impostazioni globali in futuro
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper per i singoli elementi Toggle
  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: outlineVariant.withOpacity(0.2)),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: surfaceLowest,
            activeTrackColor: primary,
            inactiveThumbColor: onSurfaceVariant.withOpacity(0.7),
            inactiveTrackColor: surfaceContainerHigh,
            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
