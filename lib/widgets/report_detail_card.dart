// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.\nPROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/types.dart';
import '../theme/app_theme.dart';
import 'responsive_wrapper.dart';
import 'product_detail_card.dart';

class ReportDetailCard extends StatefulWidget {
  final Product product;
  final VoidCallback onBack;

  // AGGIUNTO: Lo stato originale del prodotto prima della segnalazione
  final GlutenSafetyStatus originalStatus;

  // Dati fittizi per la segnalazione (Sostituisci con il tuo modello Report reale)
  final String reportReasonKey;
  final String reportComment;
  final String reportDate;
  final int initialUpvotes;
  final int score;

  final Future<void> Function(int voteDirection)? onVote;
  final Future<Map<String, int>> Function()? onInitVote;
  final UserSettings? userSettings;
  final bool isOwnReport;
  final String? reportId;
  final Future<void> Function(String reportId)? onDeleteReport;
  final bool useResponsiveWrapper;
  final bool showProductLink;

  const ReportDetailCard({
    super.key,
    required this.product,
    required this.onBack,
    required this.originalStatus,
    required this.reportReasonKey,
    required this.reportComment,
    required this.reportDate,
    this.initialUpvotes = 12,
    this.onVote,
    this.score = 0,
    this.onInitVote,
    this.userSettings,
    this.isOwnReport = false,
    this.reportId,
    this.onDeleteReport,
    this.useResponsiveWrapper = true,
    this.showProductLink = true,
  });

  @override
  State<ReportDetailCard> createState() => _ReportDetailCardState();
}

class _ReportDetailCardState extends State<ReportDetailCard> {
  // Stato del voto: 0 = nessun voto, 1 = upvote, -1 = downvote
  int _currentVote = 0;
  late int _displayScore;
  bool _isVoteLoading = true;

  ProductReport? _activeReport;

