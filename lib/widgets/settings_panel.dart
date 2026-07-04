import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/types.dart';
import '../services/db_service.dart';

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
  String _selectedTheme = 'system';

  // Variabile per l'aggiornamento UI istantaneo ("Optimistic Update")
  String? _optimisticDisplayName;

  void _triggerToast(String msg) {
    if (!mounted) return;
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isAnonymous = currentUser?.isAnonymous ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

          _buildSectionHeader(
            icon: Icons.attribution_rounded,
            title: "Il tuo Account",
            color: primary,
          ),
          const SizedBox(height: 16),
          _buildAccountCard(isAnonymous, currentUser),

          const SizedBox(height: 40),

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

          _buildSectionHeader(
            icon: Icons.data_usage,
            title: "Dati e Cronologia",
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
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        title: const Text(
                          "Svuota Cronologia",
                          style: TextStyle(color: onSurface),
                        ),
                        content: const Text(
                          "Sei sicuro di voler eliminare tutta la cronologia delle scansioni? Questa azione non è reversibile.",
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
                          "Rimuove in modo permanente la tua cronologia scansioni.",
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

  // ── M3 Account Card Unificata ─────────────────────────────────────────
  Widget _buildAccountCard(bool isAnonymous, User? currentUser) {
    // Usa il nome ottimistico se presente, altrimenti quello di Firebase
    final String displayName =
        _optimisticDisplayName ?? currentUser?.displayName ?? "";

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
              _buildUserAvatar(isAnonymous, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAnonymous
                          ? "Utente Ospite"
                          : (displayName.isNotEmpty
                                ? displayName
                                : "Utente Registrato"),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAnonymous
                          ? "Le tue scansioni sono salvate solo su questo dispositivo."
                          : "Il tuo profilo e le scansioni sono sincronizzati sul cloud.",
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
            child: isAnonymous
                ? FilledButton.tonalIcon(
                    onPressed: () => _handleAnonymousAction(),
                    style: FilledButton.styleFrom(
                      backgroundColor: surfaceContainer,
                      foregroundColor: onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.login, size: 20),
                    label: const Text(
                      "Accedi o Registrati",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _showAccountManagementMenu(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: onSurface,
                      side: BorderSide(color: outlineVariant.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.manage_accounts_outlined, size: 20),
                    label: const Text(
                      "Gestisci Account",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Costruisce l'avatar base
  Widget _buildUserAvatar(bool isAnonymous, {double size = 56}) {
    if (isAnonymous) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_outline,
          color: onSurfaceVariant,
          size: size * 0.5,
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: primary, size: size * 0.5),
      );
    }
  }

  // Helper per mostrare info Provider nel BottomSheet
  Widget _buildProviderInfoTile(User currentUser) {
    String providerStr = "Sconosciuto";
    IconData providerIcon = Icons.account_circle_outlined;

    if (currentUser.providerData.isNotEmpty) {
      final pid = currentUser.providerData.first.providerId;
      if (pid.contains('google')) {
        providerStr = "Google";
        providerIcon = Icons.g_mobiledata;
      } else if (pid.contains('facebook')) {
        providerStr = "Facebook";
        providerIcon = Icons.facebook;
      } else if (pid.contains('password')) {
        providerStr = "Email";
        providerIcon = Icons.email_outlined;
      } else if (pid.contains('phone')) {
        providerStr = "Telefono";
        providerIcon = Icons.phone_android;
      }
    }

    final String identifier =
        (currentUser.email != null && currentUser.email!.isNotEmpty)
        ? currentUser.email!
        : ((currentUser.phoneNumber != null &&
                  currentUser.phoneNumber!.isNotEmpty)
              ? currentUser.phoneNumber!
              : "Nessun recapito collegato");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(providerIcon, color: onSurfaceVariant, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Accesso tramite $providerStr",
                  style: const TextStyle(fontSize: 13, color: onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  identifier,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Sheet: Gestione Avanzata Profilo ─────────────────────────
  void _showAccountManagementMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) return const SizedBox.shrink();

            // Sincronizzato con l'UI Principale
            final String displayName =
                _optimisticDisplayName ?? currentUser.displayName ?? "";

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: outlineVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    _buildUserAvatar(false, size: 80),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () =>
                          _updateDisplayName(setModalState, displayName),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName.isNotEmpty
                                  ? displayName
                                  : "Aggiungi il tuo nome",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: primary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    const SizedBox(height: 16),

                    _buildProviderInfoTile(currentUser),

                    const SizedBox(height: 16),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    const SizedBox(height: 8),

                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: onSurfaceVariant,
                      ),
                      title: const Text(
                        "Esci dall'account",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleLogout();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.person_remove_outlined,
                        color: error,
                      ),
                      title: const Text(
                        "Elimina Account",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: error,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleDeleteAccount();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Modifica Nome (Optimistic Update & Validazione live) ──────────────
  Future<void> _updateDisplayName(
    StateSetter setModalState,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: const Icon(Icons.badge_outlined, color: primary, size: 32),
        title: const Text(
          "Modifica Nome",
          style: TextStyle(
            color: onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Scegli come vuoi farti chiamare. Questo nome sarà visibile all'interno dell'app.",
              style: TextStyle(
                color: onSurfaceVariant,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              style: const TextStyle(fontSize: 16, color: onSurface),
              cursorColor: primary,
              decoration: InputDecoration(
                labelText: "Il tuo nome",
                labelStyle: const TextStyle(color: onSurfaceVariant),
                filled: true,
                fillColor: surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              "Annulla",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          // Validazione in tempo reale sul testo inserito
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final bool isValid = value.text
                  .trim()
                  .isNotEmpty; // Almeno 1 carattere

              return FilledButton(
                // Se non valido (vuoto), il bottone è null -> disabilitato automaticamente
                onPressed: isValid
                    ? () => Navigator.pop(ctx, value.text.trim())
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: surfaceLowest,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  "Salva",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
    );

    // Se è stato inserito un nome valido e diverso dall'attuale
    if (newName != null && newName.isNotEmpty && newName != currentName) {
      // 1. UPDATE ISTANTANEO (Optimistic UI Update)
      setState(() {
        _optimisticDisplayName = newName;
      });
      setModalState(() {});

      // 2. ESECUZIONE SILENZIOSA IN BACKGROUND
      try {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
        // Nessun messaggio di caricamento che interrompe l'utente:
        // l'update al server è nascosto per massima fluidità.
      } catch (e) {
        // Fallback invisibile nel caso l'utente abbia un drop di connessione temporaneo
      }
    }
  }

  // ── Gestione Azioni Account ─────────────────────────────────────────

  Future<void> _handleAnonymousAction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Effettua l'accesso",
          style: TextStyle(color: onSurface),
        ),
        content: const Text(
          "Accedendo potrai sincronizzare la tua cronologia nel cloud.\nI tuoi dati locali verranno mantenuti fino al prossimo accesso.",
          style: TextStyle(color: onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: onSurfaceVariant),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: primary),
            child: const Text("Procedi"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) _triggerToast("Preparazione all'accesso...");
      try {
        await DbService.wipeAllLocalData();
        await FirebaseAuth.instance.currentUser?.delete();
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        if (mounted) _triggerToast("Errore: $e");
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Vuoi uscire?", style: TextStyle(color: onSurface)),
        content: const Text(
          "Uscendo dal tuo account, i dati salvati su questo dispositivo verranno rimossi per privacy.\nPotrai ripristinarli al prossimo accesso.",
          style: TextStyle(color: onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: onSurfaceVariant),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: error),
            child: const Text("Esci"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) _triggerToast("Uscita in corso...");
      try {
        await DbService.wipeAllLocalData();
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        if (mounted) _triggerToast("Errore durante la disconnessione: $e");
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: errorContainer, width: 2),
        ),
        icon: const Icon(Icons.warning_amber_rounded, color: error, size: 36),
        title: const Text(
          "Eliminazione Definitiva",
          style: TextStyle(color: error, fontSize: 20),
        ),
        content: const Text(
          "Sei sicuro di voler eliminare il tuo account e tutti i dati cloud? Questa azione è IRREVERSIBILE.\n\nNota: Per motivi di sicurezza potrebbe esserti richiesto di effettuare nuovamente l'accesso.",
          style: TextStyle(color: onSurface),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: onSurfaceVariant),
            child: const Text("Annulla"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: error,
              foregroundColor: Colors.white,
            ),
            child: const Text("Elimina"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) _triggerToast("Tentativo di eliminazione account...");
      try {
        await DbService.wipeAllLocalData();
        await FirebaseAuth.instance.currentUser?.delete();
        await FirebaseAuth.instance.signOut();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          if (mounted) {
            _triggerToast(
              "Sicurezza: Uscita forzata. Esegui un nuovo accesso e riprova ad eliminare l'account.",
            );
          }
          await FirebaseAuth.instance.signOut();
        } else {
          if (mounted) _triggerToast("Errore: ${e.message}");
        }
      } catch (e) {
        if (mounted) _triggerToast("Errore imprevisto: $e");
      }
    }
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
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
