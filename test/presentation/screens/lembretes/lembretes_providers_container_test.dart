// Testes que exercem os providers reais de lembretes via ProviderContainer,
// garantindo cobertura das funções de sort/filter definidas no arquivo fonte
// (linhas 118-147 de lembretes_providers.dart — não cobertas pelos testes
// de lógica pura que replicam as funções localmente).
//
// Estratégia: usamos ProviderContainer com AppDatabase em memória e
// esperamos pelo primeiro evento não-loading dos providers derivados.

import 'dart:async';

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/data/providers.dart';
import 'package:carro_na_mao/presentation/screens/lembretes/lembretes_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

LembretesCompanion _novoLembrete({
  String placa = 'ABC1D23',
  String descricao = 'Lembrete',
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

AbastecimentosCompanion _novoAbast({
  String placa = 'ABC1D23',
  required int km,
}) => AbastecimentosCompanion.insert(
  veiculoPlaca: placa,
  data: DateTime(2026, 1, 1),
  km: km,
  tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
  precoLitro: 5.5,
  valorTotal: 55.0,
  litros: 10.0,
);

ProviderContainer _makeContainer(AppDatabase db) =>
    ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);

/// Aguarda o primeiro valor non-loading de [lembretesPendentesProvider].
Future<AsyncValue<List<Lembrete>>> _awaitPendentes(ProviderContainer c) async {
  final completer = Completer<AsyncValue<List<Lembrete>>>();
  final sub = c.listen<AsyncValue<List<Lembrete>>>(lembretesPendentesProvider, (
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

/// Aguarda o primeiro valor non-loading de [lembretesAtrasadosProvider].
Future<AsyncValue<List<Lembrete>>> _awaitAtrasados(ProviderContainer c) async {
  final completer = Completer<AsyncValue<List<Lembrete>>>();
  final sub = c.listen<AsyncValue<List<Lembrete>>>(lembretesAtrasadosProvider, (
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

/// Aguarda o primeiro valor non-loading de [lembretesConcluidosProvider].
Future<AsyncValue<List<Lembrete>>> _awaitConcluidos(ProviderContainer c) async {
  final completer = Completer<AsyncValue<List<Lembrete>>>();
  final sub = c.listen<AsyncValue<List<Lembrete>>>(
    lembretesConcluidosProvider,
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

/// Aguarda o primeiro valor non-loading de [kmAtualPorVeiculoProvider].
Future<AsyncValue<Map<String, int>>> _awaitKmMap(ProviderContainer c) async {
  final completer = Completer<AsyncValue<Map<String, int>>>();
  final sub = c.listen<AsyncValue<Map<String, int>>>(
    kmAtualPorVeiculoProvider,
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
    await db.veiculosDao.insertVeiculo(
      VeiculosCompanion.insert(
        placa: 'ABC1D23',
        marca: 'Fiat',
        modelo: 'Uno',
        ano: 2020,
        tipo: TipoVeiculo.carro,
        combustivel: TipoCombustivelVeiculo.flex,
        kmInicial: 10000,
      ),
    );
    container = _makeContainer(db);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // kmAtualPorVeiculoProvider — mapa de km atual derivado de abastecimentos
  // ──────────────────────────────────────────────────────────────────────────

  group('kmAtualPorVeiculoProvider', () {
    test('sem abastecimentos → mapa vazio', () async {
      final val = await _awaitKmMap(container);
      expect(val.value, isNotNull);
      expect(val.value!, isEmpty);
    });

    test('com abastecimentos → km máximo por placa', () async {
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 15000),
      );
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 20000),
      );
      final val = await _awaitKmMap(container);
      expect(val.value!['ABC1D23'], 20000);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // lembretesPendentesProvider — sort e filtro via provider real (#33 seção 9.4)
  // ──────────────────────────────────────────────────────────────────────────

  group('lembretesPendentesProvider via ProviderContainer', () {
    test('banco vazio → lista vazia', () async {
      final val = await _awaitPendentes(container);
      expect(val.value, isNotNull);
      expect(val.value!, isEmpty);
    });

    test('lembrete com data futura aparece como pendente', () async {
      await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'Futuro', dataAlvo: DateTime(2030, 6, 1)),
      );
      final val = await _awaitPendentes(container);
      expect(val.value!.any((l) => l.descricao == 'Futuro'), isTrue);
    });

    test(
      'lembrete com data passada NÃO aparece como pendente (é atrasado)',
      () async {
        await db.lembretesDao.insertLembrete(
          _novoLembrete(descricao: 'Passado', dataAlvo: DateTime(2020, 1, 1)),
        );
        final val = await _awaitPendentes(container);
        expect(val.value!.any((l) => l.descricao == 'Passado'), isFalse);
      },
    );

    // Cobre _sortPendentes: dois com data → ordena por data asc
    test(
      'ordena pendentes por data asc (com data antes de sem data)',
      () async {
        await db.lembretesDao.insertLembrete(
          _novoLembrete(
            descricao: 'Data Distante',
            dataAlvo: DateTime(2031, 1, 1),
          ),
        );
        await db.lembretesDao.insertLembrete(
          _novoLembrete(
            descricao: 'Data Proxima',
            dataAlvo: DateTime(2030, 1, 1),
          ),
        );
        await db.lembretesDao.insertLembrete(
          _novoLembrete(descricao: 'So Km', kmAlvo: 99999),
        );

        final val = await _awaitPendentes(container);
        final nomes = val.value!.map((l) => l.descricao).toList();
        // Com data vêm antes de sem data; mais próxima vem primeiro
        expect(
          nomes.indexOf('Data Proxima'),
          lessThan(nomes.indexOf('Data Distante')),
        );
        expect(
          nomes.indexOf('Data Distante'),
          lessThan(nomes.indexOf('So Km')),
        );
      },
    );

    // Cobre _sortPendentes: dois sem data → ordena por km asc
    test('sem data ordena por kmAlvo asc', () async {
      await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'Km Alto', kmAlvo: 80000),
      );
      await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'Km Baixo', kmAlvo: 20000),
      );

      final val = await _awaitPendentes(container);
      final nomes = val.value!.map((l) => l.descricao).toList();
      expect(nomes.indexOf('Km Baixo'), lessThan(nomes.indexOf('Km Alto')));
    });

    test('lembrete com km ultrapassado NÃO aparece em pendentes', () async {
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 25000),
      );
      await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'KmVencido', kmAlvo: 20000),
      );
      final val = await _awaitPendentes(container);
      expect(val.value!.any((l) => l.descricao == 'KmVencido'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // lembretesAtrasadosProvider — sort e filtro via provider real
  // ──────────────────────────────────────────────────────────────────────────

  group('lembretesAtrasadosProvider via ProviderContainer', () {
    test('banco vazio → lista vazia', () async {
      final val = await _awaitAtrasados(container);
      expect(val.value, isNotNull);
      expect(val.value!, isEmpty);
    });

    test('lembrete com data passada aparece como atrasado', () async {
      await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'Passado', dataAlvo: DateTime(2020, 1, 1)),
      );
      final val = await _awaitAtrasados(container);
      expect(val.value!.any((l) => l.descricao == 'Passado'), isTrue);
    });

    test('lembrete com km ultrapassado aparece como atrasado', () async {
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 30000),
      );
      await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'KmAtrasado', kmAlvo: 20000),
      );
      final val = await _awaitAtrasados(container);
      expect(val.value!.any((l) => l.descricao == 'KmAtrasado'), isTrue);
    });

    // Cobre _sortAtrasados: dois com data → mais antiga (mais atrasada) primeiro
    test('ordena atrasados: data mais antiga primeiro', () async {
      await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'MaisRecente', dataAlvo: DateTime(2019, 6, 1)),
      );
      await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'MaisAntigo', dataAlvo: DateTime(2018, 1, 1)),
      );
      final val = await _awaitAtrasados(container);
      final nomes = val.value!.map((l) => l.descricao).toList();
      expect(
        nomes.indexOf('MaisAntigo'),
        lessThan(nomes.indexOf('MaisRecente')),
      );
    });

    // Cobre _sortAtrasados: dois sem data → retorno 0 (ordem estável)
    test('atrasados sem data mantidos em alguma ordem', () async {
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbast(placa: 'ABC1D23', km: 99000),
      );
      await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'SemData1', kmAlvo: 50000),
      );
      await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'SemData2', kmAlvo: 60000),
      );
      final val = await _awaitAtrasados(container);
      // Apenas verifica que ambos aparecem
      final nomes = val.value!.map((l) => l.descricao).toList();
      expect(nomes, containsAll(['SemData1', 'SemData2']));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // lembretesConcluidosProvider — sort e filtro via provider real
  // ──────────────────────────────────────────────────────────────────────────

  group('lembretesConcluidosProvider via ProviderContainer', () {
    test('banco vazio → lista vazia', () async {
      final val = await _awaitConcluidos(container);
      expect(val.value, isNotNull);
      expect(val.value!, isEmpty);
    });

    test('lembrete concluído aparece na lista', () async {
      final id = await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'Concluido', dataAlvo: DateTime(2026, 1, 1)),
      );
      await db.lembretesDao.marcarConcluido(id);
      final val = await _awaitConcluidos(container);
      expect(val.value!.any((l) => l.descricao == 'Concluido'), isTrue);
    });

    // issue #116: lembrete adiado NÃO aparece em concluídos — vai para pendentes.
    test(
      'lembrete adiado NÃO aparece na lista de concluídos (issue #116)',
      () async {
        final id = await db.lembretesDao.insertLembrete(
          _novoLembrete(descricao: 'Adiado', dataAlvo: DateTime(2030, 1, 1)),
        );
        await db.lembretesDao.adiar(id, novaData: DateTime(2031, 1, 1));
        final val = await _awaitConcluidos(container);
        expect(val.value!.any((l) => l.descricao == 'Adiado'), isFalse);
      },
    );

    // issue #116: lembrete adiado com data futura aparece em pendentes.
    test(
      'lembrete adiado com data futura aparece em pendentes (issue #116)',
      () async {
        final id = await db.lembretesDao.insertLembrete(
          _novoLembrete(descricao: 'Adiado', dataAlvo: DateTime(2030, 1, 1)),
        );
        await db.lembretesDao.adiar(id, novaData: DateTime(2031, 1, 1));
        final val = await _awaitPendentes(container);
        expect(val.value!.any((l) => l.descricao == 'Adiado'), isTrue);
      },
    );

    // Cobre _sortConcluidos: dois com data → mais recente (maior data) primeiro
    test('ordena concluídos por data desc (mais recente primeiro)', () async {
      final id1 = await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'MaisAntigo', dataAlvo: DateTime(2023, 1, 1)),
      );
      await db.lembretesDao.marcarConcluido(id1);
      final id2 = await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'MaisRecente', dataAlvo: DateTime(2024, 1, 1)),
      );
      await db.lembretesDao.marcarConcluido(id2);

      final val = await _awaitConcluidos(container);
      final nomes = val.value!.map((l) => l.descricao).toList();
      // MaisRecente deve vir antes de MaisAntigo
      expect(
        nomes.indexOf('MaisRecente'),
        lessThan(nomes.indexOf('MaisAntigo')),
      );
    });

    // Cobre _sortConcluidos: com data antes de sem data
    test('com data vem antes de sem data em concluídos', () async {
      final idSemData = await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'SemData', kmAlvo: 10000),
      );
      await db.lembretesDao.marcarConcluido(idSemData);
      final idComData = await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'ComData', dataAlvo: DateTime(2024, 6, 1)),
      );
      await db.lembretesDao.marcarConcluido(idComData);

      final val = await _awaitConcluidos(container);
      final nomes = val.value!.map((l) => l.descricao).toList();
      expect(nomes.indexOf('ComData'), lessThan(nomes.indexOf('SemData')));
    });

    // Cobre _sortConcluidos: sem data, sem data → retorna 0 (sem crash)
    test('dois concluídos sem data — sem crash, ambos na lista', () async {
      final id1 = await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'SemDataA', kmAlvo: 10000),
      );
      final id2 = await db.lembretesDao.insertLembrete(
        _novoLembrete(descricao: 'SemDataB', kmAlvo: 20000),
      );
      await db.lembretesDao.marcarConcluido(id1);
      await db.lembretesDao.marcarConcluido(id2);

      final val = await _awaitConcluidos(container);
      final nomes = val.value!.map((l) => l.descricao).toList();
      expect(nomes, containsAll(['SemDataA', 'SemDataB']));
    });
  });
}