  @override
  void initState() {
    super.initState();
    _displayScore = widget.score;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('reports')
            .where('barcode', isEqualTo: widget.product.barcode)
            .where('status', isEqualTo: 'open')
            .limit(1)
            .get(),
        widget.onInitVote != null
            ? widget.onInitVote!()
            : Future.value(<String, int>{}),
      ]);

      final querySnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final voteData = results[1] as Map<String, int>;

      if (mounted) {
        setState(() {
          if (querySnapshot.docs.isNotEmpty) {
            _activeReport = ProductReport.fromJson(
              querySnapshot.docs.first.data(),
            );
          }
          if (voteData.isNotEmpty) {
            _displayScore = voteData['score'] ?? widget.score;
            _currentVote = voteData['userVote'] ?? 0;
          }
          _isVoteLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Errore nel caricamento del report da Firestore: $e");
      if (mounted) {
        setState(() {
          _isVoteLoading = false;
        });
      }
    }
  }

  void _handleVote(int vote) {
    setState(() {
      if (_currentVote == vote) {
        // Rimuove il voto (se riclicca)
        if (vote == 1) _displayScore--;
        if (vote == -1) {
          _displayScore++; // Se toglie il downvote, il punteggio sale
        }
        _currentVote = 0;
      } else {
        // Applica il nuovo voto
        if (vote == 1) {
          _displayScore += (_currentVote == -1)
              ? 2
              : 1; // Se passa da Giù a Su, sale di 2
        } else if (vote == -1) {
          _displayScore -= (_currentVote == 1)
              ? 2
              : 1; // Se passa da Su a Giù, scende di 2
        }
        _currentVote = vote;
      }
    });

    if (widget.onVote != null) {
      widget.onVote!(_currentVote); // Invia il -1, 0 o 1 al padre
    }
  }

  String _translateReason(String key) {
    switch (key) {
      case "label_unclear":
        return "Etichetta poco chiara o ambigua";
      case "outdated":
        return "Informazione obsoleta / Ricetta cambiata";
      case "incorrect_status":
        return "Stato glutine errato";
      case "other":
        return "Altro";
      default:
        return "Segnalazione generica";
    }
  }

  // Helper per ottenere colori/icone in base allo stato
  Map<String, dynamic> _getStatusData(GlutenSafetyStatus status, ColorScheme colorScheme) {
    switch (status) {
      case GlutenSafetyStatus.adatto:
        return {"text": "SICURO", "color": colorScheme.primary, "icon": Icons.check_circle};
      case GlutenSafetyStatus.nonAdatto:
        return {"text": "VIETATO", "color": colorScheme.error, "icon": Icons.cancel};
      case GlutenSafetyStatus.incerto:
        return {"text": "INCERTO", "color": colorScheme.tertiary, "icon": Icons.warning};
      default:
        return {
          "text": "SCONOSCIUTO",
          "color": colorScheme.outlineVariant,
          "icon": Icons.help,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    // Ora usa l'originalStatus passato via parametro e non il current status (che sarebbe in revisione/giallo)
    final oldStatusData = _getStatusData(widget.originalStatus, colorScheme);

    return widget.useResponsiveWrapper
        ? ResponsiveMaxCardWidth(child: _buildContent(context, oldStatusData))
        : _buildContent(context, oldStatusData);
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> oldStatusData,
  ) {
    final colorScheme = context.colorScheme;
    final cardBg = context.cardBackground;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
          onPressed: widget.onBack,
        ),
        title: Text(
          "Revisione Segnalazione",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.isOwnReport && widget.onDeleteReport != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              color: cardBg,
              onSelected: (value) {
                if (value == 'delete_report') {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      final ctxColorScheme = ctx.colorScheme;
                      final ctxCardBg = ctx.cardBackground;
                      return AlertDialog(
                        backgroundColor: ctxCardBg,
                        title: const Text("Eliminare segnalazione?"),
                        content: const Text(
                          "Sei sicuro di voler eliminare questa segnalazione?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              foregroundColor: ctxColorScheme.onSurfaceVariant,
                            ),
                            child: const Text("Annulla"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final targetId =
                                  widget.reportId ?? _activeReport?.id;
                              if (targetId != null) {
                                await widget.onDeleteReport!(targetId);
                              }
                              if (mounted) widget.onBack();
                            },
                            style: TextButton.styleFrom(foregroundColor: ctxColorScheme.error),
                            child: const Text("Elimina"),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete_report',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        "Elimina segnalazione",
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Section ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning,
                      color: colorScheme.tertiary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.brand,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pillola Barcode
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code, size: 16, color: colorScheme.tertiary),
                        const SizedBox(width: 8),
                        SelectableText(
                          widget.product.barcode,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // DATA AGGIUNTA DA RICHIESTA
                  Builder(
                    builder: (context) {
                      final String effectiveReportDate =
                          (_activeReport?.submittedAt != null &&
                                  _activeReport!.submittedAt.isNotEmpty)
                              ? formatRelativeDate(_activeReport!.submittedAt)
                              : widget.reportDate;

                      if (effectiveReportDate.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "Segnalato il: $effectiveReportDate",
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                        );
                      }

                      if (_isVoteLoading) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Skeletonizer(
                            enabled: true,
                            child: Text(
                              "Segnalato il: 00/00/0000",
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── BOTTONE NEUTRO: Scheda Prodotto (anti-loop) ────────────
            if (widget.showProductLink)
              InkWell(
                onTap: () {
                  final productToShow = widget.product;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailCard(
                        product: productToShow,
                        onBack: () => Navigator.pop(context),
                        // Sola lettura: la segnalazione è già stata inviata,
                        // questi callback non verranno mai chiamati da qui.
                        onReportSubmit: (_, _) async {},
                        onProductUpdate: (_) async {},
                        userSettings:
                            widget.userSettings ??
                            UserSettings(
                              strictMode: true,
                              alertLactose: false,
                              warnAdditives: true,
                              autoSaveHistory: true,
                              preferredLanguage: 'it',
                            ),
                        showReportLink: false,
                        showScanDate: false,
                        useResponsiveWrapper: widget.useResponsiveWrapper,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.onSurface.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icona neutra a sinistra
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Testo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mostra scheda prodotto",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Ingredienti, allergeni e note.",
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Freccia a destra per indicare la navigazione
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 24,
                        color: colorScheme.outlineVariant,
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.showProductLink) const SizedBox(height: 24),

            // ── Vecchio Stato del Prodotto ────────────────────────────
            _buildSectionCard(
              colorScheme: colorScheme,
              cardBg: cardBg,
              title: "STATO PRECEDENTE",
              icon: Icons.history,
              child: Row(
                children: [
                  Icon(
                    oldStatusData["icon"],
                    color: oldStatusData["color"],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        oldStatusData["text"],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: oldStatusData["color"],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Risultato registrato da Open Food Facts",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Dettagli Segnalazione Utente (NUOVO DESIGN) ───────────
            _buildSectionCard(
              colorScheme: colorScheme,
              cardBg: cardBg,
              title: "DETTAGLI SEGNALAZIONE",
              icon: Icons.chat_bubble_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informazioni compatte: Motivo
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface,
                              height: 1.3,
                            ),
                            children: [
                              TextSpan(
                                text: "Motivo: ",
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                              TextSpan(
                                text: _translateReason(
                                  _activeReport?.type ?? widget.reportReasonKey,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Commento dell'utente stile "Blockquote"
                  Text(
                    "Commento dell'utente",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.outlineVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                          width: 4,
                        ),
                      ),
                    ),
                    child: Skeletonizer(
                      enabled: _isVoteLoading,
                      child: Text(
                        _isVoteLoading
                            ? "Questo è un commento segnaposto utilizzato per visualizzare lo scheletro di caricamento."
                            : (_activeReport?.comments ?? "").isEmpty
                            ? "Nessun commento aggiuntivo fornito."
                            : '"${_activeReport!.comments}"',
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle:
                              _isVoteLoading ||
                                  (_activeReport?.comments ?? "").isEmpty
                              ? FontStyle.normal
                              : FontStyle.italic,
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Sistema di Voto (YouTube Style) ───────────────────────
            if (_isVoteLoading)
              Skeletonizer(
                enabled: true,
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        "Sei d'accordo con questa segnalazione?",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.thumb_up_outlined,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "0",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Container(
                              width: 1,
                              height: 24,
                              color: colorScheme.outlineVariant,
                            ),
                            const SizedBox(width: 20),
                            Icon(
                              Icons.thumb_down_outlined,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Text(
                      "Sei d'accordo con questa segnalazione?",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(999),
                                bottomLeft: Radius.circular(999),
                              ),
                              onTap: () => _handleVote(1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _currentVote == 1
                                          ? Icons.thumb_up
                                          : Icons.thumb_up_outlined,
                                      size: 20,
                                      color: _currentVote == 1
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _displayScore < 0
                                          ? "0"
                                          : "$_displayScore",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _currentVote == 1
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: _currentVote == 1
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(999),
                                bottomRight: Radius.circular(999),
                              ),
                              onTap: () => _handleVote(-1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: Icon(
                                  _currentVote == -1
                                      ? Icons.thumb_down
                                      : Icons.thumb_down_outlined,
                                  size: 20,
                                  color: _currentVote == -1
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required ColorScheme colorScheme,
    required Color cardBg,
    required String title,
    IconData? icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
