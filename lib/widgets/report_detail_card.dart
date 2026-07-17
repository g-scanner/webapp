import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/types.dart';
import 'responsive_wrapper.dart';

// --- Colori estratti dal tuo Tailwind Config ---
const Color bgBackground = Color(0xFFFAF9FC);
const Color surfaceLowest = Color(0xFFFFFFFF);
const Color onSurface = Color(0xFF1B1B1E);
const Color onSurfaceVariant = Color(0xFF40493D);
const Color surfaceContainer = Color(0xFFEFEDF1);
const Color surfaceContainerHigh = Color(0xFFE9E7EB);
const Color surfaceContainerLow = Color(0xFFF5F3F7);
const Color outlineVariant = Color(0xFFBFCABA);

const Color primary = Color(0xFF0D631B);
const Color error = Color(0xFFBA1A1A);
const Color warningText = Color(0xFF884200);

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

  const ReportDetailCard({
    super.key,
    required this.product,
    required this.onBack,
    required this.originalStatus, // Passalo dal DB quando chiami questa pagina
    required this.reportReasonKey,
    required this.reportComment,
    required this.reportDate,
    this.initialUpvotes = 12,
    this.onVote,
    this.score = 0,
    this.onInitVote,
  });

  @override
  State<ReportDetailCard> createState() => _ReportDetailCardState();
}

class _ReportDetailCardState extends State<ReportDetailCard> {
  // Stato del voto: 0 = nessun voto, 1 = upvote, -1 = downvote
  int _currentVote = 0;
  late int _displayScore;
  bool _isVoteLoading = true;

  @override
  void initState() {
    super.initState();
    _displayScore = widget.score;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.onInitVote != null) {
      final data = await widget.onInitVote!();
      if (mounted) {
        setState(() {
          _displayScore = data['score'] ?? widget.score;
          _currentVote = data['userVote'] ?? 0;
          _isVoteLoading = false;
        });
      }
    } else {
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
  Map<String, dynamic> _getStatusData(GlutenSafetyStatus status) {
    switch (status) {
      case GlutenSafetyStatus.adatto:
        return {"text": "SICURO", "color": primary, "icon": Icons.check_circle};
      case GlutenSafetyStatus.nonAdatto:
        return {"text": "VIETATO", "color": error, "icon": Icons.cancel};
      case GlutenSafetyStatus.incerto:
        return {"text": "INCERTO", "color": warningText, "icon": Icons.warning};
      default:
        return {
          "text": "SCONOSCIUTO",
          "color": outlineVariant,
          "icon": Icons.help,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ora usa l'originalStatus passato via parametro e non il current status (che sarebbe in revisione/giallo)
    final oldStatusData = _getStatusData(widget.originalStatus);

    return ResponsiveMaxCardWidth(
      child: Scaffold(
        backgroundColor: bgBackground,
        appBar: AppBar(
          backgroundColor: surfaceLowest,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: onSurface),
            onPressed: widget.onBack,
          ),
          title: const Text(
            "Revisione Segnalazione",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: onSurface,
            ),
          ),
          centerTitle: true,
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
                  color: Color(0xFFFFDCC6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFF884200).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Color(0xFF884200),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.product.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.brand,
                      style: const TextStyle(
                        fontSize: 16,
                        color: onSurfaceVariant,
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
                        color: Color(0xFF884200).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 16,
                            color: Color(0xFF884200),
                          ),
                          const SizedBox(width: 8),
                          SelectableText(
                            widget.product.barcode,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF884200),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // DATA AGGIUNTA DA RICHIESTA
                    const SizedBox(height: 4),
                    Text(
                      "Segnalato il: ${widget.reportDate}",
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Vecchio Stato del Prodotto ────────────────────────────
              _buildSectionCard(
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
                            color: onSurfaceVariant.withValues(alpha: 0.7),
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
                title: "DETTAGLI SEGNALAZIONE",
                icon: Icons.chat_bubble_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informazioni compatte: Motivo e Data
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: onSurface,
                                height: 1.3,
                              ),
                              children: [
                                const TextSpan(
                                  text: "Motivo: ",
                                  style: TextStyle(color: onSurfaceVariant),
                                ),
                                TextSpan(
                                  text: _translateReason(
                                    widget.reportReasonKey,
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
                    Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: onSurface,
                            ),
                            children: [
                              const TextSpan(
                                text: "Data invio: ",
                                style: TextStyle(color: onSurfaceVariant),
                              ),
                              TextSpan(
                                text: widget.reportDate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Commento dell'utente stile "Blockquote"
                    const Text(
                      "Commento dell'utente",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: outlineVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        left: 14,
                        top: 2,
                        bottom: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: outlineVariant.withValues(alpha: 0.6),
                            width: 4,
                          ),
                        ),
                      ),
                      child: Text(
                        widget.reportComment.isEmpty
                            ? "Nessun commento aggiuntivo fornito."
                            : '"${widget.reportComment}"',
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: widget.reportComment.isEmpty
                              ? FontStyle.normal
                              : FontStyle.italic,
                          color: Colors.red,
                          height: 1.4,
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
                        const Text(
                          "Sei d'accordo con questa segnalazione?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.thumb_up_outlined, size: 20, color: onSurfaceVariant),
                              const SizedBox(width: 8),
                              const Text("0", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
                              const SizedBox(width: 20),
                              Container(width: 1, height: 24, color: outlineVariant),
                              const SizedBox(width: 20),
                              const Icon(Icons.thumb_down_outlined, size: 20, color: onSurfaceVariant),
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
                      const Text(
                        "Sei d'accordo con questa segnalazione?",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceContainerHigh,
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
                                            ? onSurface
                                            : onSurfaceVariant,
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
                                              ? onSurface
                                              : onSurfaceVariant,
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
                              color: outlineVariant.withValues(alpha: 0.5),
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
                                        ? onSurface
                                        : onSurfaceVariant,
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
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    IconData? icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: onSurface.withValues(alpha: 0.02),
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
                Icon(icon, size: 18, color: onSurfaceVariant),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: onSurfaceVariant,
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
