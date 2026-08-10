// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gscanner/widgets/licenses_screen.dart';
import '../models/types.dart';
import '../services/db_service.dart';

import '../theme/app_theme.dart';

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

  // Variabile per l'aggiornamento UI istantaneo ("Optimistic Update")
  String? _optimisticDisplayName;

  void _triggerToast(String msg) {
    if (!mounted) return;
    final colorScheme = context.colorScheme;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colorScheme.inverseSurface,
        content: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.onInverseSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: colorScheme.onInverseSurface,
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
      preferredTheme: widget.settings.preferredTheme,
      reportedBarcodes: widget.settings.reportedBarcodes,
    );
    await widget.onSettingsChange(updated);
    _triggerToast("Preferenze salvate ed applicate!");
  }

  Future<void> _handleLanguageChange(String newLang) async {
    if (newLang == widget.settings.preferredLanguage) {
      return;
    }

    final updated = UserSettings(
      userId: widget.settings.userId,
      strictMode: widget.settings.strictMode,
      alertLactose: widget.settings.alertLactose,
      warnAdditives: widget.settings.warnAdditives,
      autoSaveHistory: widget.settings.autoSaveHistory,
      preferredLanguage: newLang,
      preferredTheme: widget.settings.preferredTheme,
      reportedBarcodes: widget.settings.reportedBarcodes,
    );
    await widget.onSettingsChange(updated);
    _triggerToast("Preferenze salvate ed applicate!");
  }

  Future<void> _handleThemeChange(String newTheme) async {
    if (newTheme == widget.settings.preferredTheme) {
      return;
    }

    final updated = UserSettings(
      userId: widget.settings.userId,
      strictMode: widget.settings.strictMode,
      alertLactose: widget.settings.alertLactose,
      warnAdditives: widget.settings.warnAdditives,
      autoSaveHistory: widget.settings.autoSaveHistory,
      preferredLanguage: widget.settings.preferredLanguage,
      preferredTheme: newTheme,
      reportedBarcodes: widget.settings.reportedBarcodes,
    );
    await widget.onSettingsChange(updated);
    _triggerToast("Preferenze salvate ed applicate!");
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isAnonymous = currentUser?.isAnonymous ?? true;
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Impostazioni",
            style: TextStyle(
              fontSize: 22,
              fontWeight: kIsWeb ? FontWeight.w600 : FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Gestisci il tuo profilo, l'analisi degli ingredienti e i dati salvati.",
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader(
            icon: Icons.attribution_rounded,
            title: "Il tuo Account",
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _buildAccountCard(isAnonymous, currentUser),

          const SizedBox(height: 40),

          _buildSectionHeader(
            icon: Icons.tune,
            title: "Regole di Analisi",
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Material(
            color: cardBg,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
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
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: _buildThemeSelector(),
          ),

          const SizedBox(height: 40),

          _buildSectionHeader(
            icon: Icons.translate_outlined,
            title: "Lingua",
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: _buildLanguageSelector(),
          ),

          const SizedBox(height: 40),

          _buildSectionHeader(
            icon: Icons.data_usage,
            title: "Dati e Cronologia",
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: _clearing
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: ctx.cardBackground,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        title: Text(
                          "Svuota Cronologia",
                          style: TextStyle(color: ctx.colorScheme.onSurface),
                        ),
                        content: Text(
                          "Sei sicuro di voler eliminare tutta la cronologia delle scansioni? Questa azione non è reversibile.",
                          style: TextStyle(color: ctx.colorScheme.onSurfaceVariant),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: TextButton.styleFrom(
                              foregroundColor: ctx.colorScheme.onSurfaceVariant,
                            ),
                            child: const Text("Annulla"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.error),
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
            splashColor: colorScheme.error.withValues(alpha: 0.12),
            highlightColor: colorScheme.error.withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.errorContainer),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: _clearing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: colorScheme.error,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.delete_outline,
                            color: colorScheme.error,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Svuota Cronologia",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rimuove in modo permanente la tua cronologia scansioni.",
                          style: TextStyle(fontSize: 13, color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          _buildSectionHeader(
            icon: Icons.info_outline_rounded,
            title: "Informazioni Legali",
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),

          Material(
            color: cardBg,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _buildLegalItem(
                  title: "Termini e Condizioni",
                  subtitle: Text(
                    "Consulta le regole di utilizzo dell'applicazione e dei servizi offerti.",
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  onTap: () {
                    _showLegalBottomSheet(
                      context,
                      "Termini e Condizioni",
                      _buildNativeTos(colorScheme.onSurfaceVariant),
                    );
                  },
                  showTrailingArrow: true,
                  isFirst: true,
                ),
                _buildLegalItem(
                  title: "Privacy Policy",
                  subtitle: Text(
                    "Scopri come raccogliamo, gestiamo e proteggiamo i tuoi dati personali.",
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  onTap: () {
                    _showLegalBottomSheet(
                      context,
                      "Privacy Policy",
                      _buildNativePrivacyPolicy(colorScheme.onSurfaceVariant),
                    );
                  },
                  showTrailingArrow: true,
                ),
                _buildLegalItem(
                  title: "Licenze",
                  subtitle: Text(
                    "Consulta le licenze open source dei pacchetti e delle librerie utilizzate in questa app.",
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomLicensesPage(),
                      ),
                    );
                  },
                  showTrailingArrow: true,
                  isLast: true,
                ),
              ],
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
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAnonymous
                          ? "Le tue scansioni sono salvate solo su questo dispositivo."
                          : "Il tuo profilo e le scansioni sono sincronizzati sul cloud.",
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
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
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurface,
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
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
    final colorScheme = context.colorScheme;
    if (isAnonymous) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_outline,
          color: colorScheme.onSurfaceVariant,
          size: size * 0.5,
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: colorScheme.primary, size: size * 0.5),
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
      useRootNavigator: false,
      constraints: const BoxConstraints(maxWidth: 500),
      backgroundColor: context.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        final colorScheme = ctx.colorScheme;
        final cardBg = ctx.cardBackground;
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
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
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
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                        color: cardBg,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                                      : colorScheme.surfaceContainerHigh,
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
                                        color: colorScheme.onSurfaceVariant,
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
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    const SizedBox(height: 2),
                                    // Metodo di connessione come Sottotitolo
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.link,
                                          size: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            "Collegato con $providerName",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colorScheme.onSurfaceVariant,
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
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                foregroundColor: colorScheme.onSurface,
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
                                foregroundColor: colorScheme.error,
                                backgroundColor: colorScheme.errorContainer.withValues(
                                  alpha: 0.3,
                                ),
                                side: BorderSide(color: colorScheme.errorContainer),
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
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                          icon: Icon(
                            Icons.arrow_back,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerHigh,
                          ),
                          onPressed: goBackToMenu, // Torna fluidamente
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Modifica Nome",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
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
                        Text(
                          "Scegli come vuoi farti chiamare. Questo nome sarà visibile all'interno dell'app.",
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
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
                          style: TextStyle(
                            fontSize:
                                14, // Uniformato alla grandezza della search bar
                            color: colorScheme.onSurface,
                          ),
                          cursorColor: colorScheme.primary,
                          decoration: InputDecoration(
                            hintText: "Es. Mario Rossi",
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 48,
                              maxWidth: 48,
                              minHeight: 48,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Icon(
                                Icons.badge_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
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
                                foregroundColor: colorScheme.onSurfaceVariant,
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
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
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
        backgroundColor: ctx.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Effettua l'accesso",
          style: TextStyle(color: ctx.colorScheme.onSurface),
        ),
        content: Text(
          "Accedendo potrai sincronizzare la tua cronologia nel cloud.\nI tuoi dati locali verranno mantenuti fino al prossimo accesso.",
          style: TextStyle(color: ctx.colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.onSurfaceVariant),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.primary),
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
        backgroundColor: ctx.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Vuoi uscire?", style: TextStyle(color: ctx.colorScheme.onSurface)),
        content: Text(
          "Uscendo dal tuo account, i dati salvati su questo dispositivo verranno rimossi per privacy.\nPotrai ripristinarli al prossimo accesso.",
          style: TextStyle(color: ctx.colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.onSurfaceVariant),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.error),
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final lastSignIn = user.metadata.lastSignInTime;
    final bool needsReauth =
        lastSignIn == null ||
        DateTime.now().difference(lastSignIn).inMinutes > 5;

    if (needsReauth) {
      // CASO 2: Serve riautenticazione/re-login per motivi di sicurezza
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.cardBackground,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: ctx.colorScheme.outlineVariant, width: 1.5),
          ),
          icon: Icon(Icons.security_rounded, color: ctx.colorScheme.primary, size: 36),
          title: Text(
            "Accesso richiesto per sicurezza",
            style: TextStyle(
              color: ctx.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            "Per motivi di sicurezza, prima di procedere all'eliminazione dell'account è necessario effettuare un nuovo accesso.\n\nPremendo 'Procedi' verrai disconnesso per poter rientrare e completare l'operazione.",
            style: TextStyle(color: ctx.colorScheme.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(foregroundColor: ctx.colorScheme.onSurfaceVariant),
              child: const Text("Annulla"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: ctx.colorScheme.primary,
                foregroundColor: ctx.colorScheme.onPrimary,
              ),
              child: const Text("Procedi"),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pop(context); // Chiude il Bottom Sheet settings
        }
      }
      return;
    }

    // CASO 1: Può procedere immediatamente
    bool isDeletingAccount = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: dialogCtx.cardBackground,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: dialogCtx.colorScheme.errorContainer, width: 2),
          ),
          icon: Icon(Icons.warning_amber_rounded, color: dialogCtx.colorScheme.error, size: 36),
          title: Text(
            "Eliminazione Definitiva",
            style: TextStyle(
              color: dialogCtx.colorScheme.error,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            "Sei sicuro di voler eliminare il tuo account e tutti i dati cloud? Questa azione è IRREVERSIBILE.\n\nSaranno eliminati:\n- La tua cronologia scansioni\n- Le tue impostazioni personali\n\nI tuoi report inseriti rimarranno ma verranno anonimizzati.",
            style: TextStyle(color: dialogCtx.colorScheme.onSurface, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: isDeletingAccount
                  ? null
                  : () => Navigator.pop(dialogCtx),
              style: TextButton.styleFrom(foregroundColor: dialogCtx.colorScheme.onSurfaceVariant),
              child: const Text("Annulla"),
            ),
            FilledButton(
              onPressed: isDeletingAccount
                  ? null
                  : () async {
                      setDialogState(() {
                        isDeletingAccount = true;
                      });
                      try {
                        final String uid = user.uid;
                        await Future.wait([
                          DbService.deleteUserSettings(uid),
                          DbService.deleteUserHistory(uid),
                          DbService.anonymizeUserReports(uid),
                          DbService.wipeCurrentUserLocalData(),
                        ]);

                        // Chiude il popup e la bottom sheet tornando a MainScreen
                        if (dialogCtx.mounted) {
                          Navigator.of(
                            dialogCtx,
                          ).popUntil((route) => route.isFirst);
                        }

                        await user.delete();
                        await FirebaseAuth.instance.signOut();
                      } on FirebaseAuthException catch (e) {
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (e.code == 'requires-recent-login') {
                          if (mounted) {
                            _triggerToast(
                              "Sicurezza: Uscita forzata. Esegui un nuovo accesso e riprova.",
                            );
                          }
                          await FirebaseAuth.instance.signOut();
                        } else {
                          if (mounted) _triggerToast("Errore: ${e.message}");
                        }
                      } catch (e) {
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (mounted) _triggerToast("Errore imprevisto: $e");
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: dialogCtx.colorScheme.error,
                foregroundColor: dialogCtx.colorScheme.onError,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: isDeletingAccount ? 0.0 : 1.0,
                    child: const Text(
                      "Elimina definitivamente",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (isDeletingAccount)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: dialogCtx.colorScheme.onError.withValues(alpha: 0.7),
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Sheet Legale M3 ──────────────────────────────────────────
  void _showLegalBottomSheet(
    BuildContext context,
    String title,
    Widget content,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      constraints: const BoxConstraints(maxWidth: 500),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final double sheetHeight = MediaQuery.of(ctx).size.height * 0.85;
        return Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: ctx.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Maniglia M3
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(top: 16, bottom: 24),
                  decoration: BoxDecoration(
                    color: ctx.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Titolo e pulsante chiudi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: ctx.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Contenuto scrollabile
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: SafeArea(top: false, child: content),
                ),
              ),
            ],
          ),
        );
      },
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
    final themeLabels = {
      'system': 'Sistema',
      'light': 'Chiaro',
      'dark': 'Scuro',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tema dell'app",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Chiaro, scuro o uguale al sistema",
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Pulsante con effetto splash M3
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            clipBehavior:
                Clip.antiAlias, // Taglia lo splash sui bordi arrotondati
            child: PopupMenuButton<String>(
              tooltip: "Scegli tema",
              initialValue: widget.settings.preferredTheme,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).cardColor,
              position: PopupMenuPosition.under,
              onSelected: (val) => _handleThemeChange(val),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'system', child: Text("Sistema")),
                PopupMenuItem(value: 'light', child: Text("Chiaro")),
                PopupMenuItem(value: 'dark', child: Text("Scuro")),
              ],
              child: SizedBox(
                width: 110,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themeLabels[widget.settings.preferredTheme] ?? 'Sistema',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper per il selettore lingua
  Widget _buildLanguageSelector() {
    final langLabels = {
      'it': 'Italiano',
      'en': 'Inglese',
      'es': 'Spagnolo',
      'de': 'Tedesco',
      'fr': 'Francese',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lingua preferita",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Lingua preferita per gli ingredienti",
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Pulsante con effetto splash M3
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: PopupMenuButton<String>(
              tooltip: "Scegli lingua",
              initialValue: widget.settings.preferredLanguage,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).cardColor,
              position: PopupMenuPosition.under,
              onSelected: (val) => _handleLanguageChange(val),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'it', child: Text("Italiano")),
                PopupMenuItem(value: 'en', child: Text("Inglese")),
                PopupMenuItem(value: 'es', child: Text("Spagnolo")),
                PopupMenuItem(value: 'de', child: Text("Tedesco")),
                PopupMenuItem(value: 'fr', child: Text("Francese")),
              ],
              child: SizedBox(
                width: 110,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          langLabels[widget.settings.preferredLanguage] ??
                              'Italiano',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
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
    final colorScheme = context.colorScheme;
    return Container(
      // Manteniamo il padding dinamico
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: isFirst ? 24.0 : 16.0,
        bottom: isLast ? 24.0 : 16.0,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged, // Solo lo Switch risponderà al tocco
            activeThumbColor: colorScheme.onPrimary,
            activeTrackColor: colorScheme.primary,
            inactiveThumbColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            inactiveTrackColor: colorScheme.surfaceContainerHigh,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

// Helper per i singoli elementi testuali/cliccabili (Stile gemello a _buildToggleItem)
Widget _buildLegalItem({
  required String title,
  required Widget subtitle,
  VoidCallback? onTap,
  bool isFirst = false,
  bool showTrailingArrow = true,
  bool isLast = false,
}) {
  final bool hasTrailingArrow = onTap != null && showTrailingArrow;

  return Builder(
    builder: (context) {
      final colorScheme = context.colorScheme;
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: isFirst ? 24.0 : 16.0,
            bottom: isLast ? 24.0 : 16.0,
          ),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
          ),
          child: hasTrailingArrow
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          subtitle,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Transform.translate(
                      offset: const Offset(8, 0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        size: 26,
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      subtitle,
                    ],
                  ),
                ),
        ),
      );
    },
  );
}

Widget _buildNativeTos(Color textColor) {
  // Helper per creare le parti in grassetto automaticamente e velocemente
  Widget pContent(String text) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: i % 2 == 1 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
        children: spans,
      ),
    );
  }

  Widget h1(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
  );

  Widget h2(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
  );

  Widget p(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: pContent(text),
  );

  Widget bullet(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "• ",
          style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
        ),
        Expanded(child: pContent(text)),
      ],
    ),
  );

  Widget divider() => const Divider(height: 32);

  return SingleChildScrollView(
    child: SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          h2("Termini e Condizioni d'Uso (ToS) di G-Scanner"),
          p(
            "**Versione:** 1.0\n**Data di entrata in vigore:** 17 luglio 2026\n**Data di ultimo aggiornamento:** 17 luglio 2026",
          ),
          divider(),

          p(
            "Il presente documento disciplina l'accesso e l'utilizzo dell'applicazione **G-Scanner** (di seguito, l’“App”).",
          ),
          p(
            "Prima di utilizzare l'App, l'Utente è tenuto a leggere attentamente i presenti **Termini e Condizioni d'Uso** (di seguito, i “Termini”).",
          ),
          p(
            "L'accesso, la registrazione, l'installazione o qualsiasi utilizzo dell'App costituiscono accettazione elettronica dei presenti Termini e determinano la conclusione di un accordo vincolante tra l'Utente e lo Sviluppatore, nei limiti consentiti dalla normativa applicabile.",
          ),
          p(
            "Qualora l'Utente non intenda accettare integralmente i presenti Termini, è tenuto ad astenersi dall'utilizzare l'App.",
          ),
          divider(),

          h1("1. Identità dello Sviluppatore e Natura del Progetto"),
          p("L'App **G-Scanner** è sviluppata e gestita da:"),
          p("**Emanuele Ciotola**"),
          p(
            "Contatto per assistenza, richieste o comunicazioni:\n**supporto-gscanner@googlegroups.com**",
          ),
          p("G-Scanner è un progetto software:"),
          bullet("**gratuito**;"),
          bullet("**amatoriale**;"),
          bullet("**non commerciale**;"),
          bullet(
            "sviluppato nell'ambito di un progetto personale da uno studente di informatica.",
          ),
          p(
            "L'App è realizzata con finalità informative, tecniche e sperimentali e non costituisce un servizio professionale, commerciale, medico, sanitario o nutrizionale.",
          ),
          p(
            "Lo Sviluppatore non opera come produttore alimentare, ente certificatore, consulente nutrizionale, medico o professionista sanitario.",
          ),
          divider(),

          h1("2. Requisiti di Età"),
          p(
            "L'utilizzo dell'App è consentito esclusivamente agli utenti che abbiano compiuto almeno **14 (quattordici) anni di età**.",
          ),
          p(
            "Utilizzando l'App, l'Utente dichiara e garantisce di possedere tale requisito anagrafico.",
          ),
          p(
            "Lo Sviluppatore non assume responsabilità per l'utilizzo dell'App da parte di soggetti che non soddisfino tale requisito.",
          ),
          p(
            "Qualora lo Sviluppatore venga a conoscenza della presenza di dati appartenenti a un minore di 14 anni, provvederà alla loro cancellazione nei limiti tecnicamente possibili e compatibilmente con eventuali obblighi di legge applicabili.",
          ),
          divider(),

          h1("3. Accettazione dei Termini e Accettazione Elettronica"),
          p("L'utilizzo dell'App, in qualsiasi sua forma, inclusa:"),
          bullet("la Web App;"),
          bullet("l'applicazione Android distribuita tramite file **.apk**;"),
          bullet(
            "eventuali versioni future rese disponibili dallo Sviluppatore;",
          ),
          p("costituisce accettazione integrale dei presenti Termini."),
          p(
            "L'accesso, la registrazione tramite sistemi di autenticazione disponibili o il semplice utilizzo delle funzionalità dell'App costituiscono una forma di **accettazione elettronica vincolante** dei presenti Termini ai sensi della normativa applicabile.",
          ),
          p(
            "L'Utente riconosce che tale accettazione elettronica produce effetti giuridici equivalenti all'accettazione delle condizioni contrattuali mediante strumenti tradizionali, nei limiti previsti dalla legge.",
          ),
          p(
            "Il mancato rispetto anche di una sola disposizione dei presenti Termini può comportare la sospensione, limitazione o cessazione dell'accesso ai servizi dell'App.",
          ),
          divider(),

          h1(
            "4. Natura del Servizio, Finalità Informative e Disclaimer Medico",
          ),
          h2("4.1 Assenza di finalità mediche"),
          p(
            "**G-Scanner non è un dispositivo medico, non costituisce uno strumento diagnostico e non fornisce consulenze mediche, nutrizionali o sanitarie.**",
          ),
          p(
            "L'App non effettua diagnosi, non certifica la sicurezza degli alimenti e non sostituisce il parere di medici, nutrizionisti o altri professionisti qualificati.",
          ),
          p(
            "Le informazioni mostrate dall'App hanno esclusivamente carattere:",
          ),
          bullet("informativo;"),
          bullet("orientativo;"),
          bullet("sperimentale."),
          p(
            "Gli esiti della scansione, inclusi ma non limitati agli indicatori:",
          ),
          bullet("**Semaforo Verde**;"),
          bullet("**Semaforo Giallo**;"),
          bullet("**Semaforo Rosso**;"),
          p(
            "sono generati mediante algoritmi automatici basati su dati disponibili da fonti interne e/o di terze parti.",
          ),
          p("Tali risultati non devono essere interpretati come:"),
          bullet("certificazioni alimentari;"),
          bullet("valutazioni mediche;"),
          bullet("garanzie assolute di sicurezza;"),
          bullet("indicazioni professionali personalizzate."),

          h2("4.2 Assenza di rapporto professionale"),
          p("L'utilizzo dell'App non crea alcun rapporto:"),
          bullet("medico;"),
          bullet("sanitario;"),
          bullet("nutrizionale;"),
          bullet("consulenziale;"),
          bullet("professionale;"),
          p("tra l'Utente e lo Sviluppatore."),
          p(
            "Le informazioni fornite dall'App non costituiscono consulenza professionale e non devono essere utilizzate come unica base per decisioni relative alla salute o all'alimentazione.",
          ),

          h2("4.3 Obbligo di verifica dell'Utente"),
          p("L'Utente riconosce e accetta che:"),
          bullet(
            "è esclusivamente responsabile delle proprie decisioni alimentari;",
          ),
          bullet(
            "deve leggere integralmente l'etichetta fisica del prodotto prima del consumo;",
          ),
          bullet(
            "deve verificare personalmente ingredienti, allergeni, avvertenze, valori nutrizionali e ogni altra informazione presente sulla confezione originale.",
          ),
          p(
            "L'App non sostituisce in alcun modo l'etichetta ufficiale del produttore.",
          ),

          h2("4.4 Preferenze alimentari e trattamento dei dati personali"),
          p(
            "L'Utente riconosce che alcune impostazioni dell'Applicazione relative a esigenze alimentari personali possono riguardare informazioni potenzialmente riconducibili a categorie particolari di dati personali ai sensi dell'art. 9 GDPR.",
          ),
          p(
            "L'attivazione e l'utilizzo delle funzionalità relative a tali preferenze avvengono esclusivamente secondo quanto indicato nella Privacy Policy dell'Applicazione.",
          ),
          p(
            "Utilizzando tali funzionalità, l'Utente dichiara di aver preso visione della relativa informativa privacy e di aver prestato, ove richiesto, il consenso previsto dalla normativa applicabile.",
          ),
          p(
            "L'Utente può modificare o disattivare tali preferenze in qualsiasi momento secondo le modalità disponibili nell'Applicazione, senza pregiudicare la liceità dei trattamenti effettuati prima della revoca del consenso.",
          ),

          h2("4.5 Clausola di Responsabilità e Manleva"),
          p(
            "Nei limiti massimi consentiti dalla normativa applicabile e fatti salvi i diritti inderogabili dell'Utente quale consumatore, l'Utente riconosce che:",
          ),
          bullet(
            "il consumo di qualsiasi prodotto alimentare costituisce una scelta personale;",
          ),
          bullet(
            "la decisione finale relativa all'acquisto e al consumo di un prodotto spetta esclusivamente all'Utente.",
          ),
          p("Lo Sviluppatore non potrà essere ritenuto responsabile per:"),
          bullet("reazioni allergiche;"),
          bullet("intolleranze;"),
          bullet("effetti indesiderati;"),
          bullet("conseguenze derivanti dal consumo di prodotti;"),
          bullet("errori di classificazione;"),
          bullet("dati incompleti;"),
          bullet("informazioni inesatte;"),
          bullet("errori algoritmici;"),
          bullet("interpretazioni personali dei risultati forniti dall'App."),
          p(
            "L'Utente si impegna a tenere indenne e manlevare lo Sviluppatore da pretese, contestazioni o richieste derivanti direttamente dall'uso improprio dell'App o da decisioni autonome assunte sulla base delle informazioni visualizzate, nei limiti massimi consentiti dalla normativa applicabile e fatti salvi i diritti inderogabili dell'Utente quale consumatore.",
          ),
          divider(),

          h1("5. Dati di Terze Parti (Open Food Facts)"),
          p(
            "L'App utilizza dati provenienti dal database collaborativo **Open Food Facts**.",
          ),
          p(
            "Tali dati sono forniti da utenti e collaboratori della comunità internazionale e sono distribuiti secondo la licenza **Open Database License (ODbL)**.",
          ),
          p("Lo Sviluppatore:"),
          bullet("non crea tali dati;"),
          bullet("non controlla direttamente il loro inserimento;"),
          bullet("non garantisce la loro accuratezza;"),
          bullet("non garantisce la loro completezza;"),
          bullet("non garantisce il loro aggiornamento;"),
          bullet("non garantisce l'assenza di errori o omissioni."),
          p(
            "L'Utente riconosce che eventuali inesattezze, omissioni o dati obsoleti presenti nel database di Open Food Facts non possono essere imputati allo Sviluppatore.",
          ),
          p(
            "L'Utente riconosce inoltre che **Open Food Facts opera come database collaborativo indipendente e che G-Scanner si limita a utilizzare tali informazioni senza certificarne o modificarne necessariamente il contenuto originale.**",
          ),
          p(
            "In particolare, G-Scanner non certifica la conformità normativa dei prodotti alimentari, la sicurezza degli stessi o la correttezza delle informazioni presenti nelle etichette dei produttori.",
          ),
          divider(),

          h1(
            "6. Distribuzione dell'Applicazione, Installazione APK e Servizi Esterni",
          ),
          p("L'App è resa disponibile:"),
          bullet("come Web App tramite GitHub Pages;"),
          bullet(
            "come applicazione Android distribuibile mediante file **.apk**.",
          ),
          p(
            "L'installazione manuale di file APK provenienti da fonti esterne agli store ufficiali (\"sideloading\") costituisce una scelta volontaria dell'Utente e avviene sotto la sua esclusiva responsabilità.",
          ),
          p("Lo Sviluppatore non assume responsabilità per:"),
          bullet("errori di installazione;"),
          bullet("incompatibilità hardware o software;"),
          bullet("modifiche effettuate dall'Utente;"),
          bullet("configurazioni non corrette del dispositivo;"),
          bullet(
            "problemi derivanti dall'abilitazione di installazioni da fonti sconosciute;",
          ),
          bullet("danni derivanti dall'ambiente del dispositivo utilizzato."),

          h2("6.1 Servizi infrastrutturali e provider esterni"),
          p(
            "Per il funzionamento dell'App possono essere utilizzati servizi forniti da soggetti terzi, inclusi, a titolo esemplificativo:",
          ),
          bullet("GitHub Pages;"),
          bullet("Firebase;"),
          bullet("servizi di hosting;"),
          bullet("servizi database;"),
          bullet("servizi cloud;"),
          bullet("API esterne."),
          p(
            "Lo Sviluppatore non controlla direttamente tali servizi e non è responsabile per:",
          ),
          bullet("malfunzionamenti;"),
          bullet("interruzioni temporanee;"),
          bullet("modifiche tecniche;"),
          bullet("sospensioni;"),
          bullet("cessazioni del servizio;"),
          bullet("modifiche delle API;"),
          bullet("perdita di disponibilità;"),
          p("imputabili ai rispettivi fornitori terzi."),
          p(
            "L'Utente riconosce che tali servizi sono soggetti ai termini, alle condizioni e alle politiche dei relativi provider.",
          ),
          divider(),

          h1("7. Account Utente, Social Login e Segnalazioni della Community"),
          h2("7.1 Creazione e gestione dell'account"),
          p(
            "Alcune funzionalità dell'App possono richiedere l'autenticazione dell'Utente tramite sistemi di accesso forniti da soggetti terzi (\"Social Login\"), inclusi, a titolo esemplificativo:",
          ),
          bullet("Google;"),
          bullet("Facebook;"),
          bullet(
            "eventuali altri provider di autenticazione eventualmente integrati in futuro.",
          ),
          p(
            "L'accesso tramite tali sistemi implica che alcune informazioni relative all'identità dell'account possano essere gestite tramite i rispettivi provider esterni, secondo i loro termini di servizio e le loro informative sulla privacy.",
          ),
          p(
            "L'Utente riconosce di essere esclusivamente responsabile della sicurezza del proprio account Google, Facebook o altro provider utilizzato per l'autenticazione.",
          ),
          p(
            "Lo Sviluppatore non gestisce, non conosce e non conserva le password o le credenziali di accesso degli account esterni utilizzati dall'Utente.",
          ),
          p(
            "Qualsiasi attività effettuata tramite tali account rimane sotto la responsabilità del relativo titolare dell'account, salvo quanto previsto dalla normativa applicabile.",
          ),
          p("Lo Sviluppatore non è responsabile per:"),
          bullet(
            "accessi abusivi derivanti dalla compromissione dell'account dell'Utente;",
          ),
          bullet("perdita delle credenziali presso provider esterni;"),
          bullet("violazioni della sicurezza del dispositivo dell'Utente;"),
          bullet(
            "malfunzionamenti, modifiche, sospensioni o cessazioni dei servizi di autenticazione forniti da Google, Facebook o altri provider terzi.",
          ),

          h2("7.2 Richiesta di cancellazione dell'account"),
          p(
            "L'Utente può richiedere la cancellazione del proprio account e dei dati associati attraverso:",
          ),
          bullet(
            "gli strumenti eventualmente disponibili direttamente nell'App;",
          ),
          bullet(
            "i canali ufficiali di supporto indicati nei presenti Termini.",
          ),
          p(
            "Lo Sviluppatore provvederà a gestire la richiesta nei limiti tecnicamente disponibili e nel rispetto degli eventuali obblighi legali applicabili.",
          ),
          p(
            "La cancellazione dell'account può comportare la perdita definitiva delle funzionalità associate allo stesso e dei contributi eventualmente collegati all'account.",
          ),

          h2("7.3 Segnalazioni degli Utenti"),
          p(
            "Gli utenti autenticati possono contribuire al miglioramento del servizio inviando segnalazioni relative ai prodotti presenti nel database di G-Scanner.",
          ),
          p("Le segnalazioni possono consistere esclusivamente in:"),
          bullet("testi;"),
          bullet("informazioni descrittive;"),
          bullet("dati;"),
          bullet("note relative ai prodotti."),
          p(
            "L'App non consente il caricamento di fotografie o immagini tramite tali segnalazioni, salvo eventuali modifiche future comunicate dallo Sviluppatore.",
          ),
          p("L'Utente si impegna a inviare esclusivamente informazioni:"),
          bullet("veritiere;"),
          bullet("pertinenti;"),
          bullet("formulate in buona fede."),
          p("È espressamente vietato:"),
          bullet("inviare segnalazioni false;"),
          bullet("inserire informazioni deliberatamente errate;"),
          bullet("inviare contenuti ingannevoli;"),
          bullet("effettuare attività di spam;"),
          bullet("compromettere la qualità del database;"),
          bullet("utilizzare linguaggio offensivo o illecito;"),
          bullet("arrecare danno all'App o alla community."),

          h2("7.4 Licenza sui contenuti inviati dagli Utenti"),
          p(
            "Con l'invio di segnalazioni tramite l'App, l'Utente concede allo Sviluppatore una licenza gratuita, non esclusiva, valida per la durata necessaria alla gestione, manutenzione e miglioramento dell'Applicazione e del database di G-Scanner, e utilizzabile nei limiti consentiti dalla legge, sui contenuti testuali e informativi forniti.",
          ),
          p(
            "Tale licenza è limitata alle finalità sopra indicate e non potrà essere utilizzata per scopi diversi.",
          ),
          p("A tale scopo, lo Sviluppatore potrà:"),
          bullet("archiviare tali contenuti;"),
          bullet("analizzarli;"),
          bullet("modificarli ove necessario per finalità tecniche;"),
          bullet("integrarli nel database dell'Applicazione;"),
          bullet("utilizzarli per migliorare il funzionamento del servizio."),
          p("La presente licenza non comporta:"),
          bullet("trasferimento della proprietà dei contenuti;"),
          bullet("rinuncia ai diritti eventualmente spettanti all'Utente;"),
          bullet(
            "autorizzazione a utilizzare tali contenuti per finalità estranee alla gestione e al miglioramento di G-Scanner.",
          ),

          h2("7.5 Diritto di sospensione e rimozione account"),
          p("Lo Sviluppatore si riserva il diritto esclusivo di:"),
          bullet("sospendere temporaneamente un account;"),
          bullet("limitare determinate funzionalità;"),
          bullet("eliminare un account;"),
          bullet("rimuovere segnalazioni;"),
          bullet("impedire ulteriori contributi;"),
          p(
            "qualora ritenga, secondo valutazione ragionevole e discrezionale, che il comportamento dell'Utente sia:",
          ),
          bullet("contrario ai presenti Termini;"),
          bullet("fraudolento;"),
          bullet("dannoso per la community;"),
          bullet("dannoso per il funzionamento tecnico dell'App;"),
          bullet("idoneo a compromettere la qualità del database."),
          p(
            "Tale decisione potrà essere adottata anche senza preavviso nei casi in cui ciò sia necessario per proteggere sicurezza, integrità o corretto funzionamento del servizio.",
          ),
          divider(),

          h1("8. Proprietà Intellettuale dell'Applicazione"),
          p(
            "Tutti i diritti di proprietà intellettuale relativi a G-Scanner, inclusi, a titolo esemplificativo:",
          ),
          bullet("codice sorgente;"),
          bullet("codice compilato;"),
          bullet("algoritmi;"),
          bullet("strutture dati;"),
          bullet("interfaccia grafica;"),
          bullet("elementi visivi;"),
          bullet("logiche applicative;"),
          bullet("architettura software;"),
          bullet("denominazione dell'App;"),
          p(
            "appartengono esclusivamente a **Emanuele Ciotola**, salvo eventuali componenti appartenenti a terze parti secondo le rispettive licenze.",
          ),
          p(
            "Il fatto che il codice sorgente dell'App sia pubblicamente consultabile tramite GitHub ha esclusivamente finalità di:",
          ),
          bullet("trasparenza;"),
          bullet("verifica tecnica;"),
          bullet("studio del funzionamento."),
          p("La pubblicazione del codice non costituisce:"),
          bullet("concessione di licenza Open Source;"),
          bullet("autorizzazione al riutilizzo libero;"),
          bullet("rinuncia ai diritti di proprietà intellettuale;"),
          bullet("trasferimento di diritti a terzi."),
          divider(),

          h1("9. Licenza del Codice e Limitazioni d'Uso"),
          p(
            "Il codice dell'App è distribuito secondo un modello **Source-Available** con licenza proprietaria **\"All Rights Reserved\"**.",
          ),
          p(
            "La possibilità di consultare il codice sorgente non attribuisce all'Utente alcun diritto di:",
          ),
          bullet("utilizzare liberamente il software;"),
          bullet("modificarlo;"),
          bullet("distribuirlo;"),
          bullet("creare opere derivate;"),
          bullet("commercializzarlo."),
          p(
            "Salvo preventiva autorizzazione scritta dello Sviluppatore, è vietato:",
          ),
          bullet("copiare integralmente o parzialmente il codice;"),
          bullet("clonare il progetto;"),
          bullet("riprodurre l'algoritmo;"),
          bullet("replicare la logica di funzionamento;"),
          bullet("riprodurre la UI;"),
          bullet("creare versioni derivate;"),
          bullet("distribuire copie dell'App;"),
          bullet("utilizzare componenti del codice per altri progetti;"),
          bullet("sfruttare commercialmente il software."),
          p("È inoltre vietato effettuare:"),
          bullet("reverse engineering;"),
          bullet("decompilazione;"),
          bullet("disassemblaggio;"),
          bullet(
            "analisi del codice finalizzata alla ricostruzione delle logiche interne;",
          ),
          bullet("scraping degli algoritmi;"),
          bullet("estrazione automatizzata di componenti software;"),
          bullet("ricostruzione del funzionamento interno dell'Applicazione."),
          p(
            "Qualsiasi utilizzo non autorizzato potrà comportare l'esercizio dei rimedi previsti dalla normativa applicabile, inclusa la richiesta di risarcimento dei danni eventualmente subiti.",
          ),
          p(
            "Le presenti limitazioni si applicano nei limiti massimi consentiti dalla normativa applicabile e non intendono limitare eventuali diritti inderogabili riconosciuti dalla legge, inclusi quelli relativi all'interoperabilità del software ove applicabili.",
          ),
          divider(),

          h1("10. Licenza Limitata di Utilizzo dell'Applicazione"),
          p("Lo Sviluppatore concede all'Utente una licenza:"),
          bullet("personale;"),
          bullet("limitata;"),
          bullet("non esclusiva;"),
          bullet("revocabile;"),
          bullet("non trasferibile;"),
          p(
            "per utilizzare G-Scanner esclusivamente per finalità personali e lecite.",
          ),
          p("La licenza consente esclusivamente:"),
          bullet("l'accesso alle funzionalità disponibili;"),
          bullet("l'utilizzo dell'App secondo i presenti Termini;"),
          bullet("la consultazione delle informazioni fornite."),
          p("La presente licenza non comporta alcun trasferimento di:"),
          bullet("proprietà dell'App;"),
          bullet("diritti sul codice;"),
          bullet("diritti sugli algoritmi;"),
          bullet("diritti sulla UI;"),
          bullet("diritti di sfruttamento economico."),
          p(
            "Ogni diritto non espressamente concesso rimane riservato allo Sviluppatore.",
          ),
          divider(),

          h1("11. Disponibilità, Aggiornamenti ed Evoluzione del Software"),
          p(
            "L'Utente riconosce che G-Scanner è un software in continua evoluzione.",
          ),
          p(
            "Lo Sviluppatore può modificare, aggiornare, migliorare, sospendere o interrompere funzionalità dell'App in qualsiasi momento, anche senza preavviso, quando ciò sia necessario per motivi tecnici, organizzativi, di sicurezza o sviluppo.",
          ),
          p("A titolo esemplificativo, lo Sviluppatore può:"),
          bullet("modificare algoritmi;"),
          bullet("aggiornare componenti;"),
          bullet("cambiare modalità di funzionamento;"),
          bullet("introdurre nuove funzioni;"),
          bullet("rimuovere funzioni esistenti;"),
          bullet("sospendere temporaneamente il servizio."),
          p("Lo Sviluppatore non garantisce:"),
          bullet("disponibilità continua;"),
          bullet("assenza assoluta di errori;"),
          bullet("compatibilità permanente con ogni dispositivo;"),
          bullet("mantenimento indefinito di tutte le funzionalità."),
          p(
            "Tali modifiche non attribuiscono automaticamente all'Utente diritto a compensazioni, rimborsi o risarcimenti, nei limiti massimi consentiti dalla normativa applicabile e fatti salvi i diritti inderogabili dell'Utente quale consumatore.",
          ),
          divider(),

          h1(
            "12. Uso Corretto dell'Applicazione, Sicurezza e Divieto di Abuso Tecnico",
          ),
          p(
            "L'Utente si impegna a utilizzare G-Scanner in modo corretto, conforme alla legge, ai presenti Termini e ai principi di buona fede.",
          ),
          p(
            "L'Utente è tenuto a non utilizzare l'App in modo tale da compromettere:",
          ),
          bullet("la sicurezza del servizio;"),
          bullet("la disponibilità dell'Applicazione;"),
          bullet("l'integrità dei sistemi informatici;"),
          bullet("l'esperienza degli altri utenti;"),
          bullet("la qualità dei dati gestiti."),
          p(
            "È espressamente vietato, salvo preventiva autorizzazione scritta dello Sviluppatore:",
          ),
          bullet(
            "effettuare attività di scraping automatizzato dei dati, delle interfacce o delle funzionalità dell'App;",
          ),
          bullet(
            "utilizzare bot, crawler o strumenti automatici per accedere al servizio;",
          ),
          bullet(
            "inviare un numero eccessivo o irragionevole di richieste verso sistemi o API;",
          ),
          bullet(
            "tentare di sovraccaricare server, database o infrastrutture utilizzate dall'App;",
          ),
          bullet(
            "aggirare sistemi di sicurezza, autenticazione o limitazioni tecniche;",
          ),
          bullet(
            "tentare di ottenere accessi non autorizzati a dati o componenti riservati;",
          ),
          bullet("interferire con il normale funzionamento dell'Applicazione;"),
          bullet(
            "introdurre codice dannoso, malware o componenti potenzialmente dannosi;",
          ),
          bullet(
            "effettuare reverse engineering, decompilazione o attività finalizzate alla ricostruzione del funzionamento interno dell'App.",
          ),
          p(
            "Qualsiasi comportamento idoneo a compromettere sicurezza, stabilità o disponibilità del servizio potrà comportare la sospensione o cessazione dell'accesso dell'Utente, oltre all'eventuale esercizio dei rimedi previsti dalla normativa applicabile.",
          ),
          divider(),

          h1("13. Comunicazioni Elettroniche"),
          p(
            "L'Utente accetta di ricevere comunicazioni elettroniche strettamente necessarie alla gestione del rapporto con lo Sviluppatore e al corretto funzionamento dell'App.",
          ),
          p("Tali comunicazioni possono riguardare:"),
          bullet("aggiornamenti tecnici;"),
          bullet("informazioni relative alla sicurezza;"),
          bullet("modifiche ai presenti Termini;"),
          bullet("modifiche rilevanti alle funzionalità dell'App;"),
          bullet("comunicazioni amministrative relative all'account;"),
          bullet("informazioni necessarie alla gestione del servizio."),
          p(
            "Tali comunicazioni hanno esclusivamente finalità tecniche, amministrative o di servizio e non costituiscono automaticamente comunicazioni commerciali o promozionali.",
          ),
          p(
            "Eventuali comunicazioni promozionali saranno soggette agli eventuali consensi richiesti dalla normativa applicabile.",
          ),
          divider(),

          h1("14. Servizi Esterni, Infrastrutture di Terze Parti e Provider"),
          p(
            "Per il funzionamento dell'App possono essere utilizzati servizi forniti da soggetti terzi, inclusi, a titolo esemplificativo:",
          ),
          bullet("servizi di autenticazione;"),
          bullet("servizi cloud;"),
          bullet("database esterni;"),
          bullet("servizi di hosting;"),
          bullet("GitHub Pages;"),
          bullet("Firebase;"),
          bullet("API e infrastrutture tecnologiche di terze parti."),
          p(
            "L'Utente riconosce che tali servizi sono gestiti autonomamente dai rispettivi fornitori e soggetti ai relativi termini contrattuali, condizioni d'uso e informative sulla privacy.",
          ),
          p(
            "Nei limiti massimi consentiti dalla normativa applicabile e fatti salvi i diritti inderogabili dell'Utente quale consumatore, lo Sviluppatore non è responsabile per:",
          ),
          bullet("interruzioni temporanee dei servizi esterni;"),
          bullet("malfunzionamenti dei provider;"),
          bullet("modifiche tecniche effettuate da soggetti terzi;"),
          bullet("sospensione o cessazione di API;"),
          bullet("variazioni delle condizioni dei servizi esterni;"),
          bullet(
            "perdita di disponibilità di infrastrutture non controllate direttamente dallo Sviluppatore.",
          ),
          divider(),

          h1("15. Limitazione Generale di Responsabilità"),
          p(
            "Nei limiti massimi consentiti dalla normativa applicabile e fatti salvi i diritti inderogabili dell'Utente quale consumatore, G-Scanner viene fornita:\n**\"così com'è\" (\"AS IS\")**\ne\n**\"come disponibile\" (\"AS AVAILABLE\")**.",
          ),
          p("Lo Sviluppatore non garantisce che:"),
          bullet("l'App sia disponibile senza interruzioni;"),
          bullet("il servizio sia privo di errori;"),
          bullet("tutte le funzionalità siano sempre operative;"),
          bullet("i dati utilizzati siano sempre completi o aggiornati;"),
          bullet("i risultati prodotti siano sempre privi di inesattezze;"),
          bullet(
            "l'App sia compatibile con ogni dispositivo o configurazione tecnica.",
          ),
          p(
            "Lo Sviluppatore non potrà essere ritenuto responsabile per danni derivanti dall'utilizzo dell'App, salvo nei casi in cui tale responsabilità non possa essere esclusa o limitata ai sensi della normativa applicabile.",
          ),
          p("In particolare, nulla nei presenti Termini limita o esclude:"),
          bullet(
            "i diritti inderogabili riconosciuti ai consumatori dalla normativa italiana ed europea;",
          ),
          bullet(
            "la responsabilità derivante da condotte dolose o gravemente colpose nei casi previsti dalla legge;",
          ),
          bullet(
            "qualsiasi altra responsabilità che non possa essere legalmente esclusa.",
          ),
          divider(),

          h1("16. Privacy Policy e Cookie Policy"),
          p(
            "Il trattamento dei dati personali degli Utenti è disciplinato da una specifica **Privacy Policy**, documento separato e indipendente rispetto ai presenti Termini.",
          ),
          p("La Privacy Policy disciplina, tra gli altri aspetti:"),
          bullet("quali dati personali vengono raccolti;"),
          bullet("le finalità del trattamento;"),
          bullet(
            "le modalità di utilizzo dei dati e le architetture cloud coinvolte;",
          ),
          bullet("gli eventuali servizi terzi coinvolti;"),
          bullet(
            "i diritti riconosciuti agli interessati ai sensi della normativa applicabile.",
          ),
          p(
            "All'interno della medesima Privacy Policy sono inoltre fornite tutte le informazioni relative all'utilizzo di cookie tecnici e tecnologie di archiviazione locale (es. *SharedPreferences* o *LocalStorage*), utilizzati dall'App esclusivamente per necessità tecniche e di funzionamento, senza alcun tracciamento a fini pubblicitari.",
          ),
          p("I presenti Termini e Condizioni d'Uso:"),
          bullet("non sostituiscono la Privacy Policy;"),
          bullet("non costituiscono un'informativa privacy;"),
          bullet(
            "non disciplinano integralmente il trattamento dei dati personali.",
          ),
          p(
            "L'Utente è invitato a consultare tali documenti prima dell'utilizzo dell'App.",
          ),
          divider(),

          h1("17. Modifiche ai Termini"),
          p(
            "Lo Sviluppatore si riserva il diritto di modificare, integrare o aggiornare i presenti Termini in qualsiasi momento.",
          ),
          p(
            "Le modifiche possono rendersi necessarie, a titolo esemplificativo, per:",
          ),
          bullet("evoluzione tecnica dell'App;"),
          bullet("modifiche normative;"),
          bullet("introduzione di nuove funzionalità;"),
          bullet("esigenze di sicurezza;"),
          bullet("aggiornamenti organizzativi."),
          p(
            "La versione aggiornata dei Termini sarà identificata mediante indicazione della relativa versione e della data di ultimo aggiornamento.",
          ),
          p(
            "Le modifiche avranno efficacia dalla loro pubblicazione attraverso i canali ufficiali dell'App.",
          ),
          p(
            "L'utilizzo continuato dell'Applicazione successivamente alla pubblicazione delle modifiche costituisce accettazione della nuova versione dei Termini.",
          ),
          p(
            "Qualora l'Utente non intenda accettare le modifiche, dovrà interrompere l'utilizzo dell'App e potrà richiedere la cancellazione del proprio account secondo le modalità previste.",
          ),
          divider(),

          h1("18. Lingua dei Termini e delle Informative"),
          p(
            "I presenti Termini e Condizioni d'Uso, nonché la Privacy Policy e gli eventuali ulteriori documenti legali relativi all'Applicazione, sono redatti originariamente in **lingua italiana**. Eventuali traduzioni in altre lingue sono fornite esclusivamente a fini di cortesia e per agevolare la comprensione da parte degli Utenti. In caso di discrepanze, incongruenze, ambiguità o conflitti interpretativi tra la versione in lingua italiana e qualsiasi versione tradotta, prevarrà la versione in lingua italiana, nei limiti massimi consentiti dalla normativa applicabile.",
          ),
          divider(),

          h1("19. Disposizioni Finali"),
          p(
            "Qualora una qualsiasi disposizione dei presenti Termini venga dichiarata nulla, invalida o inefficace da un'autorità competente, tale circostanza non comprometterà la validità delle restanti disposizioni.",
          ),
          p(
            "Le disposizioni rimanenti continueranno a produrre pieno effetto nella misura massima consentita dalla normativa applicabile.",
          ),
          p(
            "L'eventuale mancato esercizio da parte dello Sviluppatore di un diritto previsto dai presenti Termini non costituisce rinuncia definitiva allo stesso.",
          ),
          p(
            "I presenti Termini costituiscono l'accordo completo tra l'Utente e lo Sviluppatore relativamente all'utilizzo dell'App, limitatamente agli aspetti disciplinati nel presente documento.",
          ),
          divider(),

          h1("20. Legge Applicabile e Foro Competente"),
          p(
            "I presenti Termini sono disciplinati dalla **legge italiana**, fatto salvo quanto previsto dalle norme imperative applicabili dell'Unione Europea e dalla normativa italiana a tutela dei consumatori.",
          ),
          p(
            "Per gli Utenti qualificabili come consumatori ai sensi della normativa applicabile, restano applicabili le norme inderogabili relative alla competenza territoriale e alla tutela del consumatore.",
          ),
          p(
            "Per gli Utenti che non rivestano tale qualifica, eventuali controversie derivanti dall'interpretazione, esecuzione o validità dei presenti Termini saranno disciplinate secondo la legge italiana e sottoposte al foro competente secondo le disposizioni applicabili.",
          ),
          divider(),

          h1("Contatti"),
          p("**Applicazione:** G-Scanner"),
          p("**Sviluppatore:** Emanuele Ciotola"),
          p("**Email di supporto:**\n**supporto-gscanner@googlegroups.com**"),

          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}

