import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
              fontWeight: kIsWeb ? FontWeight.w600 : FontWeight.w500,
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
              border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _buildToggleItem(
                  title: "Avvertimento Additivi",
                  subtitle:
                      "Genera un avviso per amidi modificati o aromi senza origine specificata.",
                  value: widget.settings.warnAdditives,
                  onChanged: (val) => _handleToggle(val, 'warnAdditives'),
                  isFirst: true,
                ),
                _buildToggleItem(
                  title: "Filtro Rigido Contaminazioni",
                  subtitle:
                      "Segnala come 'Vietato' qualsiasi alimento con dicitura \"può contenere tracce di glutine\".",
                  value: widget.settings.strictMode,
                  onChanged: (val) => _handleToggle(val, 'strictMode'),
                ),
                _buildToggleItem(
                  title: "Intolleranza al Lattosio",
                  subtitle:
                      "Verifica la presenza di lattosio, burro, polvere di latte o siero.",
                  value: widget.settings.alertLactose,
                  onChanged: (val) => _handleToggle(val, 'alertLactose'),
                  isLast: true,
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
              border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
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
            splashColor: error.withValues(alpha: 0.12),
            highlightColor: error.withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorContainer.withValues(alpha: 0.3),
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

  // ── M3 Account Card Unificata (Pagina Principale) ──────────────────────
  Widget _buildAccountCard(bool isAnonymous, User? currentUser) {
    final String displayName =
        _optimisticDisplayName ?? currentUser?.displayName ?? "";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
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
                      side: BorderSide(
                        color: outlineVariant.withValues(alpha: 0.5),
                      ),
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
          color: primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: primary, size: size * 0.5),
      );
    }
  }

  // ── Bottom Sheet Animato: Gestione & Modifica Nome ──────────────────
  void _showAccountManagementMenu(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Stato locale del Bottom Sheet
    bool isEditingName = false;
    final TextEditingController nameController = TextEditingController(
      text: _optimisticDisplayName ?? currentUser.displayName ?? "",
    );

    // FocusNode per gestire l'apertura ritardata e fluida della tastiera
    final FocusNode nameFocusNode = FocusNode();

    // Recupero Dati Provider (Google, Facebook, Email)
    String providerName = "Account";
    IconData providerIcon = Icons.account_circle_outlined;
    if (currentUser.providerData.isNotEmpty) {
      final pid = currentUser.providerData.first.providerId;
      if (pid.contains('google')) {
        providerName = "Google";
        providerIcon = Icons.g_mobiledata; // fallback, overridden below
      } else if (pid.contains('facebook')) {
        providerName = "Facebook";
        providerIcon = Icons.facebook; // fallback, overridden below
      } else if (pid.contains('password')) {
        providerName = "Email";
        providerIcon = Icons.email_outlined;
      } else if (pid.contains('phone')) {
        providerName = "Telefono";
        providerIcon = Icons.phone_android;
      }
    }
    final String identifier =
        (currentUser.email != null && currentUser.email!.isNotEmpty)
        ? currentUser.email!
        : ((currentUser.phoneNumber != null &&
                  currentUser.phoneNumber!.isNotEmpty)
              ? currentUser.phoneNumber!
              : "Dati cloud");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      backgroundColor: surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final String currentDisplayName =
                _optimisticDisplayName ?? currentUser.displayName ?? "";

            // Funzione helper per tornare al menu fluidamente nascondendo prima la tastiera
            void goBackToMenu() {
              nameFocusNode.unfocus(); // Scende la tastiera
              Future.delayed(const Duration(milliseconds: 200), () {
                if (ctx.mounted) {
                  setModalState(() => isEditingName = false); // Animazione UI
                }
              });
            }

            // ── VISTA 1: IL MENU ACCOUNT ────────────────
            Widget buildMenuView() {
              return Column(
                key: const ValueKey("MenuView"),
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Maniglia Superiore
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      margin: const EdgeInsets.only(top: 16, bottom: 24),
                      decoration: BoxDecoration(
                        color: outlineVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // ── Area Profilo Libera ──
                  _buildUserAvatar(false, size: 80),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      currentDisplayName.isNotEmpty
                          ? currentDisplayName
                          : "Aggiungi il tuo nome",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bottone "Modifica"
                  OutlinedButton.icon(
                    onPressed: () {
                      nameController.text = currentDisplayName;
                      setModalState(
                        () => isEditingName = true,
                      ); // Cambia pagina

                      // Apre la tastiera solo DOPO che l'animazione della pagina è finita
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (ctx.mounted && nameFocusNode.canRequestFocus) {
                          nameFocusNode.requestFocus();
                        }
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: onSurface,
                      side: BorderSide(
                        color: outlineVariant.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      "Modifica Nome",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Card Integrata (Info Provider + Azioni) ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceLowest,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          // 1. Riga Informativa Ridisegnata e Bilanciata
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icona Provider (Quadrato smussato o logo pulito)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  // Rimuove lo sfondo se è Google o Facebook
                                  color:
                                      (providerName == "Google" ||
                                          providerName == "Facebook")
                                      ? Colors.transparent
                                      : surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: providerName == "Google"
                                    ? Image.asset(
                                        'assets/icons/google.png',
                                        width: 28,
                                        height: 28,
                                      )
                                    : providerName == "Facebook"
                                    ? Image.asset(
                                        'assets/icons/facebook.png',
                                        width: 28,
                                        height: 28,
                                      )
                                    : Icon(
                                        providerIcon,
                                        color: onSurfaceVariant,
                                        size: 24,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Identificatore (Email/Telefono) come Titolo principale
                                    Text(
                                      identifier,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    const SizedBox(height: 2),
                                    // Metodo di connessione come Sottotitolo
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.link,
                                          size: 14,
                                          color: onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            "Collegato con $providerName",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          // Divisorio per separare nettamente le info dalle azioni
                          Divider(
                            height: 1,
                            color: outlineVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 20),

                          // 2. Bottone Esci (Pieno e arrotondato)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _handleLogout();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: surfaceContainer,
                                foregroundColor: onSurface,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              icon: const Icon(Icons.logout, size: 20),
                              label: const Text(
                                "Esci dall'account",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 3. Bottone Elimina (Visivamente pericoloso)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _handleDeleteAccount();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: error,
                                backgroundColor: errorContainer.withValues(
                                  alpha: 0.3,
                                ),
                                side: const BorderSide(color: errorContainer),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              icon: const Icon(
                                Icons.person_remove_outlined,
                                size: 20,
                              ),
                              label: const Text(
                                "Elimina Account",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32), // Spazio dal fondo del telefono
                ],
              );
            }

            // ── VISTA 2: EDIT NOME (Appare in fade) ───────────────────────
            // ── VISTA 2: EDIT NOME (Appare in fade) ───────────────────────
            Widget buildEditNameView() {
              return Column(
                key: const ValueKey("EditNameView"),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      margin: const EdgeInsets.only(top: 16, bottom: 16),
                      decoration: BoxDecoration(
                        color: outlineVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Header con Back Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: onSurfaceVariant,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: surfaceContainerHigh,
                          ),
                          onPressed: goBackToMenu, // Torna fluidamente
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Modifica Nome",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Scegli come vuoi farti chiamare. Questo nome sarà visibile all'interno dell'app.",
                          style: TextStyle(
                            color: onSurfaceVariant,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── TEXTFIELD AGGIORNATO (Stile SearchBar) ──
                        TextField(
                          controller: nameController,
                          focusNode: nameFocusNode,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontSize:
                                14, // Uniformato alla grandezza della search bar
                            color: onSurface,
                          ),
                          cursorColor: primary,
                          decoration: InputDecoration(
                            hintText: "Es. Mario Rossi",
                            hintStyle: TextStyle(
                              color: onSurfaceVariant.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: surfaceContainer, // Colore morbido M3
                            contentPadding: const EdgeInsets.symmetric(
                              vertical:
                                  0, // 0 per bilanciarsi perfettamente con il prefixIcon
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                999,
                              ), // Forma a pillola
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: goBackToMenu,
                              style: TextButton.styleFrom(
                                foregroundColor: onSurfaceVariant,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                "Annulla",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: nameController,
                              builder: (context, value, child) {
                                final bool isValid = value.text
                                    .trim()
                                    .isNotEmpty;
                                return FilledButton(
                                  onPressed: isValid
                                      ? () async {
                                          final newName = value.text.trim();
                                          if (newName != currentDisplayName) {
                                            // Optimistic Update visibile subito
                                            setState(
                                              () => _optimisticDisplayName =
                                                  newName,
                                            );
                                            goBackToMenu(); // Torna al menu

                                            // Salva nel cloud in background
                                            try {
                                              await currentUser
                                                  .updateDisplayName(newName);
                                            } catch (e) {
                                              // Fallback silenzioso
                                            }
                                          } else {
                                            goBackToMenu();
                                          }
                                        }
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Padding(
              // isScrollControlled: true gestisce automaticamente la tastiera
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: AnimatedSize(
                // AnimatedSize gestisce la variazione di altezza fra il menu e il form
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  // AnimatedSwitcher dissolve la pagina A nella pagina B
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: isEditingName ? buildEditNameView() : buildMenuView(),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Pulizia quando l'intero Bottom Sheet viene trascinato via e chiuso
      nameFocusNode.dispose();
    });
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
                  if (val != null) setState(() => _selectedTheme = val);
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
                bottom: BorderSide(
                  color: outlineVariant.withValues(alpha: 0.2),
                ),
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
            activeThumbColor: surfaceLowest,
            activeTrackColor: primary,
            inactiveThumbColor: onSurfaceVariant.withValues(alpha: 0.7),
            inactiveTrackColor: surfaceContainerHigh,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
