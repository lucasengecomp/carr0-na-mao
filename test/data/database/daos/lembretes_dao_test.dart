import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

LembretesCompanion _novoLembrete({
  String placa = 'ABC1D23',
  String tipo = 'avulso',
  String descricao = 'Trocar palhetas',
  DateTime? dataAlvo,
  int? kmAlvo,
  StatusLembrete status = StatusLembrete.pendente,
  int? manutencaoId,
}) => LembretesCompanion.insert(
  veiculoPlaca: placa,
  tipo: tipo,
  descricao: descricao,
  dataAlvo: Value(dataAlvo),
  kmAlvo: Value(kmAlvo),
  status: status,
  manutencaoId: Value(manutencaoId),
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

  test('insere com data_alvo apenas', () async {
    final id = await db.lembretesDao.insertLembrete(
      _novoLembrete(dataAlvo: DateTime(2026, 12, 1)),
    );
    final l = await db.lembretesDao.byId(id);
    expect(l!.dataAlvo, DateTime(2026, 12, 1));
    expect(l.kmAlvo, isNull);
  });

  test('insere com km_alvo apenas', () async {
    final id = await db.lembretesDao.insertLembrete(
      _novoLembrete(kmAlvo: 50000),
    );
    final l = await db.lembretesDao.byId(id);
    expect(l!.kmAlvo, 50000);
    expect(l.dataAlvo, isNull);
  });

  test('CHECK impede inserir sem data nem km', () async {
    expect(
      () => db.lembretesDao.insertLembrete(_novoLembrete()),
      throwsA(isA<Exception>()),
    );
  });

  test('listPendentesByVeiculo filtra por status', () async {
    final idP = await db.lembretesDao.insertLembrete(
      _novoLembrete(dataAlvo: DateTime(2026, 6, 1)),
    );
    final idC = await db.lembretesDao.insertLembrete(
      _novoLembrete(dataAlvo: DateTime(2026, 7, 1)),
    );
    await db.lembretesDao.marcarConcluido(idC);

    final pendentes = await db.lembretesDao.listPendentesByVeiculo('ABC1D23');
    expect(pendentes.map((l) => l.id), [idP]);
  });

  test('findVencidosPorKm devolve apenas abaixo do atual', () async {
    final idA = await db.lembretesDao.insertLembrete(
      _novoLembrete(kmAlvo: 20000),
    );
    final idB = await db.lembretesDao.insertLembrete(
      _novoLembrete(kmAlvo: 25000),
    );
    await db.lembretesDao.insertLembrete(_novoLembrete(kmAlvo: 30000));

    final vencidos = await db.lembretesDao.findVencidosPorKm('ABC1D23', 26000);
    expect(vencidos.map((l) => l.id).toSet(), {idA, idB});
  });

  test('marcarConcluido muda status', () async {
    final id = await db.lembretesDao.insertLembrete(
      _novoLembrete(kmAlvo: 20000),
    );
    await db.lembretesDao.marcarConcluido(id);
    expect((await db.lembretesDao.byId(id))!.status, StatusLembrete.concluido);
  });

  test('adiar atualiza data e km e volta a pendente', () async {
    final id = await db.lembretesDao.insertLembrete(
      _novoLembrete(dataAlvo: DateTime(2026, 1, 1), kmAlvo: 20000),
    );
    await db.lembretesDao.marcarConcluido(id);

    await db.lembretesDao.adiar(
      id,
      novaData: DateTime(2026, 6, 1),
      novoKm: 25000,
    );

    final l = (await db.lembretesDao.byId(id))!;
    expect(l.status, StatusLembrete.pendente);
    expect(l.dataAlvo, DateTime(2026, 6, 1));
    expect(l.kmAlvo, 25000);
  });

  test(
    'upsertByManutencao substitui lembrete pendente do mesmo tipo',
    () async {
      await db.manutencoesDao.insertManutencao(
        ManutencoesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          tipo: TipoManutencao.oleoMotor,
          data: DateTime(2026, 1, 10),
          km: 10200,
        ),
      );
      final manut1 = (await db.manutencoesDao.listByVeiculo('ABC1D23')).first;

      await db.lembretesDao.upsertByManutencao(
        placa: 'ABC1D23',
        manutencaoId: manut1.id,
        tipo: 'oleoMotor',
        descricao: 'Trocar óleo',
        dataAlvo: DateTime(2027, 1, 10),
        kmAlvo: 20200,
      );
      expect(
        await db.lembretesDao.listPendentesByVeiculo('ABC1D23'),
        hasLength(1),
      );

      // Nova manutenção do mesmo tipo substitui o lembrete anterior.
      await db.manutencoesDao.insertManutencao(
        ManutencoesCompanion.insert(
          veiculoPlaca: 'ABC1D23',
          tipo: TipoManutencao.oleoMotor,
          data: DateTime(2026, 7, 10),
          km: 15500,
        ),
      );
      final manut2 = (await db.manutencoesDao.listByVeiculo('ABC1D23')).first;

      await db.lembretesDao.upsertByManutencao(
        placa: 'ABC1D23',
        manutencaoId: manut2.id,
        tipo: 'oleoMotor',
        descricao: 'Trocar óleo',
        dataAlvo: DateTime(2027, 7, 10),
        kmAlvo: 25500,
      );

      final pendentes = await db.lembretesDao.listPendentesByVeiculo('ABC1D23');
      expect(pendentes, hasLength(1));
      expect(pendentes.single.kmAlvo, 25500);
    },
  );
}