Widget _buildNativePrivacyPolicy(Color textColor) {
  // Helper per creare le parti in grassetto automaticamente e velocemente
  Widget pContent(String text) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: i % 2 == 1 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
        children: spans,
      ),
    );
  }

  Widget h1(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
  );

  Widget h2(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
  );

  Widget p(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: pContent(text),
  );

  Widget bullet(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "• ",
          style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
        ),
        Expanded(child: pContent(text)),
      ],
    ),
  );

  Widget divider() => const Divider(height: 32);

  return SingleChildScrollView(
    child: SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          h2("Privacy Policy di G-Scanner"),
          p(
            "**Versione:** 1.0\n**Data di entrata in vigore:** 17 luglio 2026\n**Data di ultimo aggiornamento:** 17 luglio 2026",
          ),
          divider(),

          p(
            "La presente Privacy Policy descrive le modalità di trattamento dei dati personali effettuato attraverso l'applicazione mobile e web **G-Scanner**, sviluppata nel rispetto del **Regolamento (UE) 2016/679 (GDPR)** e della normativa italiana applicabile in materia di protezione dei dati personali.",
          ),
          divider(),

          h1("Finalità dell'applicazione"),
          p(
            "G-Scanner è un'applicazione che consente agli utenti di consultare informazioni relative ai prodotti alimentari mediante la scansione dei codici a barre, con particolare attenzione alle esigenze delle persone affette da celiachia o intolleranza al lattosio.",
          ),
          p(
            "L'applicazione permette inoltre agli utenti di configurare specifiche preferenze alimentari, ricevere indicazioni basate su filtri informativi preimpostati e partecipare a una community attraverso la condivisione di segnalazioni relative ai prodotti.",
          ),
          p("**Importante – Limitazione di responsabilità**"),
          p(
            "Le informazioni fornite da G-Scanner hanno esclusivamente finalità informative e di supporto all'utente.",
          ),
          p(
            "L'applicazione **non costituisce un dispositivo medico**, **non fornisce consulenze mediche**, **non ha valore diagnostico o terapeutico** e **non produce effetti o valutazioni aventi valore legale**.",
          ),
          p("Le informazioni visualizzate non sostituiscono in alcun modo:"),
          bullet(
            "il parere di un medico o di altro professionista sanitario qualificato;",
          ),
          bullet(
            "la consultazione delle etichette ufficiali dei prodotti alimentari;",
          ),
          bullet("le informazioni fornite direttamente dal produttore."),
          p(
            "Le valutazioni generate dall'applicazione si basano esclusivamente sui dati disponibili nel database e sulle impostazioni configurate dall'utente e potrebbero non riflettere variazioni nella composizione dei prodotti, aggiornamenti delle ricette da parte dei produttori o informazioni non disponibili.",
          ),
          p(
            "L'utente è sempre tenuto a verificare autonomamente la composizione e l'etichettatura dei prodotti prima del consumo.",
          ),
          divider(),

          h1("1. Titolare del Trattamento"),
          p("Il Titolare del Trattamento dei dati personali è:"),
          p("**Emanuele Ciotola**"),
          p("E-mail:\n**supporto-gscanner@googlegroups.com**"),
          p(
            "Per qualsiasi richiesta relativa al trattamento dei dati personali o all'esercizio dei diritti previsti dal GDPR è possibile contattare il Titolare al suddetto indirizzo.",
          ),
          divider(),

          h1("2. Tipologie di dati trattati"),
          p(
            "L'applicazione tratta esclusivamente i dati necessari al proprio funzionamento e all'erogazione delle funzionalità offerte.",
          ),

          h2("2.1 Utenti anonimi"),
          p(
            "Quando G-Scanner viene utilizzata senza effettuare l'accesso, i dati personali dell'utente e le preferenze configurate rimangono esclusivamente sul dispositivo e vengono memorizzati localmente tramite **SharedPreferences**.",
          ),
          p("Tra questi rientrano:"),
          bullet("cronologia delle scansioni;"),
          bullet("impostazioni dell'applicazione;"),
          bullet(
            "preferenze relative alle funzionalità alimentari e sanitarie selezionate dall'utente.",
          ),
          p(
            "Tali dati personali **non vengono trasmessi ai server del Titolare**.",
          ),
          p(
            "Resta tuttavia inteso che le **segnalazioni relative ai prodotti**, qualora inviate tramite l'applicazione, vengono memorizzate nel database cloud dell'applicazione e rese disponibili agli altri utenti della community al fine di migliorare il servizio.",
          ),
          p(
            "Le segnalazioni pubblicate nella community possono contenere esclusivamente:",
          ),
          bullet("informazioni relative all'alimento o prodotto segnalato;"),
          bullet("eventuali note inserite dall'utente;"),
          bullet("il motivo della segnalazione."),
          p(
            "L'identità dell'utente che effettua la segnalazione, inclusi **nome, cognome, indirizzo e-mail o altri dati identificativi**, **non viene mai resa pubblica né associata visibilmente alla segnalazione in nessuna circostanza**.",
          ),
          p(
            "Anche le segnalazioni effettuate da altri utenti possono essere consultate dagli utilizzatori dell'applicazione, indipendentemente dall'autenticazione.",
          ),
          divider(),

          h2("2.2 Utenti autenticati"),
          p(
            "L'utente può autenticarsi mediante **Firebase Authentication** utilizzando un account:",
          ),
          bullet("Google;"),
          bullet("Facebook."),
          p(
            "A seguito dell'autenticazione vengono acquisiti dal provider i dati necessari all'identificazione dell'utente, che possono comprendere:",
          ),
          bullet("nome;"),
          bullet("cognome;"),
          bullet("indirizzo e-mail;"),
          bullet(
            "numero di telefono, ove disponibile o associato al profilo utilizzato per l'autenticazione.",
          ),
          p(
            "A tali informazioni viene associato un identificativo univoco dell'utente (**User ID**).",
          ),
          p(
            "G-Scanner non accede alle credenziali di autenticazione dell'utente, quali password o strumenti equivalenti, e non tratta tali informazioni.",
          ),
          divider(),

          h2("2.3 Dati memorizzati nel database cloud"),
          p(
            "Per gli utenti autenticati vengono memorizzati su **Firebase Firestore**, associati all'identificativo dell'utente:",
          ),
          bullet("cronologia delle scansioni;"),
          bullet("elenco delle segnalazioni inviate;"),
          bullet("impostazioni relative alle preferenze alimentari:"),
          bullet("Avvertimento Additivi;"),
          bullet("Filtro Rigido Contaminazioni;"),
          bullet("Intolleranza al Lattosio;"),
          bullet(
            "eventuali impostazioni relative agli avvisi sulle contaminazioni;",
          ),
          bullet("lingua selezionata;"),
          bullet("tema grafico scelto."),
          p(
            "I dati identificativi ottenuti mediante l'autenticazione (nome, cognome, indirizzo e-mail ed eventuale numero di telefono, ove disponibile) sono utilizzati esclusivamente per:",
          ),
          bullet("consentire la gestione dell'account;"),
          bullet(
            "associare correttamente i dati dell'utente al relativo profilo;",
          ),
          bullet("fornire le funzionalità riservate agli utenti autenticati."),
          divider(),

          h2("2.4 Cookie e Tecnologie di Archiviazione Locale"),
          p(
            "G-Scanner (sia nella versione Web App che come applicazione Mobile) non utilizza cookie di profilazione, strumenti di tracciamento pubblicitario o sistemi di analytics di terze parti.",
          ),
          p(
            "L'applicazione utilizza esclusivamente tecnologie di archiviazione locale strettamente necessarie (come *SharedPreferences* su dispositivi mobili e *LocalStorage / Cookie tecnici* su browser) al solo fine di:",
          ),
          bullet(
            "Mantenere la sessione utente attiva in modo sicuro tramite Firebase Authentication;",
          ),
          bullet(
            "Memorizzare localmente le preferenze dell'utente (es. lingua, tema grafico) e la conferma di accettazione dei documenti legali.",
          ),
          p(
            "Poiché si tratta esclusivamente di strumenti tecnici indispensabili per l'erogazione del servizio richiesto dall'utente, ai sensi della normativa europea (Direttiva ePrivacy) e dei provvedimenti del Garante Privacy italiano, non è richiesto il preventivo consenso dell'utente per il loro utilizzo. L'utente viene informato della loro presenza tramite la presente Privacy Policy, senza necessità di banner o documenti separati.",
          ),
          p(
            "I dati memorizzati localmente rimangono sul dispositivo dell'utente fino alla loro eliminazione o alla disinstallazione dell'applicazione.",
          ),
          divider(),

          h1("3. Dati appartenenti a categorie particolari (Art. 9 GDPR)"),
          p(
            "G-Scanner consente all'utente di configurare specifiche preferenze personali finalizzate alla consultazione delle informazioni sui prodotti alimentari. Tali impostazioni possono riflettere lo stato di salute o particolari esigenze alimentari dell'utente e, pertanto, possono costituire **categorie particolari di dati personali**, ai sensi dell'**art. 9 del Regolamento (UE) 2016/679 (GDPR)**.",
          ),
          p("Le impostazioni disponibili nell'applicazione sono le seguenti:"),
          bullet(
            "**Avvertimento Additivi**: genera un avviso in presenza di ingredienti quali amidi modificati o aromi la cui origine non sia specificata, affinché l'utente possa effettuare ulteriori verifiche.",
          ),
          bullet(
            "**Filtro Rigido Contaminazioni**: considera come **\"Vietato\"** qualsiasi alimento la cui etichetta riporti diciture quali **\"può contenere tracce di glutine\"** o formulazioni equivalenti relative alla possibile contaminazione da glutine.",
          ),
          bullet(
            "**Intolleranza al Lattosio**: verifica la presenza di ingredienti quali lattosio, burro, latte in polvere o siero del latte, segnalandone l'eventuale presenza secondo le funzionalità dell'applicazione.",
          ),
          p(
            "Al **primo avvio dell'applicazione** risultano abilitate per impostazione predefinita esclusivamente le seguenti opzioni:",
          ),
          bullet("Avvertimento Additivi;"),
          bullet("Filtro Rigido Contaminazioni."),
          p(
            "L'opzione **Intolleranza al Lattosio** è inizialmente disabilitata e può essere attivata dall'utente in qualsiasi momento.",
          ),
          p(
            "Il trattamento di tali informazioni avviene **esclusivamente previo consenso esplicito dell'utente**, ai sensi dell'**art. 9, paragrafo 2, lettera a) del GDPR**.",
          ),
          p(
            "L'utente è libero di modificare, attivare o disattivare in qualsiasi momento le suddette impostazioni secondo le proprie esigenze personali.",
          ),
          p(
            "Tali scelte sono effettuate sotto la responsabilità dell'utente, il quale riconosce che G-Scanner costituisce esclusivamente uno **strumento di supporto informativo** e non sostituisce:",
          ),
          bullet("la verifica delle etichette dei prodotti;"),
          bullet("le informazioni fornite dal produttore;"),
          bullet(
            "il parere di un medico o di altro professionista sanitario qualificato.",
          ),
          p(
            "L'eventuale modifica delle impostazioni e l'utilizzo delle informazioni fornite dall'applicazione avvengono pertanto **a esclusivo rischio dell'utente**.",
          ),
          p(
            "L'utente può in ogni momento modificare le proprie preferenze o revocare il consenso precedentemente prestato, senza pregiudicare la liceità del trattamento effettuato prima della revoca.",
          ),
          divider(),

          h1("4. Finalità del trattamento"),
          p(
            "I dati personali raccolti attraverso G-Scanner sono trattati per le seguenti finalità:",
          ),
          bullet(
            "consentire la scansione dei codici a barre e la consultazione delle informazioni relative ai prodotti alimentari;",
          ),
          bullet(
            "permettere la personalizzazione dell'esperienza dell'utente tramite la configurazione delle preferenze alimentari e delle impostazioni dell'applicazione;",
          ),
          bullet(
            "consentire agli utenti autenticati la sincronizzazione dei dati tra dispositivi diversi;",
          ),
          bullet(
            "permettere la partecipazione alla community attraverso l'invio, la gestione e la consultazione delle segnalazioni relative ai prodotti;",
          ),
          bullet(
            "gestire l'autenticazione tramite provider esterni quali Google e Facebook;",
          ),
          bullet(
            "garantire il corretto funzionamento tecnico dell'applicazione, la sicurezza dei servizi e la protezione dei dati trattati.",
          ),
          divider(),

          h1("5. Base giuridica del trattamento"),
          p("Il trattamento dei dati personali si fonda su:"),
          bullet(
            "consenso esplicito dell'interessato per il trattamento delle **categorie particolari di dati personali** relative alla salute (art. 9, par. 2, lett. a GDPR);",
          ),
          bullet(
            "esecuzione del servizio richiesto dall'utente e delle funzionalità offerte dall'applicazione;",
          ),
          bullet(
            "adempimento degli obblighi previsti dalla normativa vigente;",
          ),
          bullet(
            "interesse legittimo del Titolare relativamente alla sicurezza tecnica dell'applicazione e alla prevenzione di utilizzi impropri del servizio, ove applicabile.",
          ),
          divider(),

          h1("6. Minori"),
          p("L'utilizzo di G-Scanner è vietato ai minori di **14 anni**."),
          p(
            "In conformità alla normativa italiana sul consenso digitale, l'applicazione non è destinata a utenti di età inferiore ai 14 anni e non raccoglie consapevolmente dati personali riferibili a tali soggetti.",
          ),
          p(
            "Qualora il Titolare venga a conoscenza della presenza di dati appartenenti a un minore di 14 anni, provvederà alla loro tempestiva cancellazione.",
          ),
          divider(),

          h1("7. Permessi richiesti dall'applicazione"),
          p(
            "Per garantire il corretto funzionamento delle funzionalità offerte, G-Scanner può richiedere alcuni permessi del dispositivo dell'utente.",
          ),

          h2("Fotocamera"),
          p(
            "La fotocamera viene utilizzata esclusivamente per consentire la scansione dei codici a barre dei prodotti.",
          ),
          p(
            "Le immagini acquisite tramite fotocamera non vengono salvate, trasmesse o utilizzate per finalità diverse dalla scansione del codice a barre.",
          ),
          divider(),

          h2("Connessione Internet"),
          p("La connessione Internet è necessaria per:"),
          bullet("effettuare l'autenticazione tramite i provider supportati;"),
          bullet("sincronizzare i dati degli utenti autenticati;"),
          bullet("accedere ai servizi cloud utilizzati dall'applicazione;"),
          bullet(
            "consentire il funzionamento delle funzionalità basate sui dati della community.",
          ),
          divider(),

          h2("Tema di sistema"),
          p(
            "Il permesso relativo al tema di sistema viene utilizzato esclusivamente per adattare automaticamente l'interfaccia grafica dell'applicazione alla modalità chiara o scura configurata sul dispositivo dell'utente.",
          ),
          divider(),

          h2("Posizione geografica approssimativa di sistema"),
          p(
            "L'applicazione utilizza esclusivamente la posizione geografica approssimativa fornita dal sistema operativo **soltanto al primo avvio dell'applicazione**, esclusivamente allo scopo di determinare automaticamente la lingua dell'interfaccia.",
          ),
          p("Tale informazione:"),
          bullet("viene elaborata esclusivamente sul dispositivo;"),
          bullet("non comporta l'accesso alla posizione GPS precisa;"),
          bullet("non viene salvata;"),
          bullet("non viene trasmessa ai server;"),
          bullet(
            "non viene utilizzata per attività di profilazione o tracciamento.",
          ),
          divider(),

          h1(
            "8. Assenza di pubblicità, tracciamento e raccolta dati analitici",
          ),
          p(
            "G-Scanner adotta una politica di tutela della riservatezza degli utenti.",
          ),
          p("L'applicazione:"),
          bullet("è completamente gratuita;"),
          bullet("non contiene pubblicità;"),
          bullet("non utilizza strumenti di analytics;"),
          bullet("non utilizza Google Analytics;"),
          bullet("non utilizza Firebase Crashlytics;"),
          bullet("non effettua profilazione degli utenti;"),
          bullet("non svolge attività di tracciamento degli utenti;"),
          bullet("non vende dati personali;"),
          bullet(
            "non comunica né cede dati personali a terzi per finalità commerciali.",
          ),
          p(
            "In particolare, **G-Scanner non raccoglie identificativi pubblicitari, informazioni di utilizzo dell'applicazione, dati diagnostici o dati tecnici del dispositivo per finalità analitiche o di profilazione**.",
          ),
          p(
            "L'applicazione non effettua processi di monitoraggio comportamentale dell'utente né crea profili commerciali o pubblicitari.",
          ),
          divider(),

          h1("9. Conservazione dei dati"),
          h2("9.1 Utenti anonimi"),
          p(
            "Quando l'utente utilizza G-Scanner senza autenticazione, i dati personali e le preferenze configurate rimangono esclusivamente memorizzati localmente sul dispositivo tramite **SharedPreferences**.",
          ),
          p("Tali dati vengono conservati fino a quando:"),
          bullet(
            "l'utente li elimina tramite le funzionalità disponibili nell'applicazione;",
          ),
          bullet("l'applicazione viene disinstallata;"),
          bullet(
            "il dispositivo viene ripristinato o i dati locali vengono cancellati.",
          ),
          p(
            "Le segnalazioni relative ai prodotti inviate alla community costituiscono un trattamento distinto e vengono invece conservate nel database cloud dell'applicazione per consentirne la consultazione da parte degli altri utenti.",
          ),
          divider(),

          h2("9.2 Utenti autenticati"),
          p(
            "Per gli utenti autenticati i dati vengono conservati mediante una modalità di **doppia memorizzazione**:",
          ),
          bullet(
            "localmente sul dispositivo dell'utente, per consentire un utilizzo rapido dell'applicazione;",
          ),
          bullet(
            "nel database cloud Firebase Firestore, per consentire la sincronizzazione delle informazioni tra dispositivi diversi e il mantenimento delle funzionalità associate all'account.",
          ),
          p(
            "I dati associati all'account rimangono conservati fino alla loro eliminazione secondo le modalità descritte nel successivo articolo relativo alla cancellazione dei dati.",
          ),
          divider(),

          h1(
            "10. Diritto alla cancellazione e gestione dell'account (Art. 17 GDPR)",
          ),
          p(
            "L'utente dispone di due modalità distinte per la gestione della cancellazione dei propri dati.",
          ),

          h2(
            "10.1 Eliminazione dell'account tramite funzione interna dell'applicazione",
          ),
          p(
            "Qualora l'utente utilizzi l'apposita funzione interna di eliminazione dell'account disponibile in G-Scanner, viene effettuata la cancellazione del relativo **profilo di autenticazione Firebase Authentication**.",
          ),
          p("Tale operazione comporta:"),
          bullet(
            "la rimozione definitiva dell'associazione tra l'account e i dati identificativi utilizzati per l'autenticazione;",
          ),
          bullet(
            "la cancellazione dei riferimenti relativi a email, nome, cognome ed eventuali dati del provider associati al profilo.",
          ),
          p(
            "Tuttavia, l'eliminazione del profilo di autenticazione **non comporta automaticamente la distruzione fisica immediata dei documenti presenti su Firebase Firestore**.",
          ),
          p("I dati eventualmente presenti nel database cloud, quali:"),
          bullet("cronologia delle scansioni;"),
          bullet("impostazioni dell'applicazione;"),
          bullet("dati associati all'identificativo utente;"),
          p(
            "non risultano più collegabili all'identità dell'utente e diventano tecnicamente inaccessibili tramite il normale utilizzo dell'applicazione.",
          ),
          p(
            "Il collegamento tra tali dati e l'identità dell'utente viene eliminato definitivamente.",
          ),
          divider(),

          h2(
            "10.2 Cancellazione completa e definitiva dei dati (Wipe dei dati)",
          ),
          p(
            "Qualora l'utente desideri la cancellazione fisica completa e definitiva di tutti i record associati al proprio identificativo presente nei sistemi cloud, deve inoltrare una richiesta esplicita al Titolare tramite:",
          ),
          p("**supporto-gscanner@googlegroups.com**"),
          p(
            "La richiesta deve essere effettuata **prima di procedere all'eliminazione del profilo tramite l'applicazione**, utilizzando lo stesso indirizzo e-mail associato all'account utilizzato per l'accesso.",
          ),
          p(
            "Questa procedura è necessaria affinché il Titolare possa verificare l'identità del richiedente e individuare correttamente i record associati all'account.",
          ),
          p(
            "Qualora l'utente elimini preventivamente il proprio profilo dall'applicazione senza aver inviato la richiesta di cancellazione completa, potrebbe non essere più possibile verificare l'identità del richiedente e individuare i dati precedentemente associati all'account eliminato.",
          ),
          p(
            "A seguito della verifica dell'identità, il Titolare procederà alla cancellazione definitiva dei dati presenti nei sistemi cloud associati all'identificativo dell'utente, nei limiti tecnicamente disponibili e previsti dalla normativa applicabile.",
          ),
          divider(),

          h1("11. Diritti dell'interessato"),
          p(
            "Ai sensi degli articoli 15 e seguenti del GDPR, l'interessato può esercitare il diritto di:",
          ),
          bullet("ottenere conferma dell'esistenza dei propri dati personali;"),
          bullet("accedere ai dati personali trattati;"),
          bullet("richiedere la rettifica dei dati inesatti;"),
          bullet(
            "richiedere la cancellazione dei dati nei casi previsti dalla normativa;",
          ),
          bullet("ottenere la limitazione del trattamento;"),
          bullet("opporsi al trattamento nei casi consentiti;"),
          bullet(
            "revocare il consenso precedentemente prestato, senza pregiudicare la liceità del trattamento effettuato prima della revoca;",
          ),
          bullet(
            "ricevere i propri dati in formato strutturato, ove applicabile;",
          ),
          bullet(
            "proporre reclamo all'Autorità Garante per la Protezione dei Dati Personali.",
          ),
          p(
            "Per l'esercizio dei propri diritti è possibile contattare il Titolare:",
          ),
          p("**supporto-gscanner@googlegroups.com**"),
          divider(),

          h1("12. Sicurezza dei dati"),
          p(
            "I dati personali sono trattati mediante strumenti informatici e misure tecniche e organizzative adeguate a garantirne:",
          ),
          bullet("riservatezza;"),
          bullet("integrità;"),
          bullet("disponibilità;"),
          bullet("protezione contro accessi non autorizzati."),
          p(
            "In particolare, per i dati conservati tramite infrastruttura Firebase, l'accesso ai dati in cloud è limitato esclusivamente ai soggetti autorizzati ed è protetto mediante le misure tecniche e di sicurezza messe a disposizione dall'infrastruttura Firebase.",
          ),
          p(
            "Il Titolare adotta misure proporzionate alla natura dei dati trattati, tenendo conto dei rischi connessi al trattamento, in conformità all'art. 32 GDPR.",
          ),
          divider(),

          h1("13. Modifiche alla presente Privacy Policy"),
          p(
            "Il Titolare si riserva il diritto di modificare o aggiornare la presente Privacy Policy per adeguarla a:",
          ),
          bullet("modifiche normative;"),
          bullet("evoluzioni tecniche dell'applicazione;"),
          bullet(
            "variazioni delle modalità di trattamento dei dati personali.",
          ),
          p(
            "La versione aggiornata sarà resa disponibile all'interno dell'applicazione e/o attraverso gli eventuali canali ufficiali di G-Scanner, con indicazione della data di ultimo aggiornamento.",
          ),
          divider(),

          h1("14. Fornitori di Servizi e Trasferimento dei Dati"),
          p(
            "Per l'erogazione delle funzionalità offerte da G-Scanner, il Titolare si avvale di fornitori di servizi tecnologici che trattano dati personali esclusivamente nei limiti necessari all'esecuzione dei servizi richiesti.",
          ),
          divider(),

          h2("14.1 Infrastruttura Cloud (Google Firebase)"),
          p(
            "Per le funzionalità di autenticazione e archiviazione dei dati, G-Scanner utilizza la piattaforma **Google Firebase**, fornita da **Google Ireland Limited**, con sede in Gordon House, Barrow Street, Dublin 4, Irlanda.",
          ),
          p("In particolare, l'applicazione utilizza:"),
          bullet(
            "**Firebase Authentication**, per la gestione dell'autenticazione degli utenti;",
          ),
          bullet(
            "**Cloud Firestore**, per la memorizzazione e sincronizzazione dei dati degli utenti autenticati.",
          ),
          p(
            "Per i trattamenti effettuati per conto del Titolare nell'ambito dei servizi Firebase utilizzati dall'applicazione, **Google Ireland Limited opera quale Responsabile del Trattamento ai sensi dell'art. 28 GDPR**.",
          ),
          p(
            "Restano ferme le eventuali attività di trattamento per le quali Google agisce quale autonomo titolare secondo quanto previsto dalla documentazione privacy del servizio Firebase.",
          ),
          divider(),

          h2("14.2 Localizzazione dei dati e trasferimenti verso Paesi terzi"),
          p(
            "Il database **Cloud Firestore** utilizzato da G-Scanner è configurato nella regione:",
          ),
          p("**eur3 – Francoforte (Germania)**"),
          p(
            "corrispondente a infrastrutture localizzate all'interno dell'Unione Europea.",
          ),
          p(
            "Il Titolare adotta tale configurazione con l'obiettivo di favorire la conservazione dei dati personali all'interno dello Spazio Economico Europeo (SEE).",
          ),
          p(
            "Qualora Google dovesse effettuare trasferimenti tecnici di dati personali verso Paesi situati al di fuori dello Spazio Economico Europeo, tali trasferimenti saranno effettuati nel rispetto degli articoli 44 e seguenti del GDPR e garantiti mediante strumenti legalmente riconosciuti, tra cui:",
          ),
          bullet("il **Data Privacy Framework UE-USA**, ove applicabile;"),
          bullet(
            "le **Clausole Contrattuali Tipo (Standard Contractual Clauses – SCC)** approvate dalla Commissione Europea.",
          ),
          divider(),

          h2(
            "14.3 Servizi di autenticazione tramite provider esterni (Social Login)",
          ),
          p("L'utente può scegliere di autenticarsi tramite:"),
          bullet("Google;"),
          bullet("Facebook."),
          p("Durante la procedura di autenticazione:"),
          bullet("**Google Ireland Limited**;"),
          bullet("**Meta Platforms Ireland Limited**"),
          p(
            "agiscono in qualità di **Titolari Autonomi del Trattamento**, limitatamente alle attività necessarie alla verifica delle credenziali, alla gestione dell'identità digitale e all'erogazione del servizio di autenticazione.",
          ),
          p(
            "G-Scanner riceve esclusivamente i dati necessari alla creazione e gestione dell'account, che possono comprendere:",
          ),
          bullet("nome;"),
          bullet("cognome;"),
          bullet("indirizzo e-mail;"),
          bullet("eventuale numero di telefono disponibile."),
          p(
            "Per ogni ulteriore trattamento effettuato direttamente dai provider esterni si rinvia alle rispettive informative privacy ufficiali:",
          ),
          bullet("Google Privacy Policy;"),
          bullet("Meta Privacy Policy."),
          p(
            "Il Titolare non è responsabile dei trattamenti effettuati autonomamente da tali provider per finalità proprie.",
          ),
          divider(),

          h1("15. Assenza di decisioni automatizzate (Art. 22 GDPR)"),
          p(
            "G-Scanner utilizza filtri e criteri informativi configurati dall'applicazione per fornire indicazioni relative ai prodotti alimentari.",
          ),
          p(
            "Le classificazioni generate dall'applicazione, quali ad esempio **\"Vietato\"**, **\"Consentito\"**, **\"Attenzione\"** o indicazioni equivalenti, costituiscono esclusivamente informazioni di supporto basate sui dati disponibili e sulle impostazioni selezionate dall'utente.",
          ),
          p(
            "**L'applicazione non effettua processi decisionali automatizzati aventi effetti giuridici o analogamente significativi sull'utente ai sensi dell'art. 22 GDPR.**",
          ),
          divider(),

          h1("16. Lingua delle Informative e dei Termini"),
          p(
            "La presente Privacy Policy, nonché i Termini e Condizioni d'Uso e gli eventuali ulteriori documenti legali relativi all'Applicazione, sono redatti originariamente in **lingua italiana**. Eventuali traduzioni in altre lingue sono fornite esclusivamente a fini di cortesia e per agevolare la comprensione da parte dell'Utente. In caso di discrepanze, incongruenze o difformità interpretative tra la versione in lingua italiana e qualsiasi versione tradotta, prevarrà la versione in lingua italiana, nei limiti massimi consentiti dalla normativa applicabile.",
          ),
          divider(),

          h1("Contatti del Titolare del Trattamento"),
          p("**Emanuele Ciotola**"),
          p("**Email:**\n**supporto-gscanner@googlegroups.com**"),

          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}
