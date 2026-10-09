// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — Widget Tests: Legal Content Dialog & Markdown Viewer

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gscanner/features/settings/dialogs/legal_content_dialog.dart';
import 'package:gscanner/features/settings/legal/legal_texts.dart';
import '../mocks/shared_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('LegalTexts Unit Tests', () {
    test('provides non-empty ToS for all supported languages', () {
      for (final lang in ['it', 'en', 'es', 'de', 'fr']) {
        final doc = LegalTexts.getTos(lang);
        expect(doc, isNotEmpty, reason: 'ToS missing for $lang');
      }
    });

    test('provides non-empty Privacy Policy for all supported languages', () {
      for (final lang in ['it', 'en', 'es', 'de', 'fr']) {
        final doc = LegalTexts.getPrivacyPolicy(lang);
        expect(doc, isNotEmpty, reason: 'PP missing for $lang');
      }
    });

    test('fallbacks to Italian on unknown language', () {
      expect(LegalTexts.getTos('xx'), equals(LegalTexts.getTos('it')));
      expect(LegalTexts.getPrivacyPolicy('xx'), equals(LegalTexts.getPrivacyPolicy('it')));
    });

    test('get() handles doc types correctly', () {
      expect(LegalTexts.get('tos', 'it'), equals(LegalTexts.getTos('it')));
      expect(LegalTexts.get('pp', 'it'), equals(LegalTexts.getPrivacyPolicy('it')));
      expect(LegalTexts.get('unknown', 'it'), isEmpty);
    });
  });

  group('LegalMarkdownViewer Widget Tests', () {
    testWidgets('renders tos document instantly on first frame', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: LegalMarkdownViewer(documentType: 'tos'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LegalMarkdownViewer), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders pp document instantly on first frame', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: LegalMarkdownViewer(documentType: 'pp'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LegalMarkdownViewer), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders fallback when unknown document requested', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: LegalMarkdownViewer(documentType: 'unknown_doc'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Documento non disponibile.'), findsOneWidget);
    });

    testWidgets('showLegalBottomSheet displays title and sheet', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showLegalBottomSheet(
                    context,
                    title: 'Termini e Condizioni',
                    documentType: 'tos',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Termini e Condizioni'), findsOneWidget);
      expect(find.byType(LegalMarkdownViewer), findsOneWidget);
    });
  });
}
