import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/lembretes/lembrete_detalhe_screen.dart';
import 'package:carro_na_mao/services/lembretes_service.dart';
import 'package:carro_na_mao/services/notifications_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/l10n_delegates.dart';

// ---------------------------------------------------------------------------
// Fake de notificações para testes
// ---------------------------------------------------------------------------

class _FakeNotifPlugin implements NotificationsPluginInterface {
  @override
  Future<void> initialize(InitializationSettings s) async {}

  @override
  Future<void> createAndroidChannel(AndroidNotificationChannel c) async {}

  @override
  Future<bool?> requestAndroidPermission() async => true;

  @override
  Future<bool?> requestIosPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async => null;

  @override
  Future<void> zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
  }) async {}

  @override
  Future<void> show({
    required int id,
    required String? title,
    required String? body,
    required NotificationDetails details,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}

/// Monta a LembreteDetalheScreen com DB real injetado.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required AppDatabase db,
  required int id,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        lembretesServiceProvider.overrideWith(
          (ref) => LembretesService(
            dao: ref.watch(lembretesDaoProvider),
            notifications: NotificationsService(plugin: _FakeNotifPlugin()),
          ),
        ),
      ],
      child: MaterialApp(
        locale: localeDefault,
        localizationsDelegates: l10nDelegates,
        supportedLocales: supportedLocales,
        home: LembreteDetalheScreen(id: id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Desmonta o widget tree e drena timers do Drift.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

/// Insere um veículo no banco de testes.
Future<void> _insertVeiculo(AppDatabase db, {String placa = 'ABC1D23'}) async {
  await db.veiculosDao.insertVeiculo(
    VeiculosCompanion.insert(
      placa: placa,
      marca: 'Fiat',
      modelo: 'Uno',
      ano: 2020,
      tipo: TipoVeiculo.carro,
      combustivel: TipoCombustivelVeiculo.flex,
      kmInicial: 10000,
    ),
  );
}

/// Insere uma manutenção e retorna seu id.
Future<int> _insertManutencao(
  AppDatabase db, {
  String placa = 'ABC1D23',
}) async {
  return db.manutencoesDao.insertManutencao(
    ManutencoesCompanion.insert(
      veiculoPlaca: placa,
      tipo: TipoManutencao.oleoMotor,
      data: DateTime(2026, 1, 10),
      km: 10200,
    ),
  );
}

/// Insere um lembrete e retorna seu id.
Future<int> _insertLembrete(
  AppDatabase db, {
  String placa = 'ABC1D23',
  String tipo = 'avulso',
  String descricao = 'Trocar palhetas',
  DateTime? dataAlvo,
  int? kmAlvo = 50000,
  StatusLembrete status = StatusLembrete.pendente,
  int? manutencaoId,
}) async {
  return db.lembretesDao.insertLembrete(
    LembretesCompanion.insert(
      veiculoPlaca: placa,
      tipo: tipo,
      descricao: descricao,
      dataAlvo: Value(dataAlvo),
      kmAlvo: Value(kmAlvo),
      status: status,
      manutencaoId: Value(manutencaoId),
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _insertVeiculo(db);
  });

  tearDown(() async {
    await db.close();
  });

  // -------------------------------------------------------------------------
  // Renderização dos campos
  // -------------------------------------------------------------------------
  group('renderiza campos do lembrete', () {
    testWidgets('exibe título da tela', (tester) async {
      final id = await _insertLembrete(db, descricao: 'Trocar palhetas');
      await _pumpScreen(tester, db: db, id: id);

      expect(find.text('Detalhe do lembrete'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe descrição do lembrete', (tester) async {
      final id = await _insertLembrete(db, descricao: 'Trocar filtro de ar');
      await _pumpScreen(tester, db: db, id: id);

      expect(find.text('Trocar filtro de ar'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe placa do veículo', (tester) async {
      final id = await _insertLembrete(db, placa: 'ABC1D23');
      await _pumpScreen(tester, db: db, id: id);

      expect(find.text('ABC1D23'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe tipo do lembrete', (tester) async {
      final id = await _insertLembrete(db, tipo: 'oleoMotor');
      await _pumpScreen(tester, db: db, id: id);

      expect(find.text('oleoMotor'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe data alvo formatada dd/MM/yyyy', (tester) async {
      final id = await _insertLembrete(
        db,
        dataAlvo: DateTime(2027, 3, 15),
        kmAlvo: null,
      );
      await _pumpScreen(tester, db: db, id: id);

      expect(find.text('15/03/2027'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe km alvo com separador de milhar', (tester) async {
      final id = await _insertLembrete(db, kmAlvo: 75000);
      await _pumpScreen(tester, db: db, id: id);

      expect(find.textContaining('75.000'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe "Não definida" quando data alvo é nula', (tester) async {
      final id = await _insertLembrete(db, dataAlvo: null, kmAlvo: 50000);
      await _pumpScreen(tester, db: db, id: id);

      expect(find.text('Não definida'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe "Não definido" quando km alvo é nulo', (tester) async {
      final id = await _insertLembrete(
        db,
        dataAlvo: DateTime(2027, 3, 15),
        kmAlvo: null,
      );
      await _pumpScreen(tester, db: db, id: id);

      expect(find.text('Não definido'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe "Nenhuma" quando não há manutenção associada', (
      tester,
    ) async {
      final id = await _insertLembrete(db, manutencaoId: null);
      await _pumpScreen(tester, db: db, id: id);

      expect(find.text('Nenhuma'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe badge com status do lembrete', (tester) async {
      final id = await _insertLembrete(db, status: StatusLembrete.pendente);
      await _pumpScreen(tester, db: db, id: id);

      expect(find.text('Pendente'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe badge "Concluído" para lembrete concluído', (
      tester,
    ) async {
      final id = await _insertLembrete(db, status: StatusLembrete.concluido);
      await _pumpScreen(tester, db: db, id: id);

      expect(find.text('Concluído'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('exibe badge "Adiado" para lembrete adiado', (tester) async {
      final id = await _insertLembrete(db, status: StatusLembrete.adiado);
      await _pumpScreen(tester, db: db, id: id);

      expect(find.text('Adiado'), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Estado não encontrado
  // -------------------------------------------------------------------------
  group('estado não encontrado', () {
    testWidgets('exibe mensagem quando id não existe', (tester) async {
      await _pumpScreen(tester, db: db, id: 9999);

      expect(find.text('Lembrete não encontrado.'), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Botões de ação — visibilidade
  // -------------------------------------------------------------------------
  group('visibilidade dos botões', () {
    testWidgets('botões Concluir e Adiar visíveis para lembrete pendente', (
      tester,
    ) async {
      final id = await _insertLembrete(db, status: StatusLembrete.pendente);
      await _pumpScreen(tester, db: db, id: id);

      expect(find.byKey(const Key('btn_concluir')), findsOneWidget);
      expect(find.byKey(const Key('btn_adiar')), findsOneWidget);
      expect(find.byKey(const Key('btn_excluir')), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('botões Concluir e Adiar ausentes para lembrete já concluído', (
      tester,
    ) async {
      final id = await _insertLembrete(db, status: StatusLembrete.concluido);
      await _pumpScreen(tester, db: db, id: id);

      expect(find.byKey(const Key('btn_concluir')), findsNothing);
      expect(find.byKey(const Key('btn_adiar')), findsNothing);
      expect(find.byKey(const Key('btn_excluir')), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('botão Excluir sempre visível', (tester) async {
      final id = await _insertLembrete(db, status: StatusLembrete.concluido);
      await _pumpScreen(tester, db: db, id: id);

      expect(find.byKey(const Key('btn_excluir')), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Fluxo: Concluir
  // -------------------------------------------------------------------------
  group('ação concluir', () {
    testWidgets('dialog de confirmação é exibido ao tocar Concluir', (
      tester,
    ) async {
      final id = await _insertLembrete(db);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_concluir')));
      await tester.pumpAndSettle();

      expect(find.text('Concluir lembrete'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('confirmar conclusão marca lembrete como concluído', (
      tester,
    ) async {
      final id = await _insertLembrete(db);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_concluir')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_concluir_confirmar')));
      await tester.pumpAndSettle();

      final lembrete = await db.lembretesDao.byId(id);
      expect(lembrete?.status, StatusLembrete.concluido);
      await _teardown(tester);
    });

    testWidgets('cancelar no dialog não altera o status', (tester) async {
      final id = await _insertLembrete(db);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_concluir')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      final lembrete = await db.lembretesDao.byId(id);
      expect(lembrete?.status, StatusLembrete.pendente);
      await _teardown(tester);
    });

    testWidgets(
      'oferta "Registrar manutenção" aparece para tipo != avulso com manutencaoId',
      (tester) async {
        // RF-17: critério é manutencaoId != null, não tipo != avulso.
        // Inserimos um lembrete com tipo != avulso E manutencaoId preenchido.
        final manutId = await _insertManutencao(db);
        final id = await _insertLembrete(
          db,
          tipo: 'oleoMotor',
          manutencaoId: manutId,
        );
        await _pumpScreen(tester, db: db, id: id);

        await tester.tap(find.byKey(const Key('btn_concluir')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('btn_concluir_registrar_manutencao')),
          findsOneWidget,
        );
        await _teardown(tester);
      },
    );

    testWidgets('oferta "Registrar manutenção" NÃO aparece para tipo avulso', (
      tester,
    ) async {
      final id = await _insertLembrete(db, tipo: 'avulso');
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_concluir')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('btn_concluir_registrar_manutencao')),
        findsNothing,
      );
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Fluxo: Adiar
  // -------------------------------------------------------------------------
  group('ação adiar', () {
    testWidgets('dialog de adiamento é exibido ao tocar Adiar', (tester) async {
      final id = await _insertLembrete(db);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_adiar')));
      await tester.pumpAndSettle();

      expect(find.text('Adiar lembrete'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('preencher apenas km e confirmar salva novo km', (
      tester,
    ) async {
      final id = await _insertLembrete(db, kmAlvo: 50000, dataAlvo: null);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_adiar')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('adiar_km_field')), '60000');

      await tester.tap(find.byKey(const Key('btn_adiar_confirmar')));
      await tester.pumpAndSettle();

      final lembrete = await db.lembretesDao.byId(id);
      expect(lembrete?.kmAlvo, 60000);
      await _teardown(tester);
    });

    testWidgets('confirmar sem data nem km exibe erro de validação', (
      tester,
    ) async {
      // Inserimos com km mas abrimos o dialog e limpamos o campo;
      // a data fica nula (nenhuma seleção), confirmamos sem nada.
      final id = await _insertLembrete(db, kmAlvo: 50000, dataAlvo: null);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_adiar')));
      await tester.pumpAndSettle();

      // Limpa o campo km (vem pré-preenchido com 50000)
      await tester.enterText(find.byKey(const Key('adiar_km_field')), '');

      // Confirmar sem data (nenhuma seleção) e sem km
      await tester.tap(find.byKey(const Key('btn_adiar_confirmar')));
      await tester.pumpAndSettle();

      expect(find.text('Informe ao menos uma data ou km.'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('cancelar no dialog de adiamento não altera o lembrete', (
      tester,
    ) async {
      final id = await _insertLembrete(db, kmAlvo: 50000);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_adiar')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      final lembrete = await db.lembretesDao.byId(id);
      expect(lembrete?.kmAlvo, 50000);
      expect(lembrete?.status, StatusLembrete.pendente);
      await _teardown(tester);
    });

    testWidgets('adiar muda status para adiado no banco', (tester) async {
      final id = await _insertLembrete(db, kmAlvo: 50000, dataAlvo: null);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_adiar')));
      await tester.pumpAndSettle();

      // km já vem pré-preenchido; confirmar direto
      await tester.tap(find.byKey(const Key('btn_adiar_confirmar')));
      await tester.pumpAndSettle();

      final lembrete = await db.lembretesDao.byId(id);
      // Lembrete adiado deve ficar com status adiado, não pendente
      expect(lembrete?.status, StatusLembrete.adiado);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Oferta "Registrar manutenção" — critério RF-17 (manutencaoId)
  // -------------------------------------------------------------------------
  group('oferta registrar manutenção por manutencaoId', () {
    testWidgets('oferta aparece para tipo avulso quando manutencaoId != null', (
      tester,
    ) async {
      // Segundo o RF-17 da issue #26, a oferta deve aparecer quando o
      // lembrete tem manutencao_id preenchido, independente do tipo.
      final manutId = await _insertManutencao(db);
      final id = await _insertLembrete(
        db,
        tipo: 'avulso',
        manutencaoId: manutId,
      );
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_concluir')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('btn_concluir_registrar_manutencao')),
        findsOneWidget,
      );
      await _teardown(tester);
    });

    testWidgets('oferta NÃO aparece quando manutencaoId é nulo e tipo avulso', (
      tester,
    ) async {
      final id = await _insertLembrete(db, tipo: 'avulso', manutencaoId: null);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_concluir')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('btn_concluir_registrar_manutencao')),
        findsNothing,
      );
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Navegação para form de manutenção com pré-preenchimento (issue #115)
  // -------------------------------------------------------------------------
  group('registrar manutenção — navegação pré-preenchida (issue #115)', () {
    testWidgets(
      'concluir + registrar manutenção navega para /manutencoes/novo '
      'com tipo, placa e kmSugerido',
      (tester) async {
        String? capturedPath;
        final manutId = await _insertManutencao(db);
        final id = await _insertLembrete(
          db,
          tipo: 'pastilhasFreio',
          manutencaoId: manutId,
          placa: 'ABC1D23',
          kmAlvo: 85000,
        );

        SharedPreferences.setMockInitialValues(const {});
        final router = GoRouter(
          initialLocation: '/lembretes/$id',
          routes: [
            GoRoute(
              path: '/lembretes/:id',
              builder: (c, s) => ProviderScope(
                overrides: [
                  appDatabaseProvider.overrideWithValue(db),
                  lembretesServiceProvider.overrideWith(
                    (ref) => LembretesService(
                      dao: ref.watch(lembretesDaoProvider),
                      notifications:
                          NotificationsService(plugin: _FakeNotifPlugin()),
                    ),
                  ),
                ],
                child: LembreteDetalheScreen(
                  id: int.parse(s.pathParameters['id']!),
                ),
              ),
            ),
            GoRoute(
              path: '/manutencoes/novo',
              builder: (c, s) {
                capturedPath = s.uri.toString();
                return const Scaffold(body: Text('FORM_MANUTENCAO'));
              },
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp.router(
              locale: localeDefault,
              localizationsDelegates: l10nDelegates,
              supportedLocales: supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_concluir')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('btn_concluir_registrar_manutencao')),
        );
        await tester.pumpAndSettle();

        expect(find.text('FORM_MANUTENCAO'), findsOneWidget);
        expect(capturedPath, isNotNull);
        expect(capturedPath, contains('tipo=pastilhasFreio'));
        expect(capturedPath, contains('placa=ABC1D23'));
        expect(capturedPath, contains('kmSugerido=85000'));

        await _teardown(tester);
      },
    );

    testWidgets(
      'lembrete sem kmAlvo navega sem kmSugerido na query string',
      (tester) async {
        String? capturedPath;
        // Lembrete com dataAlvo mas sem kmAlvo
        final manutId = await _insertManutencao(db);
        final id = await _insertLembrete(
          db,
          tipo: 'filtroAr',
          manutencaoId: manutId,
          placa: 'ABC1D23',
          kmAlvo: null,
          dataAlvo: DateTime(2027, 6, 1),
        );

        SharedPreferences.setMockInitialValues(const {});
        final router = GoRouter(
          initialLocation: '/lembretes/$id',
          routes: [
            GoRoute(
              path: '/lembretes/:id',
              builder: (c, s) => ProviderScope(
                overrides: [
                  appDatabaseProvider.overrideWithValue(db),
                  lembretesServiceProvider.overrideWith(
                    (ref) => LembretesService(
                      dao: ref.watch(lembretesDaoProvider),
                      notifications:
                          NotificationsService(plugin: _FakeNotifPlugin()),
                    ),
                  ),
                ],
                child: LembreteDetalheScreen(
                  id: int.parse(s.pathParameters['id']!),
                ),
              ),
            ),
            GoRoute(
              path: '/manutencoes/novo',
              builder: (c, s) {
                capturedPath = s.uri.toString();
                return const Scaffold(body: Text('FORM_MANUTENCAO'));
              },
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp.router(
              locale: localeDefault,
              localizationsDelegates: l10nDelegates,
              supportedLocales: supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('btn_concluir')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('btn_concluir_registrar_manutencao')),
        );
        await tester.pumpAndSettle();

        expect(find.text('FORM_MANUTENCAO'), findsOneWidget);
        expect(capturedPath, isNotNull);
        expect(capturedPath, contains('tipo=filtroAr'));
        expect(capturedPath, contains('placa=ABC1D23'));
        // Sem kmAlvo, não deve conter kmSugerido
        expect(capturedPath, isNot(contains('kmSugerido')));

        await _teardown(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Fluxo: Excluir
  // -------------------------------------------------------------------------
  group('ação excluir', () {
    testWidgets('dialog de confirmação é exibido ao tocar Excluir', (
      tester,
    ) async {
      final id = await _insertLembrete(db);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_excluir')));
      await tester.pumpAndSettle();

      expect(find.text('Excluir lembrete'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('confirmar exclusão deleta o lembrete do banco', (
      tester,
    ) async {
      final id = await _insertLembrete(db);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_excluir')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_excluir_confirmar')));
      await tester.pumpAndSettle();

      final lembrete = await db.lembretesDao.byId(id);
      expect(lembrete, isNull);
      await _teardown(tester);
    });

    testWidgets('cancelar exclusão não deleta o lembrete', (tester) async {
      final id = await _insertLembrete(db);
      await _pumpScreen(tester, db: db, id: id);

      await tester.tap(find.byKey(const Key('btn_excluir')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      final lembrete = await db.lembretesDao.byId(id);
      expect(lembrete, isNotNull);
      await _teardown(tester);
    });
  });
}
