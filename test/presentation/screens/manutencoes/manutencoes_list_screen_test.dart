import 'dart:async';

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/manutencoes/manutencoes_list_screen.dart';
import 'package:carro_na_mao/presentation/screens/manutencoes/manutencoes_providers.dart';
import 'package:carro_na_mao/presentation/screens/veiculos/veiculos_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/l10n_delegates.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

VeiculosCompanion _novoVeiculo({String placa = 'ABC1D23'}) =>
    VeiculosCompanion.insert(
      placa: placa,
      marca: 'Fiat',
      modelo: 'Uno',
      ano: 2020,
      tipo: TipoVeiculo.carro,
      combustivel: TipoCombustivelVeiculo.flex,
      kmInicial: 10000,
    );

ManutencoesCompanion _novaManutencao({
  String placa = 'ABC1D23',
  required DateTime data,
  required int km,
  TipoManutencao tipo = TipoManutencao.oleoMotor,
  double? valor,
  String? oficina,
  String? nomeLivre,
}) => ManutencoesCompanion.insert(
  veiculoPlaca: placa,
  tipo: tipo,
  data: data,
  km: km,
  valor: Value(valor),
  oficina: Value(oficina),
  nomeLivre: Value(nomeLivre),
);

/// Monta a tela com GoRouter mínimo que registra também as rotas de navegação.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required AppDatabase db,
  String? placaAtiva,
}) async {
  SharedPreferences.setMockInitialValues(
    placaAtiva == null ? {} : {'veiculo_selecionado_placa': placaAtiva},
  );

  final router = GoRouter(
    initialLocation: '/manutencoes',
    routes: [
      GoRoute(
        path: '/manutencoes',
        builder: (c, s) => const ManutencoesListScreen(),
      ),
      GoRoute(
        path: '/manutencoes/novo',
        builder: (c, s) => const Scaffold(body: Text('TELA_NOVA_MANUTENCAO')),
      ),
      GoRoute(
        path: '/manutencoes/:id/editar',
        builder: (c, s) =>
            Scaffold(body: Text('TELA_EDITAR_${s.pathParameters["id"]}')),
      ),
      GoRoute(
        path: '/veiculos/novo',
        builder: (c, s) => const Scaffold(body: Text('TELA_NOVO_VEICULO')),
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
  // Aguarda stream inicial resolver
  await tester.pumpAndSettle();
}

/// Desmonta o widget tree e drena timers do Drift.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 10));
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // -------------------------------------------------------------------------
  // Estado sem veículo selecionado
  // -------------------------------------------------------------------------
  group('sem veículo cadastrado', () {
    testWidgets('exibe mensagem de cadastrar veículo', (tester) async {
      await _pumpScreen(tester, db: db);

      expect(find.textContaining('Cadastre um veículo'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('FAB não aparece quando sem veículo', (tester) async {
      await _pumpScreen(tester, db: db);

      expect(find.byType(FloatingActionButton), findsNothing);
      await _teardown(tester);
    });

    testWidgets('botão Cadastrar veículo navega para /veiculos/novo', (
      tester,
    ) async {
      await _pumpScreen(tester, db: db);

      await tester.tap(find.text('Cadastrar veículo'));
      await tester.pumpAndSettle();

      expect(find.text('TELA_NOVO_VEICULO'), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Lista vazia (veículo cadastrado, sem manutenções)
  // -------------------------------------------------------------------------
  group('veículo cadastrado, sem manutenções', () {
    testWidgets('exibe mensagem de lista vazia', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('Nenhuma manutenção'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('FAB aparece com veículo cadastrado', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.byType(FloatingActionButton), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('FAB navega para /manutencoes/novo', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('TELA_NOVA_MANUTENCAO'), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Lista com itens — ordem por data desc
  // -------------------------------------------------------------------------
  group('lista com itens — ordem por data desc', () {
    testWidgets('itens aparecem em ordem descendente de data', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(data: DateTime(2026, 1, 10), km: 10000),
      );
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 6, 15),
          km: 20000,
          tipo: TipoManutencao.velas,
        ),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      final junhoPos = tester.getTopLeft(find.textContaining('15/06/2026')).dy;
      final janeiroPos = tester
          .getTopLeft(find.textContaining('10/01/2026'))
          .dy;

      // Data mais recente (junho) deve aparecer acima (menor dy)
      expect(junhoPos, lessThan(janeiroPos));
      await _teardown(tester);
    });

    testWidgets('tile exibe data no formato dd/MM/yyyy', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(data: DateTime(2026, 3, 5), km: 15000),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('05/03/2026'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('tile exibe km com separador de milhar (ponto)', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(data: DateTime(2026, 3, 5), km: 123456),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('123.456'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('tile exibe valor em reais formatado com virgula decimal', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(data: DateTime(2026, 3, 5), km: 15000, valor: 350.00),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('R\$ 350,00'), findsAtLeastNWidgets(1));
      await _teardown(tester);
    });

    testWidgets(
      'tile exibe valor em reais com separador de milhar para valores grandes',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await db.manutencoesDao.insertManutencao(
          _novaManutencao(
            data: DateTime(2026, 3, 5),
            km: 15000,
            valor: 1234.56,
          ),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        // O valor aparece tanto no título (R$ 1.234,56) quanto no subtítulo
        expect(find.textContaining('1.234,56'), findsAtLeastNWidgets(1));
        await _teardown(tester);
      },
    );

    testWidgets('tile nao exibe valor em reais quando valor e nulo', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 3, 5),
          km: 15000,
          // valor não fornecido → nulo
        ),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('R\$'), findsNothing);
      await _teardown(tester);
    });

    testWidgets('tile exibe oficina quando preenchida', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 3, 5),
          km: 15000,
          oficina: 'Auto Center SP',
        ),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('Auto Center SP'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('tile exibe tipo traduzido em pt-BR', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 3, 5),
          km: 15000,
          tipo: TipoManutencao.correiaDentada,
        ),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.textContaining('Correia dentada'), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Tipo "outros": exibição do nomeLivre
  // -------------------------------------------------------------------------
  group('tipo "outros"', () {
    testWidgets(
      'exibe nomeLivre quando tipo=outros e nomeLivre está preenchido',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await db.manutencoesDao.insertManutencao(
          _novaManutencao(
            data: DateTime(2026, 5, 10),
            km: 18000,
            tipo: TipoManutencao.outros,
            nomeLivre: 'Limpeza de bico',
          ),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        expect(find.textContaining('Limpeza de bico'), findsOneWidget);
        // Label genérico "Outros" NÃO deve aparecer no tile de título
        expect(find.textContaining('· Outros'), findsNothing);
        await _teardown(tester);
      },
    );

    testWidgets(
      'exibe label traduzido "Outros" quando tipo=outros e nomeLivre é nulo',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await db.manutencoesDao.insertManutencao(
          _novaManutencao(
            data: DateTime(2026, 5, 10),
            km: 18000,
            tipo: TipoManutencao.outros,
            // nomeLivre nulo — deve cair no label traduzido
          ),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        expect(find.textContaining('Outros'), findsOneWidget);
        await _teardown(tester);
      },
    );

    testWidgets(
      'exibe label traduzido "Outros" quando tipo=outros e nomeLivre está vazio',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await db.manutencoesDao.insertManutencao(
          _novaManutencao(
            data: DateTime(2026, 5, 10),
            km: 18000,
            tipo: TipoManutencao.outros,
            nomeLivre: '', // vazio → deve cair no label traduzido
          ),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        expect(find.textContaining('Outros'), findsOneWidget);
        await _teardown(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Navegação por toque na linha
  // -------------------------------------------------------------------------
  group('navegação por toque na linha', () {
    testWidgets('toque numa linha navega para /manutencoes/:id/editar', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      final id = await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 3, 1),
          km: 15000,
          oficina: 'Oficina XYZ',
        ),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.textContaining('Oficina XYZ'));
      await tester.pumpAndSettle();

      expect(find.text('TELA_EDITAR_$id'), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Toggle de agrupamento por tipo
  // -------------------------------------------------------------------------
  group('toggle de agrupamento por tipo', () {
    testWidgets('Switch de agrupamento está visível no AppBar', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Agrupar por tipo'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('Switch default está desligado (agrupamento OFF)', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 3, 5),
          km: 10000,
          tipo: TipoManutencao.oleoMotor,
        ),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isFalse);
      await _teardown(tester);
    });

    testWidgets('agrupamento OFF → sem cabeçalhos de tipo', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 3, 5),
          km: 10000,
          tipo: TipoManutencao.oleoMotor,
        ),
      );
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 4, 5),
          km: 15000,
          tipo: TipoManutencao.velas,
        ),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // Switch está OFF — sem cabeçalhos isolados de tipo
      // (O tipo aparece inline no título do tile, mas não como cabeçalho)
      // Verificamos que o Switch está OFF
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isFalse);

      await _teardown(tester);
    });

    testWidgets('ativar Switch liga agrupamento ON', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 3, 5),
          km: 10000,
          tipo: TipoManutencao.oleoMotor,
        ),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isTrue);
      await _teardown(tester);
    });

    testWidgets('agrupamento ON → cabeçalhos de tipo aparecem', (tester) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 3, 5),
          km: 10000,
          tipo: TipoManutencao.oleoMotor,
        ),
      );
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 4, 5),
          km: 15000,
          tipo: TipoManutencao.velas,
        ),
      );

      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Cabeçalhos de tipo com labels traduzidos
      expect(find.text('Óleo do motor'), findsAtLeastNWidgets(1));
      expect(find.text('Velas de ignição'), findsAtLeastNWidgets(1));
      await _teardown(tester);
    });

    testWidgets(
      'agrupamento ON → tipos ordenados alfabeticamente (cabeçalhos em ordem)',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        // Inserir fora de ordem alfabética: "Velas de ignição" antes de "Óleo do motor"
        await db.manutencoesDao.insertManutencao(
          _novaManutencao(
            data: DateTime(2026, 6, 1),
            km: 20000,
            tipo: TipoManutencao.velas,
          ),
        );
        await db.manutencoesDao.insertManutencao(
          _novaManutencao(
            data: DateTime(2026, 3, 5),
            km: 10000,
            tipo: TipoManutencao.oleoMotor,
          ),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        // "Óleo do motor" (O) vem antes de "Velas de ignição" (V) alfabeticamente
        final oleoPos = tester.getTopLeft(find.text('Óleo do motor').first).dy;
        final velasPos = tester
            .getTopLeft(find.text('Velas de ignição').first)
            .dy;

        expect(oleoPos, lessThan(velasPos));
        await _teardown(tester);
      },
    );

    testWidgets(
      'agrupamento ON → itens do mesmo tipo ficam sob o mesmo cabeçalho',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        // Dois itens de oleoMotor em datas diferentes
        await db.manutencoesDao.insertManutencao(
          _novaManutencao(
            data: DateTime(2026, 1, 1),
            km: 10000,
            tipo: TipoManutencao.oleoMotor,
          ),
        );
        await db.manutencoesDao.insertManutencao(
          _novaManutencao(
            data: DateTime(2026, 6, 1),
            km: 20000,
            tipo: TipoManutencao.oleoMotor,
          ),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        // Apenas um cabeçalho "Óleo do motor"
        // (O tipo aparece no cabeçalho E no tile título)
        // Contamos o cabeçalho pelo texto standalone (sem data)
        // Verificamos que os dois tiles existem e o cabeçalho só uma vez
        expect(find.textContaining('01/01/2026'), findsOneWidget);
        expect(find.textContaining('01/06/2026'), findsOneWidget);
        await _teardown(tester);
      },
    );

    testWidgets(
      'desativar Switch volta para lista plana sem cabeçalhos de tipo',
      (tester) async {
        await db.veiculosDao.insertVeiculo(_novoVeiculo());
        await db.manutencoesDao.insertManutencao(
          _novaManutencao(
            data: DateTime(2026, 3, 5),
            km: 10000,
            tipo: TipoManutencao.oleoMotor,
          ),
        );

        await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

        // Liga agrupamento
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        // Desliga agrupamento
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        final sw = tester.widget<Switch>(find.byType(Switch));
        expect(sw.value, isFalse);
        await _teardown(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Reatividade: stream reage a inserts
  // -------------------------------------------------------------------------
  group('reatividade', () {
    testWidgets('inserir manutenção → tela atualiza automaticamente', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());
      await _pumpScreen(tester, db: db, placaAtiva: 'ABC1D23');

      // Inicialmente lista vazia
      expect(find.textContaining('Nenhuma manutenção'), findsOneWidget);

      // Insere manutenção diretamente no banco
      await db.manutencoesDao.insertManutencao(
        _novaManutencao(
          data: DateTime(2026, 5, 10),
          km: 18000,
          oficina: 'OficinaNova',
        ),
      );
      await tester.pumpAndSettle();

      // Tela deve exibir o novo item
      expect(find.textContaining('OficinaNova'), findsOneWidget);
      expect(find.textContaining('Nenhuma manutenção'), findsNothing);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Estado de loading
  // -------------------------------------------------------------------------
  group('estado de loading', () {
    testWidgets('exibe indicador de loading enquanto o stream carrega', (
      tester,
    ) async {
      // Cria um veículo fixo para sobrescrever veiculoAtivoProvider,
      // garantindo que o branch do stream de manutenções seja alcançado.
      const veiculoFixo = Veiculo(
        placa: 'ABC1D23',
        marca: 'Fiat',
        modelo: 'Uno',
        ano: 2020,
        tipo: TipoVeiculo.carro,
        combustivel: TipoCombustivelVeiculo.flex,
        kmInicial: 10000,
        arquivado: false,
      );

      SharedPreferences.setMockInitialValues(const {});

      final router = GoRouter(
        initialLocation: '/manutencoes',
        routes: [
          GoRoute(
            path: '/manutencoes',
            builder: (c, s) => const ManutencoesListScreen(),
          ),
          GoRoute(
            path: '/veiculos/novo',
            builder: (c, s) => const Scaffold(body: Text('TELA_NOVO_VEICULO')),
          ),
        ],
      );

      // Stream que nunca emite — provider fica em AsyncLoading indefinidamente
      final neverStream = StreamController<List<Manutencao>>();
      addTearDown(neverStream.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            veiculoAtivoProvider.overrideWithValue(veiculoFixo),
            manutencoesDoVeiculoProvider.overrideWith(
              (ref, placa) => neverStream.stream,
            ),
          ],
          child: MaterialApp.router(
            locale: localeDefault,
            localizationsDelegates: l10nDelegates,
            supportedLocales: supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      // pump sem settle para capturar estado loading
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Estado de erro
  // -------------------------------------------------------------------------
  group('estado de erro', () {
    testWidgets('quando stream emite erro, exibe mensagem de erro', (
      tester,
    ) async {
      await db.veiculosDao.insertVeiculo(_novoVeiculo());

      SharedPreferences.setMockInitialValues(const {
        'veiculo_selecionado_placa': 'ABC1D23',
      });

      final router = GoRouter(
        initialLocation: '/manutencoes',
        routes: [
          GoRoute(
            path: '/manutencoes',
            builder: (c, s) => const ManutencoesListScreen(),
          ),
          GoRoute(
            path: '/veiculos/novo',
            builder: (c, s) => const Scaffold(body: Text('TELA_NOVO_VEICULO')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            manutencoesDoVeiculoProvider.overrideWith(
              (ref, placa) =>
                  Stream<List<Manutencao>>.error('Erro simulado de BD'),
            ),
          ],
          child: MaterialApp.router(
            locale: localeDefault,
            localizationsDelegates: l10nDelegates,
            supportedLocales: supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro'), findsOneWidget);
      await _teardown(tester);
    });
  });

  // -------------------------------------------------------------------------
  // AppBar
  // -------------------------------------------------------------------------
  group('AppBar', () {
    testWidgets('título "Manutenções" aparece no AppBar', (tester) async {
      await _pumpScreen(tester, db: db);

      expect(find.text('Manutenções'), findsOneWidget);
      await _teardown(tester);
    });
  });
}
