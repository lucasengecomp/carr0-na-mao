import 'package:carro_na_mao/data/database/app_database.dart';
import 'package:carro_na_mao/data/database/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('schema', () {
    test('cria todas as tabelas esperadas', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND "
            "name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
          )
          .get();
      final names = rows.map((r) => r.data['name'] as String).toSet();

      expect(
        names,
        containsAll([
          'veiculos',
          'abastecimentos',
          'manutencoes',
          'despesas_recorrentes',
          'ocorrencias_despesa',
          'lembretes',
          'postos_sugestao',
          'tipos_manutencao_padrao',
        ]),
      );
    });

    test('foreign keys estão habilitadas', () async {
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.data['foreign_keys'], 1);
    });
  });

  group('seed de tipos_manutencao_padrao', () {
    test('insere ao menos 11 tipos', () async {
      final rows = await db.select(db.tiposManutencaoPadrao).get();
      expect(rows.length, greaterThanOrEqualTo(11));
    });

    test('óleo do motor: 10.000 km / 12 meses', () async {
      final row =
          await (db.select(db.tiposManutencaoPadrao)
                ..where((t) => t.tipo.equalsValue(TipoManutencao.oleoMotor)))
              .getSingle();
      expect(row.intervaloKm, 10000);
      expect(row.intervaloMeses, 12);
    });

    test('fluido de freio: só meses (24), km nulo', () async {
      final row =
          await (db.select(db.tiposManutencaoPadrao)
                ..where((t) => t.tipo.equalsValue(TipoManutencao.fluidoFreio)))
              .getSingle();
      expect(row.intervaloKm, isNull);
      expect(row.intervaloMeses, 24);
    });

    test('correia dentada: 60.000 km / 60 meses', () async {
      final row =
          await (db.select(db.tiposManutencaoPadrao)..where(
                (t) => t.tipo.equalsValue(TipoManutencao.correiaDentada),
              ))
              .getSingle();
      expect(row.intervaloKm, 60000);
      expect(row.intervaloMeses, 60);
    });
  });

  group('restrições', () {
    test('lembrete exige data_alvo ou km_alvo', () async {
      await db
          .into(db.veiculos)
          .insert(
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

      expect(
        () => db
            .into(db.lembretes)
            .insert(
              LembretesCompanion.insert(
                veiculoPlaca: 'ABC1D23',
                tipo: 'avulso',
                descricao: 'sem alvo',
                status: StatusLembrete.pendente,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('cascade: deletar veículo apaga abastecimentos', () async {
      await db
          .into(db.veiculos)
          .insert(
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
      await db
          .into(db.abastecimentos)
          .insert(
            AbastecimentosCompanion.insert(
              veiculoPlaca: 'ABC1D23',
              data: DateTime(2026, 1, 10),
              km: 10100,
              tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
              precoLitro: 6.0,
              valorTotal: 300.0,
              litros: 50.0,
            ),
          );

      await (db.delete(
        db.veiculos,
      )..where((t) => t.placa.equals('ABC1D23'))).go();

      final remaining = await db.select(db.abastecimentos).get();
      expect(remaining, isEmpty);
    });
  });
}
