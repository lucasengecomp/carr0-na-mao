// ignore_for_file: avoid_print

import 'dart:async';

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/dashboard/dashboard_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers de criação de dados
// ---------------------------------------------------------------------------

const _placa = 'ABC1D23';

VeiculosCompanion _novoVeiculo({String placa = _placa}) =>
    VeiculosCompanion.insert(
      placa: placa,
      marca: 'Fiat',
      modelo: 'Uno',
      ano: 2020,
      tipo: TipoVeiculo.carro,
      combustivel: TipoCombustivelVeiculo.flex,
      kmInicial: 10000,
    );

AbastecimentosCompanion _novoAbast({
  String placa = _placa,
  required DateTime data,
  required int km,
  double litros = 40,
  double precoLitro = 6.0,
  double valorTotal = 240.0,
  bool tanqueCheio = true,
}) => AbastecimentosCompanion.insert(
  veiculoPlaca: placa,
  data: data,
  km: km,
  tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
  precoLitro: precoLitro,
  valorTotal: valorTotal,
  litros: litros,
  tanqueCheio: Value(tanqueCheio),
);

ManutencoesCompanion _novaManut({
  String placa = _placa,
  required DateTime data,
  required int km,
  double? valor,
}) => ManutencoesCompanion.insert(
  veiculoPlaca: placa,
  tipo: TipoManutencao.oleoMotor,
  data: data,
  km: km,
  valor: Value(valor),
);

LembretesCompanion _novoLembrete({
  String placa = _placa,
  required String descricao,
  DateTime? dataAlvo,
  int? kmAlvo,
  StatusLembrete status = StatusLembrete.pendente,
}) => LembretesCompanion.insert(
  veiculoPlaca: placa,
  tipo: 'avulso',
  descricao: descricao,
  dataAlvo: Value(dataAlvo),
  kmAlvo: Value(kmAlvo),
  status: status,
);

/// Cria container com (ou sem) veículo ativo selecionado via SharedPreferences.
ProviderContainer _makeContainer(AppDatabase db, {String? placa = _placa}) {
  SharedPreferences.setMockInitialValues(
    placa != null ? {'veiculo_selecionado_placa': placa} : {},
  );
  return ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
}

/// Aguarda o primeiro valor non-loading de custoMensalProvider.
Future<AsyncValue<CustoMensalResult?>> _awaitMensal(ProviderContainer c) async {
  final completer = Completer<AsyncValue<CustoMensalResult?>>();
  final sub = c.listen<AsyncValue<CustoMensalResult?>>(custoMensalProvider, (
    _,
    next,
  ) {
    if (!next.isLoading && !completer.isCompleted) completer.complete(next);
  }, fireImmediately: true);
  try {
    return await completer.future.timeout(const Duration(seconds: 10));
  } finally {
    sub.close();
  }
}

/// Aguarda o primeiro valor non-loading de custoPorKmProvider.
Future<AsyncValue<CustoPorKmResult?>> _awaitKm(ProviderContainer c) async {
  final completer = Completer<AsyncValue<CustoPorKmResult?>>();
  final sub = c.listen<AsyncValue<CustoPorKmResult?>>(custoPorKmProvider, (
    _,
    next,
  ) {
    if (!next.isLoading && !completer.isCompleted) completer.complete(next);
  }, fireImmediately: true);
  try {
    return await completer.future.timeout(const Duration(seconds: 10));
  } finally {
    sub.close();
  }
}

/// Aguarda o primeiro valor non-loading de consumoMedioProvider.
Future<AsyncValue<ConsumoMedioResult?>> _awaitConsumo(
  ProviderContainer c,
) async {
  final completer = Completer<AsyncValue<ConsumoMedioResult?>>();
  final sub = c.listen<AsyncValue<ConsumoMedioResult?>>(consumoMedioProvider, (
    _,
    next,
  ) {
    if (!next.isLoading && !completer.isCompleted) completer.complete(next);
  }, fireImmediately: true);
  try {
    return await completer.future.timeout(const Duration(seconds: 10));
  } finally {
    sub.close();
  }
}

