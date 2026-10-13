import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DespesasRecorrentesCompanion _novaDespesa({
  String placa = 'ABC1D23',
  String nome = 'Estacionamento',
  CategoriaDespesa categoria = CategoriaDespesa.estacionamento,
  double valor = 200,
  FrequenciaDespesa frequencia = FrequenciaDespesa.mensal,
  DateTime? dataInicio,
}) => DespesasRecorrentesCompanion.insert(
  veiculoPlaca: placa,
  nome: nome,
  categoria: categoria,
  valor: valor,
  frequencia: frequencia,
  dataInicio: dataInicio ?? DateTime(2026, 1, 1),
);

OcorrenciasDespesaCompanion _novaOcorrencia({
  required int despesaId,
  required DateTime vencimento,
  StatusOcorrencia status = StatusOcorrencia.pendente,
}) => OcorrenciasDespesaCompanion.insert(
  despesaId: despesaId,
  dataVencimento: vencimento,
  status: status,
);

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

  group('DespesasRecorrentesDao', () {
    test('CRUD + listByVeiculo', () async {
      final id = await db.despesasRecorrentesDao.insertDespesa(_novaDespesa());
      final d = await db.despesasRecorrentesDao.byId(id);
      expect(d!.nome, 'Estacionamento');

      await db.despesasRecorrentesDao.updateDespesa(d.copyWith(valor: 250));
      expect((await db.despesasRecorrentesDao.byId(id))!.valor, 250);

      final rows = await db.despesasRecorrentesDao.deleteById(id);
      expect(rows, 1);
      expect(await db.despesasRecorrentesDao.byId(id), isNull);
    });
  });

  group('OcorrenciasDespesaDao', () {
    late int despesaId;

    setUp(() async {
      despesaId = await db.despesasRecorrentesDao.insertDespesa(_novaDespesa());
    });

    test('listByDespesa ordena por vencimento', () async {
      await db.ocorrenciasDespesaDao.insertOcorrencia(
        _novaOcorrencia(despesaId: despesaId, vencimento: DateTime(2026, 3, 1)),
      );
      await db.ocorrenciasDespesaDao.insertOcorrencia(
        _novaOcorrencia(despesaId: despesaId, vencimento: DateTime(2026, 1, 1)),
      );
      await db.ocorrenciasDespesaDao.insertOcorrencia(
        _novaOcorrencia(despesaId: despesaId, vencimento: DateTime(2026, 2, 1)),
      );

      final lista = await db.ocorrenciasDespesaDao.listByDespesa(despesaId);
      expect(lista.map((o) => o.dataVencimento), [
        DateTime(2026, 1, 1),
        DateTime(2026, 2, 1),
        DateTime(2026, 3, 1),
      ]);
    });

    test('marcarPaga preenche valorPago e dataPagamento', () async {
      final id = await db.ocorrenciasDespesaDao.insertOcorrencia(
        _novaOcorrencia(despesaId: despesaId, vencimento: DateTime(2026, 1, 1)),
      );

      final rows = await db.ocorrenciasDespesaDao.marcarPaga(
        id,
        valorPago: 215.5,
        dataPagamento: DateTime(2026, 1, 3),
      );
      expect(rows, 1);

      final o = (await db.ocorrenciasDespesaDao.byId(id))!;
      expect(o.status, StatusOcorrencia.paga);
      expect(o.valorPago, 215.5);
      expect(o.dataPagamento, DateTime(2026, 1, 3));
    });

    test('marcarPulada muda status', () async {
      final id = await db.ocorrenciasDespesaDao.insertOcorrencia(
        _novaOcorrencia(despesaId: despesaId, vencimento: DateTime(2026, 1, 1)),
      );

      await db.ocorrenciasDespesaDao.marcarPulada(id);
      final o = (await db.ocorrenciasDespesaDao.byId(id))!;
      expect(o.status, StatusOcorrencia.pulada);
    });

    test('listPendentesByVeiculo isola por veículo e status', () async {
      await db.veiculosDao.insertVeiculo(
        VeiculosCompanion.insert(
          placa: 'XYZ9A99',
          marca: 'Fiat',
          modelo: 'Mobi',
          ano: 2024,
          tipo: TipoVeiculo.carro,
          combustivel: TipoCombustivelVeiculo.flex,
          kmInicial: 1000,
        ),
      );
      final despOutro = await db.despesasRecorrentesDao.insertDespesa(
        _novaDespesa(placa: 'XYZ9A99', nome: 'Lavagem'),
      );

      await db.ocorrenciasDespesaDao.insertOcorrencia(
        _novaOcorrencia(despesaId: despesaId, vencimento: DateTime(2026, 1, 1)),
      );
      final pagaId = await db.ocorrenciasDespesaDao.insertOcorrencia(
        _novaOcorrencia(despesaId: despesaId, vencimento: DateTime(2026, 2, 1)),
      );
      await db.ocorrenciasDespesaDao.marcarPaga(
        pagaId,
        valorPago: 200,
        dataPagamento: DateTime(2026, 2, 1),
      );
      await db.ocorrenciasDespesaDao.insertOcorrencia(
        _novaOcorrencia(
          despesaId: despOutro,
          vencimento: DateTime(2026, 1, 15),
        ),
      );

      final pendentes = await db.ocorrenciasDespesaDao.listPendentesByVeiculo(
        'ABC1D23',
      );
      expect(pendentes, hasLength(1));
      expect(pendentes.single.dataVencimento, DateTime(2026, 1, 1));
    });

    test('cascade: deletar despesa remove ocorrências', () async {
      await db.ocorrenciasDespesaDao.insertOcorrencia(
        _novaOcorrencia(despesaId: despesaId, vencimento: DateTime(2026, 1, 1)),
      );
      await db.despesasRecorrentesDao.deleteById(despesaId);
      final lista = await db.ocorrenciasDespesaDao.listByDespesa(despesaId);
      expect(lista, isEmpty);
    });
  });
}
