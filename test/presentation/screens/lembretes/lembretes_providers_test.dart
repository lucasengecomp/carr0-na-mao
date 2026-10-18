// ignore_for_file: avoid_print
//
// Testa a lógica de filtragem e ordenação dos providers de lembretes (issue #25,
// bug #68).
//
// Nota de arquitetura: os providers derivados (lembretesPendentesProvider,
// lembretesAtrasadosProvider, lembretesConcluidosProvider) dependem de um
// _todosLembretesProvider privado baseado em Stream do Drift. Testar esses
// providers via ProviderContainer sem UI segurando a assinatura não funciona
// adequadamente (o StreamProvider.future não resolve). Seguimos o mesmo padrão
// documentado em manutencoes_providers_test.dart: testamos o DAO diretamente
// (stream reativo garantido pela camada de persistência) e a lógica de
// filtragem/ordenação usando objetos Lembrete sintéticos.

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

LembretesCompanion _novoLembrete({
  String placa = 'ABC1D23',
  String descricao = 'Trocar palhetas',
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

/// Cria um [Lembrete] sintético sem tocar no banco.
Lembrete _fakeLembrete({
  int id = 1,
  String placa = 'ABC1D23',
  String descricao = 'Descricao',
  DateTime? dataAlvo,
  int? kmAlvo,
  StatusLembrete status = StatusLembrete.pendente,
}) => Lembrete(
  id: id,
  veiculoPlaca: placa,
  manutencaoId: null,
  tipo: 'avulso',
  descricao: descricao,
  dataAlvo: dataAlvo,
  kmAlvo: kmAlvo,
  status: status,
);

// ---------------------------------------------------------------------------
// Replicação das regras de filtro/sort dos providers (sem importar privados)
// ---------------------------------------------------------------------------

/// Início do dia de hoje — mesma lógica usada pelos providers.
DateTime get _inicioDia {
  final hoje = DateTime.now();
  return DateTime(hoje.year, hoje.month, hoje.day);
}

/// Replica a lógica de _isAtrasado do provider (issue #68):
///   status == pendente E
///   (dataAlvo < hoje OU (kmAlvo != null E kmAtual > kmAlvo))
bool _isAtrasado(Lembrete l, Map<String, int> kmAtualPorPlaca) {
  if (l.status != StatusLembrete.pendente) return false;
  final atrasadoPorData =
      l.dataAlvo != null && l.dataAlvo!.isBefore(_inicioDia);
  final kmAtual = kmAtualPorPlaca[l.veiculoPlaca];
  final atrasadoPorKm =
      l.kmAlvo != null && kmAtual != null && kmAtual > l.kmAlvo!;
  return atrasadoPorData || atrasadoPorKm;
}

/// Replica a lógica de _isPendente do provider:
///   status == pendente E NÃO atrasado.
bool _isPendente(Lembrete l, Map<String, int> kmAtualPorPlaca) {
  return l.status == StatusLembrete.pendente &&
      !_isAtrasado(l, kmAtualPorPlaca);
}

bool _isConcluido(Lembrete l) {
  return l.status == StatusLembrete.concluido ||
      l.status == StatusLembrete.adiado;
}

int _sortPendentes(Lembrete a, Lembrete b) {
  if (a.dataAlvo != null && b.dataAlvo != null) {
    return a.dataAlvo!.compareTo(b.dataAlvo!);
  }
  if (a.dataAlvo != null) return -1;
  if (b.dataAlvo != null) return 1;
  final aKm = a.kmAlvo ?? 0;
  final bKm = b.kmAlvo ?? 0;
  return aKm.compareTo(bKm);
}

int _sortAtrasados(Lembrete a, Lembrete b) {
  if (a.dataAlvo != null && b.dataAlvo != null) {
    return a.dataAlvo!.compareTo(b.dataAlvo!);
  }
  return 0;
}

int _sortConcluidos(Lembrete a, Lembrete b) {
  if (a.dataAlvo != null && b.dataAlvo != null) {
    return b.dataAlvo!.compareTo(a.dataAlvo!);
  }
  if (a.dataAlvo != null) return -1;
  if (b.dataAlvo != null) return 1;
  return 0;
}

/// Datas fixas absolutas (não dependem de DateTime.now() diretamente
/// mas são extremas o suficiente para não sofrerem com drift de data).
final _dataFutura = DateTime(2030, 6, 1);
final _dataFuturaMaisDistante = DateTime(2031, 1, 1);
final _dataPassada = DateTime(2020, 1, 1);
final _dataPassadaMaisAntiga = DateTime(2019, 1, 1);

/// Km mapa vazio — nenhum veículo tem abastecimento registrado.
const _semKm = <String, int>{};

void main() {
  late AppDatabase db;

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
  });

  tearDown(() async {
    await db.close();
  });

  // -------------------------------------------------------------------------
  // Lógica de filtragem — _isAtrasado (critério por data)
  // -------------------------------------------------------------------------
  group('filtro atrasado por data (_isAtrasado)', () {
    test('pendente com dataAlvo no passado → true', () {
      expect(
        _isAtrasado(_fakeLembrete(dataAlvo: _dataPassada), _semKm),
        isTrue,
      );
    });

    test('pendente com dataAlvo nula (só km) e sem abastecimento → false', () {
      expect(_isAtrasado(_fakeLembrete(kmAlvo: 50000), _semKm), isFalse);
    });

    test('pendente com dataAlvo futura → false', () {
      expect(
        _isAtrasado(_fakeLembrete(dataAlvo: _dataFutura), _semKm),
        isFalse,
      );
    });

    test('concluído com dataAlvo no passado → false', () {
      expect(
        _isAtrasado(
          _fakeLembrete(
            dataAlvo: _dataPassada,
            status: StatusLembrete.concluido,
          ),
          _semKm,
        ),
        isFalse,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Lógica de filtragem — _isAtrasado (critério por km — bug #68)
  // -------------------------------------------------------------------------
  group('filtro atrasado por km (_isAtrasado, bug #68)', () {
    test('kmAtual > kmAlvo → atrasado', () {
      final l = _fakeLembrete(placa: 'ABC1D23', kmAlvo: 20000);
      expect(_isAtrasado(l, {'ABC1D23': 25000}), isTrue);
    });

    test(
      'kmAtual == kmAlvo → NÃO atrasado (critério é estritamente maior)',
      () {
        final l = _fakeLembrete(placa: 'ABC1D23', kmAlvo: 20000);
        expect(_isAtrasado(l, {'ABC1D23': 20000}), isFalse);
      },
    );

    test('kmAtual < kmAlvo → não atrasado', () {
      final l = _fakeLembrete(placa: 'ABC1D23', kmAlvo: 20000);
      expect(_isAtrasado(l, {'ABC1D23': 15000}), isFalse);
    });

    test('placa não está no mapa (sem abastecimento) → não atrasado', () {
      final l = _fakeLembrete(placa: 'ABC1D23', kmAlvo: 20000);
      expect(_isAtrasado(l, {'XYZ9Z99': 25000}), isFalse);
    });

    test('kmAlvo é nulo, mesmo com kmAtual alto → não atrasado por km', () {
      final l = _fakeLembrete(placa: 'ABC1D23', dataAlvo: _dataFutura);
      expect(_isAtrasado(l, {'ABC1D23': 999999}), isFalse);
    });

    test('concluído com kmAtual > kmAlvo → false (status não é pendente)', () {
      final l = _fakeLembrete(
        placa: 'ABC1D23',
        kmAlvo: 20000,
        status: StatusLembrete.concluido,
      );
      expect(_isAtrasado(l, {'ABC1D23': 25000}), isFalse);
    });

    test(
      'lembrete com dataAlvo futura e kmAtual > kmAlvo → atrasado por km',
      () {
        final l = _fakeLembrete(
          placa: 'ABC1D23',
          dataAlvo: _dataFutura,
          kmAlvo: 20000,
        );
        expect(_isAtrasado(l, {'ABC1D23': 25000}), isTrue);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Lógica de filtragem — _isPendente com km
  // -------------------------------------------------------------------------
  group('filtro pendente com km (_isPendente)', () {
    test('pendente com dataAlvo futura, sem km atrasado → pendente', () {
      expect(_isPendente(_fakeLembrete(dataAlvo: _dataFutura), _semKm), isTrue);
    });

    test('pendente com dataAlvo nula e kmAtual < kmAlvo → pendente', () {
      final l = _fakeLembrete(placa: 'ABC1D23', kmAlvo: 50000);
      expect(_isPendente(l, {'ABC1D23': 30000}), isTrue);
    });

    test('pendente com kmAtual > kmAlvo → NÃO pendente (é atrasado)', () {
      final l = _fakeLembrete(placa: 'ABC1D23', kmAlvo: 20000);
      expect(_isPendente(l, {'ABC1D23': 25000}), isFalse);
    });

    test('pendente com dataAlvo no passado → não pendente (é atrasado)', () {
      expect(
        _isPendente(_fakeLembrete(dataAlvo: _dataPassada), _semKm),
        isFalse,
      );
    });

    test('concluído com dataAlvo futura → false', () {
      expect(
        _isPendente(
          _fakeLembrete(
            dataAlvo: _dataFutura,
            status: StatusLembrete.concluido,
          ),
          _semKm,
        ),
        isFalse,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Lógica de filtragem — _isConcluido
  // -------------------------------------------------------------------------
  group('filtro concluido (_isConcluido)', () {
    test('status=concluido → true', () {
      expect(
        _isConcluido(
          _fakeLembrete(
            dataAlvo: _dataPassada,
            status: StatusLembrete.concluido,
          ),
        ),
        isTrue,
      );
    });

    test('status=adiado → true', () {
      expect(
        _isConcluido(
          _fakeLembrete(dataAlvo: _dataFutura, status: StatusLembrete.adiado),
        ),
        isTrue,
      );
    });

    test('status=pendente → false', () {
      expect(_isConcluido(_fakeLembrete(dataAlvo: _dataFutura)), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Separação mútua entre os três filtros
  // -------------------------------------------------------------------------
  group('separação mútua dos filtros', () {
    test('pendente futuro (sem km): só isPendente', () {
      final l = _fakeLembrete(dataAlvo: _dataFutura);
      expect(_isPendente(l, _semKm), isTrue);
      expect(_isAtrasado(l, _semKm), isFalse);
      expect(_isConcluido(l), isFalse);
    });

    test('pendente passado: só isAtrasado', () {
      final l = _fakeLembrete(dataAlvo: _dataPassada);
      expect(_isPendente(l, _semKm), isFalse);
      expect(_isAtrasado(l, _semKm), isTrue);
      expect(_isConcluido(l), isFalse);
    });

    test('concluído: só isConcluido', () {
      final l = _fakeLembrete(
        dataAlvo: _dataPassada,
        status: StatusLembrete.concluido,
      );
      expect(_isPendente(l, _semKm), isFalse);
      expect(_isAtrasado(l, _semKm), isFalse);
      expect(_isConcluido(l), isTrue);
    });

    test('adiado: só isConcluido', () {
      final l = _fakeLembrete(
        dataAlvo: _dataFutura,
        status: StatusLembrete.adiado,
      );
      expect(_isPendente(l, _semKm), isFalse);
      expect(_isAtrasado(l, _semKm), isFalse);
      expect(_isConcluido(l), isTrue);
    });

    test('pendente sem data e sem km atrasado: só isPendente', () {
      final l = _fakeLembrete(kmAlvo: 50000);
      expect(_isPendente(l, _semKm), isTrue);
      expect(_isAtrasado(l, _semKm), isFalse);
      expect(_isConcluido(l), isFalse);
    });

    test('pendente com km ultrapassado: só isAtrasado (bug #68)', () {
      final l = _fakeLembrete(placa: 'ABC1D23', kmAlvo: 20000);
      final kmMap = {'ABC1D23': 25000};
      expect(_isPendente(l, kmMap), isFalse);
      expect(_isAtrasado(l, kmMap), isTrue);
      expect(_isConcluido(l), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Ordenação _sortPendentes
  // -------------------------------------------------------------------------
  group('_sortPendentes', () {
    test('data anterior vem antes de data posterior', () {
      final a = _fakeLembrete(id: 1, dataAlvo: _dataFutura);
      final b = _fakeLembrete(id: 2, dataAlvo: _dataFuturaMaisDistante);
      expect(_sortPendentes(a, b), isNegative);
      expect(_sortPendentes(b, a), isPositive);
    });

    test('item com data vem antes de item sem data', () {
      final comData = _fakeLembrete(id: 1, dataAlvo: _dataFutura);
      final semData = _fakeLembrete(id: 2, kmAlvo: 10000);
      expect(_sortPendentes(comData, semData), isNegative);
      expect(_sortPendentes(semData, comData), isPositive);
    });

    test('dois sem data: km menor vem antes de km maior', () {
      final a = _fakeLembrete(id: 1, kmAlvo: 10000);
      final b = _fakeLembrete(id: 2, kmAlvo: 50000);
      expect(_sortPendentes(a, b), isNegative);
      expect(_sortPendentes(b, a), isPositive);
    });

    test('dois sem data nem km: ordem indiferente (zero)', () {
      // kmAlvo nullable; sem data nem km → ambos têm km=0 no sort
      final a = _fakeLembrete(id: 1, kmAlvo: 0);
      final b = _fakeLembrete(id: 2, kmAlvo: 0);
      expect(_sortPendentes(a, b), isZero);
    });

    test('sorted: lista misturada é reordenada corretamente', () {
      final lista = [
        _fakeLembrete(id: 3, kmAlvo: 5000),
        _fakeLembrete(id: 1, dataAlvo: _dataFutura),
        _fakeLembrete(id: 2, dataAlvo: _dataFuturaMaisDistante),
      ]..sort(_sortPendentes);

      expect(lista[0].dataAlvo, _dataFutura);
      expect(lista[1].dataAlvo, _dataFuturaMaisDistante);
      expect(lista[2].kmAlvo, 5000);
    });
  });

  // -------------------------------------------------------------------------
  // Ordenação _sortAtrasados
  // -------------------------------------------------------------------------
  group('_sortAtrasados', () {
    test('data mais antiga (mais atrasada) vem primeiro', () {
      final a = _fakeLembrete(id: 1, dataAlvo: _dataPassadaMaisAntiga);
      final b = _fakeLembrete(id: 2, dataAlvo: _dataPassada);
      expect(_sortAtrasados(a, b), isNegative);
      expect(_sortAtrasados(b, a), isPositive);
    });

    test('mesma data → zero', () {
      final a = _fakeLembrete(id: 1, dataAlvo: _dataPassada);
      final b = _fakeLembrete(id: 2, dataAlvo: _dataPassada);
      expect(_sortAtrasados(a, b), isZero);
    });
  });

  // -------------------------------------------------------------------------
  // Ordenação _sortConcluidos
  // -------------------------------------------------------------------------
  group('_sortConcluidos', () {
    test('data mais recente vem primeiro (desc)', () {
      final a = _fakeLembrete(id: 1, dataAlvo: _dataPassada);
      final b = _fakeLembrete(id: 2, dataAlvo: _dataPassadaMaisAntiga);
      expect(_sortConcluidos(a, b), isNegative); // a (mais recente) < b
      expect(_sortConcluidos(b, a), isPositive);
    });

    test('com data vem antes de sem data', () {
      final comData = _fakeLembrete(id: 1, dataAlvo: _dataPassada);
      final semData = _fakeLembrete(id: 2, kmAlvo: 10000);
      expect(_sortConcluidos(comData, semData), isNegative);
    });

    test('sem data, sem data → zero', () {
      final a = _fakeLembrete(id: 1, kmAlvo: 10000);
      final b = _fakeLembrete(id: 2, kmAlvo: 20000);
      expect(_sortConcluidos(a, b), isZero);
    });
  });

  // -------------------------------------------------------------------------
  // Integração com banco: watchAll emite dados que os filtros processariam
  // -------------------------------------------------------------------------
  group('watchAll + filtros (integração banco)', () {
    test('banco vazio → todos os filtros retornam lista vazia', () async {
      final lista = await db.lembretesDao.watchAll().first;
      expect(lista.where((l) => _isPendente(l, _semKm)).toList(), isEmpty);
      expect(lista.where((l) => _isAtrasado(l, _semKm)).toList(), isEmpty);
      expect(lista.where(_isConcluido).toList(), isEmpty);
    });

    test('banco com 3 lembretes (futuro, passado, concluído) → cada filtro pega um', () async {
      await db.lembretesDao.insertLembrete(
        _novoLembrete(dataAlvo: _dataFutura, descricao: 'Futuro'),
      );
      await db.lembretesDao.insertLembrete(
        _novoLembrete(dataAlvo: _dataPassada, descricao: 'Passado'),
      );
      final idC = await db.lembretesDao.insertLembrete(
        _novoLembrete(dataAlvo: _dataPassadaMaisAntiga, descricao: 'Concluído'),
      );
      await db.lembretesDao.marcarConcluido(idC);

      final lista = await db.lembretesDao.watchAll().first;

      final pendentes = lista.where((l) => _isPendente(l, _semKm)).toList();
      final atrasados = lista.where((l) => _isAtrasado(l, _semKm)).toList();
      final concluidos = lista.where(_isConcluido).toList();

      expect(pendentes.map((l) => l.descricao), ['Futuro']);
      expect(atrasados.map((l) => l.descricao), ['Passado']);
      expect(concluidos.map((l) => l.descricao), ['Concluído']);
    });

    test(
      'pendente sem data (só km) aparece em pendentes quando kmAtual < kmAlvo',
      () async {
        await db.lembretesDao.insertLembrete(
          _novoLembrete(kmAlvo: 50000, descricao: 'Só km'),
        );
        // Veículo com km atual = 30000 (abaixo do alvo)
        final kmMap = {'ABC1D23': 30000};

        final lista = await db.lembretesDao.watchAll().first;

        expect(
          lista
              .where((l) => _isPendente(l, kmMap))
              .any((l) => l.descricao == 'Só km'),
          isTrue,
        );
        expect(
          lista
              .where((l) => _isAtrasado(l, kmMap))
              .any((l) => l.descricao == 'Só km'),
          isFalse,
        );
      },
    );

    test(
      // Bug #68: lembrete com kmAlvo=20000 e kmAtual=25000 → Atrasados
      'pendente com kmAlvo ultrapassado aparece em atrasados, não em pendentes',
      () async {
        await db.lembretesDao.insertLembrete(
          _novoLembrete(kmAlvo: 20000, descricao: 'Km ultrapassado'),
        );
        // Veículo já com 25000 km
        final kmMap = {'ABC1D23': 25000};

        final lista = await db.lembretesDao.watchAll().first;

        expect(
          lista
              .where((l) => _isAtrasado(l, kmMap))
              .any((l) => l.descricao == 'Km ultrapassado'),
          isTrue,
          reason: 'lembrete com kmAtual > kmAlvo deve estar em Atrasados',
        );
        expect(
          lista
              .where((l) => _isPendente(l, kmMap))
              .any((l) => l.descricao == 'Km ultrapassado'),
          isFalse,
          reason: 'lembrete com kmAtual > kmAlvo NÃO deve estar em Pendentes',
        );
      },
    );

    test(
      'após marcarConcluido, lembrete migra de atrasado para concluído',
      () async {
        final id = await db.lembretesDao.insertLembrete(
          _novoLembrete(dataAlvo: _dataPassada, descricao: 'MigrandoConcluido'),
        );

        // Antes da conclusão
        var lista = await db.lembretesDao.watchAll().first;
        expect(
          lista
              .where((l) => _isAtrasado(l, _semKm))
              .any((l) => l.descricao == 'MigrandoConcluido'),
          isTrue,
        );
        expect(
          lista
              .where(_isConcluido)
              .any((l) => l.descricao == 'MigrandoConcluido'),
          isFalse,
        );

        await db.lembretesDao.marcarConcluido(id);

        // Após a conclusão
        lista = await db.lembretesDao.watchAll().first;
        expect(
          lista
              .where((l) => _isAtrasado(l, _semKm))
              .any((l) => l.descricao == 'MigrandoConcluido'),
          isFalse,
        );
        expect(
          lista
              .where(_isConcluido)
              .any((l) => l.descricao == 'MigrandoConcluido'),
          isTrue,
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // kmAtualPorVeiculo — lógica de construção do mapa
  // -------------------------------------------------------------------------
  group('mapa de km atual por veículo (lógica local)', () {
    test('lista vazia → mapa vazio', () {
      final mapa = _buildKmMap([]);
      expect(mapa, isEmpty);
    });

    test('um abastecimento → km daquele veículo', () {
      final mapa = _buildKmMap([
        _fakeAbastecimento(placa: 'ABC1D23', km: 15000),
      ]);
      expect(mapa['ABC1D23'], 15000);
    });

    test('dois abastecimentos mesmo veículo → km maior vence', () {
      final mapa = _buildKmMap([
        _fakeAbastecimento(placa: 'ABC1D23', km: 15000),
        _fakeAbastecimento(placa: 'ABC1D23', km: 20000),
      ]);
      expect(mapa['ABC1D23'], 20000);
    });

    test('dois veículos distintos → mapa com dois entries', () {
      final mapa = _buildKmMap([
        _fakeAbastecimento(placa: 'ABC1D23', km: 10000),
        _fakeAbastecimento(placa: 'XYZ9Z99', km: 50000),
      ]);
      expect(mapa['ABC1D23'], 10000);
      expect(mapa['XYZ9Z99'], 50000);
    });
  });

  // -------------------------------------------------------------------------
  // Integração banco: abastecimentosDao.watchAll e mapa de km
  // -------------------------------------------------------------------------
  group('AbastecimentosDao.watchAll → mapa de km (integração banco)', () {
    setUp(() async {
      // Segundo veículo para testar múltiplas placas
      await db.veiculosDao.insertVeiculo(
        VeiculosCompanion.insert(
          placa: 'XYZ9Z99',
          marca: 'VW',
          modelo: 'Gol',
          ano: 2019,
          tipo: TipoVeiculo.carro,
          combustivel: TipoCombustivelVeiculo.flex,
          kmInicial: 5000,
        ),
      );
    });

    test('sem abastecimentos → mapa vazio', () async {
      final lista = await db.abastecimentosDao.watchAll().first;
      expect(_buildKmMap(lista), isEmpty);
    });

    test('abastecimento inserido → mapa reflete km', () async {
      await db.abastecimentosDao.insertAbastecimento(
        _novoAbastecimento(placa: 'ABC1D23', km: 25000),
      );
      final lista = await db.abastecimentosDao.watchAll().first;
      expect(_buildKmMap(lista)['ABC1D23'], 25000);
    });

    test(
      // Bug #68 end-to-end: lembrete com kmAlvo=20000, veículo com km=25000
      'lembrete com kmAlvo<kmAtual classificado como atrasado via banco',
      () async {
        // Registra abastecimento que ultrapassa kmAlvo do lembrete
        await db.abastecimentosDao.insertAbastecimento(
          _novoAbastecimento(placa: 'ABC1D23', km: 25000),
        );
        await db.lembretesDao.insertLembrete(
          _novoLembrete(kmAlvo: 20000, descricao: 'Revisão km vencida'),
        );

        final abastecimentos = await db.abastecimentosDao.watchAll().first;
        final lembretes = await db.lembretesDao.watchAll().first;
        final kmMap = _buildKmMap(abastecimentos);

        final atrasados = lembretes.where((l) => _isAtrasado(l, kmMap));
        final pendentes = lembretes.where((l) => _isPendente(l, kmMap));

        expect(
          atrasados.any((l) => l.descricao == 'Revisão km vencida'),
          isTrue,
          reason: 'deve aparecer em Atrasados',
        );
        expect(
          pendentes.any((l) => l.descricao == 'Revisão km vencida'),
          isFalse,
          reason: 'não deve aparecer em Pendentes',
        );
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Helpers para construção do mapa de km e objetos Abastecimento fake
// ---------------------------------------------------------------------------

/// Replica a lógica do `kmAtualPorVeiculoProvider` (maior km por placa).
Map<String, int> _buildKmMap(List<Abastecimento> lista) {
  final mapa = <String, int>{};
  for (final a in lista) {
    final atual = mapa[a.veiculoPlaca];
    if (atual == null || a.km > atual) {
      mapa[a.veiculoPlaca] = a.km;
    }
  }
  return mapa;
}

/// Cria um Abastecimento fake sem persistência.
Abastecimento _fakeAbastecimento({
  int id = 1,
  required String placa,
  required int km,
}) => Abastecimento(
  id: id,
  veiculoPlaca: placa,
  data: DateTime(2024, 1, 1),
  km: km,
  tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
  precoLitro: 5.5,
  valorTotal: 55.0,
  litros: 10.0,
  posto: null,
  tanqueCheio: true,
);

/// Companion para inserção no banco.
AbastecimentosCompanion _novoAbastecimento({
  required String placa,
  required int km,
}) => AbastecimentosCompanion.insert(
  veiculoPlaca: placa,
  data: DateTime(2024, 1, 1),
  km: km,
  tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
  precoLitro: 5.5,
  valorTotal: 55.0,
  litros: 10.0,
);