/// Aguarda o primeiro valor non-loading de proximasManutencoeProvider.
Future<AsyncValue<List<Lembrete>?>> _awaitManutenco(ProviderContainer c) async {
  final completer = Completer<AsyncValue<List<Lembrete>?>>();
  final sub = c.listen<AsyncValue<List<Lembrete>?>>(
    proximasManutencoeProvider,
    (_, next) {
      if (!next.isLoading && !completer.isCompleted) completer.complete(next);
    },
    fireImmediately: true,
  );
  try {
    return await completer.future.timeout(const Duration(seconds: 10));
  } finally {
    sub.close();
  }
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.veiculosDao.insertVeiculo(_novoVeiculo());
    container = _makeContainer(db);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  // =========================================================================
  // Card 1 — custo mensal
  // =========================================================================

  group('custoMensalProvider', () {
    test('retorna zero quando banco vazio (mas veículo existe)', () async {
      final val = await _awaitMensal(container);
      expect(val.value, isNotNull);
      expect(val.value!.total, 0.0);
    });

    test(
      'soma apenas abastecimentos do mês corrente, ignora mês anterior',
      () async {
        final now = DateTime.now();
        final mesAtual = DateTime(now.year, now.month, 15);
        final mesAnteriorAno = now.month == 1 ? now.year - 1 : now.year;
        final mesAnteriorMes = now.month == 1 ? 12 : now.month - 1;
        final mesAnterior = DateTime(mesAnteriorAno, mesAnteriorMes, 15);

        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: mesAtual, km: 10100, valorTotal: 300.0),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(data: mesAnterior, km: 10200, valorTotal: 250.0),
        );

        final val = await _awaitMensal(container);
        expect(val.value, isNotNull);
        // Só o abastecimento do mês atual (300); o do mês anterior deve ser ignorado
        expect(val.value!.total, closeTo(300.0, 0.01));
      },
    );

    test('soma manutenções com valor no mês corrente; ignora sem valor e mês anterior', () async {
      final now = DateTime.now();
      final mesAnteriorAno = now.month == 1 ? now.year - 1 : now.year;
      final mesAnteriorMes = now.month == 1 ? 12 : now.month - 1;

      await db.manutencoesDao.insertManutencao(
        _novaManut(
          data: DateTime(now.year, now.month, 5),
          km: 10100,
          valor: 450.0,
        ),
      );
      // Manutenção do mês anterior — não deve entrar
      await db.manutencoesDao.insertManutencao(
        _novaManut(
          data: DateTime(mesAnteriorAno, mesAnteriorMes, 5),
          km: 10200,
          valor: 200.0,
        ),
      );
      // Manutenção sem valor — não deve somar
      await db.manutencoesDao.insertManutencao(
        _novaManut(data: DateTime(now.year, now.month, 10), km: 10300),
      );

      final val = await _awaitMensal(container);
      expect(val.value, isNotNull);
      expect(val.value!.total, closeTo(450.0, 0.01));
    });

    test('soma abastecimentos + manutenções do mês corrente juntos', () async {
      final now = DateTime.now();
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 1),
          km: 10100,
          valorTotal: 100.0,
        ),
      );
      await db.manutencoesDao.insertManutencao(
        _novaManut(
          data: DateTime(now.year, now.month, 2),
          km: 10200,
          valor: 50.0,
        ),
      );

      final val = await _awaitMensal(container);
      expect(val.value, isNotNull);
      expect(val.value!.total, closeTo(150.0, 0.01));
    });

    test('retorna null quando não há veículo ativo', () async {
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      final container2 = _makeContainer(db2, placa: null);
      addTearDown(() async {
        container2.dispose();
        await db2.close();
      });

      final val = await _awaitMensal(container2);
      expect(val.value, isNull);
    });
  });

  // =========================================================================
  // Card 2 — custo por km (últimos 12 meses)
  // =========================================================================

  group('custoPorKmProvider', () {
    test('retorna null quando banco vazio (sem abastecimentos)', () async {
      final val = await _awaitKm(container);
      expect(val.value, isNull);
    });

    test(
      'retorna null com apenas 1 abastecimento (< 2 pontos de km)',
      () async {
        final now = DateTime.now();
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 5),
            km: 10100,
            valorTotal: 200.0,
          ),
        );

        final val = await _awaitKm(container);
        // 1 abast, nenhuma manut → kms.length = 1 < 2 → null
        expect(val.value, isNull);
      },
    );

    test(
      'retorna null quando km rodado = 0 (dois pontos com mesmo km)',
      () async {
        final now = DateTime.now();
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 1),
            km: 10000,
            valorTotal: 100.0,
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 2),
            km: 10000,
            valorTotal: 100.0,
          ),
        );

        final val = await _awaitKm(container);
        expect(val.value, isNull);
      },
    );

    test(
      'calcula corretamente: 600 gastos / 1000 km rodado = 0,60/km',
      () async {
        final now = DateTime.now();
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 1),
            km: 10000,
            valorTotal: 300.0,
          ),
        );
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 15),
            km: 11000,
            valorTotal: 300.0,
          ),
        );

        final val = await _awaitKm(container);
        expect(val.value, isNotNull);
        expect(val.value!.custoPorKm, closeTo(0.60, 0.001));
      },
    );

    test('abastecimentos com mais de 12 meses são excluídos', () async {
      final now = DateTime.now();
      // Abastecimento antigo (>12m)
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: now.subtract(const Duration(days: 370)),
          km: 9000,
          valorTotal: 200.0,
        ),
      );
      // Apenas 1 abastecimento recente → sem par → null
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 10),
          km: 11000,
          valorTotal: 300.0,
        ),
      );

      final val = await _awaitKm(container);
      expect(val.value, isNull);
    });

    test('retorna null quando total de gastos = 0', () async {
      final now = DateTime.now();
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 1),
          km: 10000,
          valorTotal: 0.0,
        ),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 2),
          km: 11000,
          valorTotal: 0.0,
        ),
      );

      final val = await _awaitKm(container);
      expect(val.value, isNull);
    });

    test('retorna null quando não há veículo ativo', () async {
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      final container2 = _makeContainer(db2, placa: null);
      addTearDown(() async {
        container2.dispose();
        await db2.close();
      });

      final val = await _awaitKm(container2);
      expect(val.value, isNull);
    });
  });

  // =========================================================================
  // Card 3 — consumo médio km/l (últimos 12 meses, só tanque cheio)
  // =========================================================================

  group('consumoMedioProvider', () {
    test('retorna null quando banco vazio', () async {
      final val = await _awaitConsumo(container);
      expect(val.value, isNull);
    });

    test(
      'retorna null com apenas 1 tanque cheio (< 2 tanques cheios)',
      () async {
        final now = DateTime.now();
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbast(
            data: DateTime(now.year, now.month, 5),
            km: 10000,
            tanqueCheio: true,
          ),
        );

        final val = await _awaitConsumo(container);
        expect(val.value, isNull);
      },
    );

    test('abastecimentos não-cheios são ignorados no cálculo', () async {
      final now = DateTime.now();
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 1),
          km: 10000,
          litros: 50.0,
          tanqueCheio: true,
        ),
      );
      // Parcial — deve ser ignorado
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 8),
          km: 10500,
          litros: 20.0,
          tanqueCheio: false,
        ),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 15),
          km: 11000,
          litros: 40.0,
          tanqueCheio: true,
        ),
      );

      final val = await _awaitConsumo(container);
      expect(val.value, isNotNull);
      // km segmento: 11000 - 10000 = 1000; litros do segundo cheio = 40
      // consumo = 1000 / 40 = 25.0 km/l
      expect(val.value!.kmPorLitro, closeTo(25.0, 0.01));
    });

    test('calcula corretamente com múltiplos tanques cheios', () async {
      final now = DateTime.now();
      // tanque 1: km=10000; tanque 2: km=11000, litros=50; tanque 3: km=11900, litros=45
      // média ponderada = (1000+900)/(50+45) = 1900/95 ≈ 20.0
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 1),
          km: 10000,
          litros: 30.0,
          tanqueCheio: true,
        ),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 10),
          km: 11000,
          litros: 50.0,
          tanqueCheio: true,
        ),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 20),
          km: 11900,
          litros: 45.0,
          tanqueCheio: true,
        ),
      );

      final val = await _awaitConsumo(container);
      expect(val.value, isNotNull);
      expect(val.value!.kmPorLitro, closeTo(1900 / 95, 0.01));
    });

    test('tanques cheios com mais de 12 meses são ignorados', () async {
      final now = DateTime.now();
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: now.subtract(const Duration(days: 400)),
          km: 9000,
          litros: 40.0,
          tanqueCheio: true,
        ),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 5),
          km: 10000,
          litros: 40.0,
          tanqueCheio: true,
        ),
      );

      final val = await _awaitConsumo(container);
      // apenas 1 tanque cheio nos últimos 12m → null
      expect(val.value, isNull);
    });

    test('par com km duplicado (km segmento = 0) resulta em null', () async {
      final now = DateTime.now();
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 1),
          km: 10000,
          litros: 40.0,
          tanqueCheio: true,
        ),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(
          data: DateTime(now.year, now.month, 10),
          km: 10000,
          litros: 40.0,
          tanqueCheio: true,
        ),
      );

      final val = await _awaitConsumo(container);
      // km segmento = 0 → par ignorado → totalLitros = 0 → null
      expect(val.value, isNull);
    });

    test('retorna null quando não há veículo ativo', () async {
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      final container2 = _makeContainer(db2, placa: null);
      addTearDown(() async {
        container2.dispose();
        await db2.close();
      });

      final val = await _awaitConsumo(container2);
      expect(val.value, isNull);
    });
  });

  // =========================================================================
  // Card 4 — próximas manutenções (lembretes pendentes)
  // =========================================================================

  group('proximasManutencoeProvider', () {
    test('retorna lista vazia quando não há lembretes', () async {
      final val = await _awaitManutenco(container);
      expect(val.value, isNotNull);
      expect(val.value!, isEmpty);
    });

    test('retorna no máximo 3 lembretes quando há mais de 3', () async {
      for (var i = 1; i <= 5; i++) {
        await db.lembretesDao.insertLembrete(
          _novoLembrete(
            descricao: 'Lembrete $i',
            dataAlvo: DateTime(2027, i, 1),
          ),
        );
      }

      final val = await _awaitManutenco(container);
      expect(val.value, isNotNull);
      expect(val.value!.length, 3);
    });

    test(
      'os 3 retornados são os de data mais próxima (ordenação ascendente)',
      () async {
        // Insere fora de ordem — o DAO ordena por dataAlvo
        await db.lembretesDao.insertLembrete(
          _novoLembrete(descricao: 'Terceiro', dataAlvo: DateTime(2027, 3, 1)),
        );
        await db.lembretesDao.insertLembrete(
          _novoLembrete(descricao: 'Primeiro', dataAlvo: DateTime(2027, 1, 1)),
        );
        await db.lembretesDao.insertLembrete(
          _novoLembrete(descricao: 'Quinto', dataAlvo: DateTime(2027, 5, 1)),
        );
        await db.lembretesDao.insertLembrete(
          _novoLembrete(descricao: 'Segundo', dataAlvo: DateTime(2027, 2, 1)),
        );

        final val = await _awaitManutenco(container);
        expect(val.value, isNotNull);
        final descricoes = val.value!.map((l) => l.descricao).toList();
        expect(descricoes, ['Primeiro', 'Segundo', 'Terceiro']);
      },
    );

    test('ignora lembretes concluídos e adiados', () async {
      await db.lembretesDao.insertLembrete(
        _novoLembrete(
          descricao: 'Concluído',
          dataAlvo: DateTime(2027, 1, 1),
          status: StatusLembrete.concluido,
        ),
      );
      await db.lembretesDao.insertLembrete(
        _novoLembrete(
          descricao: 'Adiado',
          dataAlvo: DateTime(2027, 1, 2),
          status: StatusLembrete.adiado,
        ),
      );
      await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'Pendente', dataAlvo: DateTime(2027, 1, 3)),
      );

      final val = await _awaitManutenco(container);
      expect(val.value, isNotNull);
      expect(val.value!.length, 1);
      expect(val.value!.first.descricao, 'Pendente');
    });

    test('retorna null quando não há veículo ativo', () async {
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      final container2 = _makeContainer(db2, placa: null);
      addTearDown(() async {
        container2.dispose();
        await db2.close();
      });

      final val = await _awaitManutenco(container2);
      expect(val.value, isNull);
    });
  });
}
