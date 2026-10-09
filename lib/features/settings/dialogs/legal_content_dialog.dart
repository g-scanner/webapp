// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';
import '../legal/legal_texts.dart';

/// Mostra la bottom sheet per la visualizzazione dei documenti legali (ToS, Privacy Policy).
void showLegalBottomSheet(
  BuildContext context, {
  required String title,
  required String documentType,
}) {
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
            // Titolo
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
            const SizedBox(height: 24),
            // Contenuto scrollabile con documento Markdown ad alte prestazioni
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: SafeArea(
                  top: false,
                  child: LegalMarkdownViewer(documentType: documentType),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Widget che visualizza un documento Markdown legale.
/// Accesso sincrono e memoizzazione dei widget per garantire 120fps costanti
/// e ZERO tempi di caricamento durante l'apertura e lo scorrimento del bottom sheet.
class LegalMarkdownViewer extends StatefulWidget {
  final String documentType;
  final bool scrollable;

  const LegalMarkdownViewer({
    super.key,
    required this.documentType,
    this.scrollable = true,
  });

  @override
  State<LegalMarkdownViewer> createState() => _LegalMarkdownViewerState();
}

class _LegalMarkdownViewerState extends State<LegalMarkdownViewer> {
  List<Widget>? _cachedWidgets;
  Brightness? _cachedBrightness;
  String? _cachedLang;

  @override
  Widget build(BuildContext context) {
    final currentBrightness = Theme.of(context).brightness;
    final currentLang = context.locale.languageCode.toLowerCase();

    // Ricalcola i widget solo se cambia la lingua o il tema (chiaro/scuro),
    // MAI durante il drag o movimento del bottom sheet!
    if (_cachedWidgets == null ||
        _cachedBrightness != currentBrightness ||
        _cachedLang != currentLang) {
      final markdown = LegalTexts.get(widget.documentType, currentLang);
      if (markdown.trim().isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Documento non disponibile.",
              style: TextStyle(
                color: context.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        );
      }
      _cachedWidgets = _parseMarkdown(markdown, context);
      _cachedBrightness = currentBrightness;
      _cachedLang = currentLang;
    }

    final body = SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _cachedWidgets!,
      ),
    );

    if (widget.scrollable) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: body,
      );
    }

    return body;
  }

  List<Widget> _parseMarkdown(String markdown, BuildContext context) {
    final lines = markdown.split(RegExp(r'\r?\n'));
    final widgets = <Widget>[];
    final colorScheme = context.colorScheme;

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        i++;
        continue;
      }

      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            line.substring(2).trim(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ));
        i++;
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(
            line.substring(3).trim(),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
        ));
        i++;
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(
            line.substring(4).trim(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ));
        i++;
      } else if (line == '---' || line == '***') {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ));
        i++;
      } else if (line.startsWith('* ') || line.startsWith('- ')) {
        final bulletText = line.substring(2).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "• ",
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              Expanded(
                child: _buildRichText(bulletText, colorScheme),
              ),
            ],
          ),
        ));
        i++;
      } else {
        // Raccoglie righe consecutive dello stesso paragrafo
        final paragraphLines = <String>[line];
        i++;
        while (i < lines.length) {
          final nextLine = lines[i].trim();
          if (nextLine.isEmpty ||
              nextLine.startsWith('#') ||
              nextLine == '---' ||
              nextLine == '***' ||
              nextLine.startsWith('* ') ||
              nextLine.startsWith('- ')) {
            break;
          }
          paragraphLines.add(nextLine);
          i++;
        }

        final fullText = paragraphLines.join('\n');
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRichText(fullText, colorScheme),
        ));
      }
    }

    return widgets;
  }

  Widget _buildRichText(String text, ColorScheme colorScheme) {
    if (!text.contains('**') && !text.contains('](')) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
          height: 1.55,
        ),
      );
    }

    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*([^*]+)\*\*|\[([^\]]+)\]\(([^)]+)\))');
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
        ));
      }

      if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ));
      } else if (match.group(3) != null && match.group(4) != null) {
        final linkLabel = match.group(3)!;
        final linkUrl = match.group(4)!;
        spans.add(TextSpan(
          text: linkLabel,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.tryParse(linkUrl);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
          height: 1.55,
        ),
        children: spans,
      ),
    );
  }
}
