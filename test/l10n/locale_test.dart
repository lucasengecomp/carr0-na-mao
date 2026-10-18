// Testes de localização — issue #34 (chore(i18n): flutter_localizations pt-BR)
//
// Valida:
//  1. pt-BR como locale padrão: strings em português aparecem na UI.
//  2. Troca de locale para 'en': mesma chave ARB aparece em inglês.
//  3. Cobertura das chaves do AppLocalizations (pt e en sem divergência de
//     quantidade).

import 'package:carro_na_mao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper: monta um MaterialApp mínimo com uma tela que exibe um texto
// obtido via AppLocalizations.
// ---------------------------------------------------------------------------
Widget _app({
  required Locale locale,
  required String Function(AppLocalizations) getText,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('pt', 'BR'), Locale('pt'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(body: Text(getText(l10n)));
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Helper: monta um MaterialApp mínimo para inspecionar MaterialLocalizations.
// ---------------------------------------------------------------------------
Widget _appMaterial({
  required Locale locale,
  required Widget Function(BuildContext) builder,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('pt', 'BR'), Locale('pt'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(builder: builder),
  );
}

void main() {
  // -------------------------------------------------------------------------
  // 1. Locale pt-BR padrão
  // -------------------------------------------------------------------------
  group('locale pt (padrão)', () {
    testWidgets('appTitle retorna "Carro na Mão"', (tester) async {
      await tester.pumpWidget(
        _app(locale: const Locale('pt'), getText: (l) => l.appTitle),
      );
      await tester.pumpAndSettle();
      expect(find.text('Carro na Mão'), findsOneWidget);
    });

    testWidgets('appSubtitulo retorna string em português', (tester) async {
      await tester.pumpWidget(
        _app(locale: const Locale('pt'), getText: (l) => l.appSubtitulo),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Gastos, consumo e lembretes em um só lugar.'),
        findsOneWidget,
      );
    });

    testWidgets('abastecimentosTitulo retorna "Abastecimentos"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          locale: const Locale('pt'),
          getText: (l) => l.abastecimentosTitulo,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Abastecimentos'), findsOneWidget);
    });

    testWidgets('botaoSalvar retorna "Salvar"', (tester) async {
      await tester.pumpWidget(
        _app(locale: const Locale('pt'), getText: (l) => l.botaoSalvar),
      );
      await tester.pumpAndSettle();
      expect(find.text('Salvar'), findsOneWidget);
    });

    testWidgets(
      'abastecimentoAvisoKmRetroativo contém "menor que o último registrado"',
      (tester) async {
        await tester.pumpWidget(
          _app(
            locale: const Locale('pt'),
            getText: (l) => l.abastecimentoAvisoKmRetroativo,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('menor que o último registrado'),
          findsOneWidget,
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // 2. Troca de locale para 'en'
  // -------------------------------------------------------------------------
  group('locale en', () {
    testWidgets('appTitle mantém "Carro na Mão" (nome do app não traduzido)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(locale: const Locale('en'), getText: (l) => l.appTitle),
      );
      await tester.pumpAndSettle();
      // O nome do aplicativo foi mantido igual em en (ver app_en.arb).
      expect(find.text('Carro na Mão'), findsOneWidget);
    });

    testWidgets('appSubtitulo retorna string em inglês', (tester) async {
      await tester.pumpWidget(
        _app(locale: const Locale('en'), getText: (l) => l.appSubtitulo),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Expenses, fuel consumption and reminders in one place.'),
        findsOneWidget,
      );
    });

    testWidgets('abastecimentosTitulo retorna "Fuel History" em inglês', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          getText: (l) => l.abastecimentosTitulo,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fuel History'), findsOneWidget);
    });

    testWidgets('botaoSalvar retorna "Save" em inglês', (tester) async {
      await tester.pumpWidget(
        _app(locale: const Locale('en'), getText: (l) => l.botaoSalvar),
      );
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('aviso km retroativo em inglês NÃO contém "menor que"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          getText: (l) => l.abastecimentoAvisoKmRetroativo,
        ),
      );
      await tester.pumpAndSettle();
      // O texto em inglês deve conter "lower than" em vez de "menor que".
      expect(find.textContaining('lower than'), findsOneWidget);
      expect(find.textContaining('menor que'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // 3. Paridade de chaves pt / en — verificada via lookup em runtime
  //    (as classes geradas possuem todos os métodos/getters por construção;
  //    este teste garante que os delegates carregam sem exceção para pt e en).
  // -------------------------------------------------------------------------
  group('paridade de delegates', () {
    testWidgets('delegate pt carrega sem exceção', (tester) async {
      AppLocalizations? l10n;
      await tester.pumpWidget(
        _app(
          locale: const Locale('pt'),
          getText: (l) {
            l10n = l;
            return l.appTitle;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(l10n, isNotNull);
      expect(l10n!.localeName, 'pt');
    });

    testWidgets('delegate en carrega sem exceção', (tester) async {
      AppLocalizations? l10n;
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          getText: (l) {
            l10n = l;
            return l.appTitle;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(l10n, isNotNull);
      expect(l10n!.localeName, 'en');
    });

    testWidgets('troca dinâmica de locale: pt → en muda string corretamente', (
      tester,
    ) async {
      // Começa em pt.
      await tester.pumpWidget(
        _app(locale: const Locale('pt'), getText: (l) => l.appSubtitulo),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Gastos, consumo e lembretes em um só lugar.'),
        findsOneWidget,
      );

      // Troca para en (novo pumpWidget simula troca de Locale na navegação).
      await tester.pumpWidget(
        _app(locale: const Locale('en'), getText: (l) => l.appSubtitulo),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Expenses, fuel consumption and reminders in one place.'),
        findsOneWidget,
      );
      expect(
        find.text('Gastos, consumo e lembretes em um só lugar.'),
        findsNothing,
      );
    });
  });

  // -------------------------------------------------------------------------
  // 4. Chaves com placeholder (erroGenerico) funcionam em pt e en.
  // -------------------------------------------------------------------------
  group('chaves com placeholder', () {
    testWidgets('erroGenerico (pt) interpola mensagem corretamente', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          locale: const Locale('pt'),
          getText: (l) => l.erroGenerico('falha de rede'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Erro: falha de rede'), findsOneWidget);
    });

    testWidgets('erroGenerico (en) interpola mensagem corretamente', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          getText: (l) => l.erroGenerico('network failure'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Error: network failure'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // 5. Regressão #73 — GlobalMaterialLocalizations traduz widgets nativos
  //    (DatePicker, dialogs) para pt-BR.
  //    Verifica que MaterialLocalizations.of(context) retorna strings em pt
  //    quando o locale é pt_BR.
  // -------------------------------------------------------------------------
  group('regressão #73 — MaterialLocalizations em pt-BR', () {
    testWidgets('cancelButtonLabel retorna "Cancelar" em pt_BR', (
      tester,
    ) async {
      String? cancelLabel;
      await tester.pumpWidget(
        _appMaterial(
          locale: const Locale('pt', 'BR'),
          builder: (context) {
            cancelLabel = MaterialLocalizations.of(context).cancelButtonLabel;
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(cancelLabel, 'Cancelar');
    });

    testWidgets('okButtonLabel retorna "OK" em pt_BR', (tester) async {
      String? okLabel;
      await tester.pumpWidget(
        _appMaterial(
          locale: const Locale('pt', 'BR'),
          builder: (context) {
            okLabel = MaterialLocalizations.of(context).okButtonLabel;
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(okLabel, 'OK');
    });

    testWidgets('cancelButtonLabel retorna "Cancel" em en (controle)', (
      tester,
    ) async {
      String? cancelLabel;
      await tester.pumpWidget(
        _appMaterial(
          locale: const Locale('en'),
          builder: (context) {
            cancelLabel = MaterialLocalizations.of(context).cancelButtonLabel;
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(cancelLabel, 'Cancel');
    });

    testWidgets('localeResolutionCallback: device em pt mapeia para pt_BR', (
      tester,
    ) async {
      // Simula o comportamento do localeResolutionCallback de app.dart:
      // se o deviceLocale tem languageCode "pt", deve resolver para pt_BR.
      Locale? resolvedLocale;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('pt'),
            Locale('en'),
          ],
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale?.languageCode == 'pt') {
              return const Locale('pt', 'BR');
            }
            return const Locale('en');
          },
          locale: const Locale('pt'),
          home: Builder(
            builder: (context) {
              resolvedLocale = Localizations.localeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(resolvedLocale?.languageCode, 'pt');
      expect(resolvedLocale?.countryCode, 'BR');
    });
  });
}
