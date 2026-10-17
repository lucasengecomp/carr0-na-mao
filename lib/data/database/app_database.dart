import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/abastecimentos_dao.dart';
import 'daos/despesas_dao.dart';
import 'daos/lembretes_dao.dart';
import 'daos/manutencoes_dao.dart';
import 'daos/marcas_modelos_dao.dart';
import 'daos/posto_sugestao_dao.dart';
import 'daos/veiculos_dao.dart';
import 'enums.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Veiculos,
    Abastecimentos,
    Manutencoes,
    DespesasRecorrentes,
    OcorrenciasDespesa,
    Lembretes,
    PostosSugestao,
    TiposManutencaoPadrao,
    Marcas,
    Modelos,
  ],
  daos: [
    VeiculosDao,
    AbastecimentosDao,
    ManutencoesDao,
    TiposManutencaoPadraoDao,
    DespesasRecorrentesDao,
    OcorrenciasDespesaDao,
    LembretesDao,
    MarcasModelosDao,
    PostoSugestaoDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'carro_na_mao'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedTiposManutencaoPadrao();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(marcas);
        await m.createTable(modelos);
      }
      if (from < 3) {
        // Adiciona colunas ultimo_uso e uso_count à tabela postos_sugestao.
        // Bancos criados antes da v3 podem ter a tabela sem essas colunas.
        await m.addColumn(postosSugestao, postosSugestao.ultimoUso);
        await m.addColumn(postosSugestao, postosSugestao.usoCount);
      }
      if (from < 4) {
        // Adiciona dia_do_mes e ativa às despesas_recorrentes.
        await m.addColumn(despesasRecorrentes, despesasRecorrentes.diaDoMes);
        await m.addColumn(despesasRecorrentes, despesasRecorrentes.ativa);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seedTiposManutencaoPadrao() async {
    TiposManutencaoPadraoCompanion seed(
      TipoManutencao tipo, {
      int? km,
      int? meses,
    }) => TiposManutencaoPadraoCompanion.insert(
      tipo: tipo,
      intervaloKm: Value(km),
      intervaloMeses: Value(meses),
    );

    await batch((b) {
      b.insertAll(tiposManutencaoPadrao, [
        seed(TipoManutencao.oleoMotor, km: 10000, meses: 12),
        seed(TipoManutencao.filtroOleo, km: 10000, meses: 12),
        seed(TipoManutencao.filtroAr, km: 20000, meses: 24),
        seed(TipoManutencao.filtroCombustivel, km: 30000, meses: 36),
        seed(TipoManutencao.filtroCabine, km: 15000, meses: 12),
        seed(TipoManutencao.velas, km: 30000, meses: 24),
        seed(TipoManutencao.correiaDentada, km: 60000, meses: 60),
        seed(TipoManutencao.pastilhasFreio, km: 30000, meses: 24),
        seed(TipoManutencao.rodizioPneus, km: 10000, meses: 12),
        seed(TipoManutencao.alinhamentoBalanceamento, km: 10000, meses: 12),
        seed(TipoManutencao.fluidoFreio, meses: 24),
      ]);
    });
  }
}
