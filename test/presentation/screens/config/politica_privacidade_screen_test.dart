import 'dart:convert';

import 'package:carro_na_mao/presentation/screens/config/politica_privacidade_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/l10n_delegates.dart';

// Conteúdo fictício que espelha a estrutura da política real.
const _fakeMarkdown = '''
# Política de Privacidade — Carro na Mão

## 1. Dados coletados

**Nenhum.**

Nenhum dado pessoal é coletado.

## 6. Contato

Dúvidas: lucasengecomp@gmail.com
''';

const _assetKey = 'docs/privacidade/politica-de-privacidade.md';

/// Registra o asset fake no rootBundle para o caminho esperado.
void _registerFakeAsset() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  // ignore: deprecated_member_use
  rootBundle.evict(_assetKey);
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
    ByteData? message,
  ) async {
    if (message == null) return null;
    final key = utf8.decode(message.buffer.asUint8List());
    if (key == _assetKey) {
      final encoded = utf8.encode(_fakeMarkdown);
      return ByteData.view(Uint8List.fromList(encoded).buffer);
    }
    return null;
  });
}

Widget _buildApp() {
  return const MaterialApp(
    locale: localeDefault,
    localizationsDelegates: l10nDelegates,
    supportedLocales: supportedLocales,
    home: PoliticaPrivacidadeScreen(),
  );
}

void main() {
  setUp(_registerFakeAsset);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    // ignore: deprecated_member_use
    rootBundle.evict(_assetKey);
  });

  testWidgets('renderiza a AppBar com o título correto', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Política de privacidade'), findsOneWidget);
  });

  testWidgets('renderiza o widget Markdown sem crashar', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(Markdown), findsOneWidget);
  });

  testWidgets('conteúdo contém seção esperada da política', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Dados coletados'), findsOneWidget);
  });

  testWidgets('conteúdo contém palavra Privacidade no título', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Privacidade'), findsWidgets);
  });
}
