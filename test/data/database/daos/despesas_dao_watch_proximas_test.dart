// ignore_for_file: lines_longer_than_80_chars

import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _seedVeiculo(AppDatabase db, {String placa = 'ABC1D23'}) =>
    db.veiculosDao.insertVeiculo(
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

Future<int> _seedDespesa(
  AppDatabase db, {
  String placa = 'ABC1D23',
  String nome = 'Estacionamento',
  double valor = 100,
}) => db.despesasRecorrentesDao.insertDespesa(
  DespesasRecorrentesCompanion.insert(
    veiculoPlaca: placa,
    nome: nome,
    categoria: CategoriaDespesa.estacionamento,
    valor: valor,
    frequencia: FrequenciaDespesa.mensal,
    dataInicio: DateTime(2026, 1, 1),
  ),
);

Future<int> _seedOcorrencia(
  AppDatabase db, {
  required int despesaId,
  required DateTime vencimento,
  StatusOcorrencia status = StatusOcorrencia.pendente,
  double? valorPago,
  DateTime? dataPagamento,
}) async {
  final id = await db.ocorrenciasDespesaDao.insertOcorrencia(
    OcorrenciasDespesaCompanion.insert(
      despesaId: despesaId,
      dataVencimento: vencimento,
      status: status,
    ),
  );
  if (status == StatusOcorrencia.paga && valorPago != null) {
    await db.ocorrenciasDespesaDao.marcarPaga(
      id,
      valorPago: valorPago,
      dataPagamento: dataPagamento ?? vencimento,
    );
  } else if (status == StatusOcorrencia.pulada) {
    await db.ocorrenciasDespesaDao.marcarPulada(id);
  }
  return id;
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _seedVeiculo(db);
  });

  tearDown(() async {
    await db.close();
  });

  // -------------------------------------------------------------------------
  // watchProximasByVeiculo
  // -------------------------------------------------------------------------
  group('watchProximasByVeiculo', () {
    test('retorna pendentes independente da data de vencimento', () async {
      final despesaId = await _seedDespesa(db);

      // pendente futura
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2099, 12, 31),
      );
      // pendente passada (vencida)
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2000, 1, 1),
      );

      final stream = db.ocorrenciasDespesaDao.watchProximasByVeiculo('ABC1D23');
      final lista = await stream.first;

      expect(lista, hasLength(2));
      expect(lista.every((o) => o.status == StatusOcorrencia.pendente), isTrue);
    });

    test(
      'retorna pagas dos últimos 90 dias; exclui pagas com mais de 90 dias',
      () async {
        final despesaId = await _seedDespesa(db);
        final hoje = DateTime.now();

        // Paga há 30 dias — deve aparecer
        final dentro30 = hoje.subtract(const Duration(days: 30));
        await _seedOcorrencia(
          db,
          despesaId: despesaId,
          vencimento: DateTime(dentro30.year, dentro30.month, dentro30.day),
          status: StatusOcorrencia.paga,
          valorPago: 100,
        );

        // Paga há 91 dias — NÃO deve aparecer
        final fora91 = hoje.subtract(const Duration(days: 91));
        await _seedOcorrencia(
          db,
          despesaId: despesaId,
          vencimento: DateTime(fora91.year, fora91.month, fora91.day),
          status: StatusOcorrencia.paga,
          valorPago: 100,
        );

        final stream = db.ocorrenciasDespesaDao.watchProximasByVeiculo(
          'ABC1D23',
        );
        final lista = await stream.first;

        expect(lista, hasLength(1));
        expect(lista.single.status, StatusOcorrencia.paga);
      },
    );

    test(
      'retorna puladas dos últimos 90 dias; exclui puladas com mais de 90 dias',
      () async {
        final despesaId = await _seedDespesa(db);
        final hoje = DateTime.now();

        // Pulada há 10 dias — deve aparecer
        final dentro10 = hoje.subtract(const Duration(days: 10));
        await _seedOcorrencia(
          db,
          despesaId: despesaId,
          vencimento: DateTime(dentro10.year, dentro10.month, dentro10.day),
          status: StatusOcorrencia.pulada,
        );

        // Pulada há 95 dias — NÃO deve aparecer
        final fora95 = hoje.subtract(const Duration(days: 95));
        await _seedOcorrencia(
          db,
          despesaId: despesaId,
          vencimento: DateTime(fora95.year, fora95.month, fora95.day),
          status: StatusOcorrencia.pulada,
        );

        final stream = db.ocorrenciasDespesaDao.watchProximasByVeiculo(
          'ABC1D23',
        );
        final lista = await stream.first;

        expect(lista, hasLength(1));
        expect(lista.single.status, StatusOcorrencia.pulada);
      },
    );

    test('resulta vazio quando não há ocorrências', () async {
      // Despesa existe mas nenhuma ocorrência
      await _seedDespesa(db);

      final stream = db.ocorrenciasDespesaDao.watchProximasByVeiculo('ABC1D23');
      final lista = await stream.first;

      expect(lista, isEmpty);
    });

    test('ordena por dataVencimento ASC', () async {
      final despesaId = await _seedDespesa(db);
      final hoje = DateTime.now();

      // Inserir fora de ordem
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(hoje.year, hoje.month + 2, 1),
      );
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(hoje.year, hoje.month, 1),
      );
      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(hoje.year, hoje.month + 1, 1),
      );

      final stream = db.ocorrenciasDespesaDao.watchProximasByVeiculo('ABC1D23');
      final lista = await stream.first;

      expect(lista, hasLength(3));
      for (var i = 0; i < lista.length - 1; i++) {
        expect(
          lista[i].dataVencimento.isBefore(lista[i + 1].dataVencimento) ||
              lista[i].dataVencimento.isAtSameMomentAs(
                lista[i + 1].dataVencimento,
              ),
          isTrue,
          reason:
              'Esperado ordem ASC: ${lista[i].dataVencimento} deve ser <= ${lista[i + 1].dataVencimento}',
        );
      }
    });

    test('isola ocorrências por veículo', () async {
      await _seedVeiculo(db, placa: 'OUT9Z99');
      final despesaId = await _seedDespesa(db, placa: 'ABC1D23');
      final despesaOutroId = await _seedDespesa(db, placa: 'OUT9Z99');

      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2027, 1, 1),
      );
      await _seedOcorrencia(
        db,
        despesaId: despesaOutroId,
        vencimento: DateTime(2027, 1, 2),
      );

      final stream = db.ocorrenciasDespesaDao.watchProximasByVeiculo('ABC1D23');
      final lista = await stream.first;

      expect(lista, hasLength(1));
    });

    test('emite nova lista após inserir nova ocorrência pendente', () async {
      final despesaId = await _seedDespesa(db);

      final stream = db.ocorrenciasDespesaDao.watchProximasByVeiculo('ABC1D23');
      final primeiro = await stream.first;
      expect(primeiro, isEmpty);

      await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2028, 6, 1),
      );

      final segundo = await stream.first;
      expect(segundo, hasLength(1));
    });
  });

  // -------------------------------------------------------------------------
  // atualizarValorPago
  // -------------------------------------------------------------------------
  group('atualizarValorPago', () {
    test('atualiza apenas o campo valor_pago, sem alterar status', () async {
      final despesaId = await _seedDespesa(db);
      final id = await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2026, 3, 1),
        status: StatusOcorrencia.paga,
        valorPago: 100.0,
      );

      final rows = await db.ocorrenciasDespesaDao.atualizarValorPago(
        id,
        250.50,
      );
      expect(rows, 1);

      final o = (await db.ocorrenciasDespesaDao.byId(id))!;
      expect(o.valorPago, 250.50);
      // Status não deve ter mudado
      expect(o.status, StatusOcorrencia.paga);
    });

    test('não afeta outras ocorrências', () async {
      final despesaId = await _seedDespesa(db);

      final id1 = await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2026, 3, 1),
        status: StatusOcorrencia.paga,
        valorPago: 100.0,
      );
      final id2 = await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2026, 4, 1),
        status: StatusOcorrencia.paga,
        valorPago: 200.0,
      );

      await db.ocorrenciasDespesaDao.atualizarValorPago(id1, 999.0);

      final o2 = (await db.ocorrenciasDespesaDao.byId(id2))!;
      expect(o2.valorPago, 200.0);
    });

    test('aceita valor zero', () async {
      final despesaId = await _seedDespesa(db);
      final id = await _seedOcorrencia(
        db,
        despesaId: despesaId,
        vencimento: DateTime(2026, 3, 1),
        status: StatusOcorrencia.paga,
        valorPago: 100.0,
      );

      await db.ocorrenciasDespesaDao.atualizarValorPago(id, 0.0);

      final o = (await db.ocorrenciasDespesaDao.byId(id))!;
      expect(o.valorPago, 0.0);
    });

    test('retorna 0 quando id não existe', () async {
      final rows = await db.ocorrenciasDespesaDao.atualizarValorPago(
        99999,
        100.0,
      );
      expect(rows, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Regressão: marcarPaga e marcarPulada continuam funcionando
  // -------------------------------------------------------------------------
  group('marcarPaga (regressão)', () {
    test('define status=paga, valorPago e dataPagamento', () async {
      final despesaId = await _seedDespesa(db);
      final id = await db.ocorrenciasDespesaDao.insertOcorrencia(
        OcorrenciasDespesaCompanion.insert(
          despesaId: despesaId,
          dataVencimento: DateTime(2026, 6, 1),
          status: StatusOcorrencia.pendente,
        ),
      );

      final rows = await db.ocorrenciasDespesaDao.marcarPaga(
        id,
        valorPago: 350.0,
        dataPagamento: DateTime(2026, 6, 3),
      );
      expect(rows, 1);

      final o = (await db.ocorrenciasDespesaDao.byId(id))!;
      expect(o.status, StatusOcorrencia.paga);
      expect(o.valorPago, 350.0);
      expect(o.dataPagamento, DateTime(2026, 6, 3));
    });
  });

  group('marcarPulada (regressão)', () {
    test('define status=pulada', () async {
      final despesaId = await _seedDespesa(db);
      final id = await db.ocorrenciasDespesaDao.insertOcorrencia(
        OcorrenciasDespesaCompanion.insert(
          despesaId: despesaId,
          dataVencimento: DateTime(2026, 6, 1),
          status: StatusOcorrencia.pendente,
        ),
      );

      await db.ocorrenciasDespesaDao.marcarPulada(id);

      final o = (await db.ocorrenciasDespesaDao.byId(id))!;
      expect(o.status, StatusOcorrencia.pulada);
    });
  });
}
