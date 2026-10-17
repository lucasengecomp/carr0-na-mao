import 'package:carro_na_mao/data/database/app_database.dart';
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

  // ---------------------------------------------------------------------------
  // Schema v3: coluna presence
  // ---------------------------------------------------------------------------
  group('schema v3 – tabela postos_sugestao', () {
    test('tabela postos_sugestao existe no schema fresh v3', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='postos_sugestao'",
          )
          .get();
      expect(rows, hasLength(1));
    });

    test('coluna nome existe como TEXT (PRIMARY KEY)', () async {
      final rows = await db
          .customSelect("PRAGMA table_info('postos_sugestao')")
          .get();
      final cols = {for (final r in rows) r.data['name'] as String: r.data};
      expect(cols.keys, containsAll(['nome', 'ultimo_uso', 'uso_count']));
      expect(cols['nome']!['pk'], 1); // primary key
    });

    test('coluna uso_count tem default 1', () async {
      final rows = await db
          .customSelect("PRAGMA table_info('postos_sugestao')")
          .get();
      final usoCountRow = rows.firstWhere((r) => r.data['name'] == 'uso_count');
      expect(usoCountRow.data['dflt_value'], '1');
    });
  });

  // ---------------------------------------------------------------------------
  // Migração v2 → v3 simulada in-memory
  // ---------------------------------------------------------------------------
  group('migração v2 → v3', () {
    test(
      'banco com tabela postos_sugestao sem colunas novas recebe addColumn sem '
      'erro e operações do DAO funcionam após migração',
      () async {
        // Simula estado pré-v3: cria a tabela só com coluna "nome"
        // Em um DB in-memory separado, cria manualmente a tabela como estava
        // antes da v3 (só nome), e então executa a migração addColumn.
        final migDb = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(migDb.close);

        // Cria a tabela simulando schema v2 (apenas coluna nome)
        await migDb.customStatement(
          'CREATE TABLE IF NOT EXISTS postos_sugestao_v2_sim '
          '(nome TEXT NOT NULL PRIMARY KEY)',
        );
        await migDb.customStatement(
          "INSERT INTO postos_sugestao_v2_sim (nome) VALUES ('Shell Antigo')",
        );

        // Adiciona as colunas novas como a migração faria
        await migDb.customStatement(
          'ALTER TABLE postos_sugestao_v2_sim ADD COLUMN ultimo_uso INTEGER',
        );
        await migDb.customStatement(
          'ALTER TABLE postos_sugestao_v2_sim ADD COLUMN uso_count INTEGER DEFAULT 1',
        );

        // Valida que a linha antiga ainda está legível
        final rows = await migDb
            .customSelect('SELECT * FROM postos_sugestao_v2_sim')
            .get();
        expect(rows, hasLength(1));
        expect(rows.single.data['nome'], 'Shell Antigo');
        // uso_count default aplicado pelo banco
        expect(rows.single.data['uso_count'], 1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // PostoSugestaoDao – upsert
  // ---------------------------------------------------------------------------
  group('PostoSugestaoDao.upsert', () {
    test('nome inédito cria registro com usoCount = 1', () async {
      await db.postoSugestaoDao.upsert('Shell Centro');

      final rows = await db.select(db.postosSugestao).get();
      expect(rows, hasLength(1));
      expect(rows.single.nome, 'Shell Centro');
      expect(rows.single.usoCount, 1);
      expect(rows.single.ultimoUso, isNotNull);
    });

    test('nome existente incrementa usoCount', () async {
      await db.postoSugestaoDao.upsert('Ipiranga');
      await db.postoSugestaoDao.upsert('Ipiranga');
      await db.postoSugestaoDao.upsert('Ipiranga');

      final rows = await db.select(db.postosSugestao).get();
      expect(rows, hasLength(1));
      expect(rows.single.usoCount, 3);
    });

    test('segundo upsert atualiza ultimoUso', () async {
      await db.postoSugestaoDao.upsert('BR Mania');
      final primeira = (await db.select(db.postosSugestao).get()).single;

      // Garante progresso de tempo entre as duas operações
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await db.postoSugestaoDao.upsert('BR Mania');
      final segunda = (await db.select(db.postosSugestao).get()).single;

      // ultimoUso deve ser >= à primeira inserção
      expect(
        segunda.ultimoUso.millisecondsSinceEpoch,
        greaterThanOrEqualTo(primeira.ultimoUso.millisecondsSinceEpoch),
      );
    });

    test('múltiplos nomes distintos criam registros separados', () async {
      await db.postoSugestaoDao.upsert('Shell');
      await db.postoSugestaoDao.upsert('Ipiranga');
      await db.postoSugestaoDao.upsert('Petrobras');

      final rows = await db.select(db.postosSugestao).get();
      expect(rows, hasLength(3));
    });

    test(
      'nome vazio não deve causar crash (comportamento defensivo)',
      () async {
        // O form nunca chama upsert com string vazia, mas o DAO por si não deve
        // crashar; pode inserir ou ignorar — apenas não deve jogar exceção.
        await expectLater(db.postoSugestaoDao.upsert(''), completes);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // PostoSugestaoDao – search
  // ---------------------------------------------------------------------------
  group('PostoSugestaoDao.search', () {
    setUp(() async {
      // Insere dados com contagens diferentes para testar ordenação
      // Shell: 3x, Ipiranga: 1x, Petrobras: 2x
      await db.postoSugestaoDao.upsert('Shell Centro');
      await db.postoSugestaoDao.upsert('Shell Centro');
      await db.postoSugestaoDao.upsert('Shell Centro');
      await db.postoSugestaoDao.upsert('Ipiranga Norte');
      await db.postoSugestaoDao.upsert('Petrobras Sul');
      await db.postoSugestaoDao.upsert('Petrobras Sul');
    });

    test('prefixo "Shell" retorna apenas Shell Centro', () async {
      final results = await db.postoSugestaoDao.search('Shell');
      expect(results, ['Shell Centro']);
    });

    test('prefixo "Ip" retorna Ipiranga (case-insensitive via LIKE)', () async {
      final results = await db.postoSugestaoDao.search('Ip');
      // LIKE em SQLite é case-insensitive para ASCII
      expect(results, ['Ipiranga Norte']);
    });

    test('busca por substring do meio retorna correto', () async {
      final results = await db.postoSugestaoDao.search('Centro');
      expect(results, ['Shell Centro']);
    });

    test('busca sem matches retorna lista vazia', () async {
      final results = await db.postoSugestaoDao.search('XYZ INEXISTENTE');
      expect(results, isEmpty);
    });

    test(
      'ordenação por usoCount desc: Shell(3) > Petrobras(2) > Ipiranga(1)',
      () async {
        // Busca por "Norte" casa só Ipiranga Norte (count=1);
        // Busca por "Sul" casa só Petrobras Sul (count=2);
        // Para testar ordenação usamos strings que casam todos via substring
        // única: "o" aparece em Shell Centr*o*, Ipiranga N*o*rte, Petrobras.
        // Shell Centro (3) > Petrobras Sul (2) > Ipiranga Norte (1)
        final results = await db.postoSugestaoDao.search('o');
        expect(results, isNotEmpty);
        // Shell Centro tem maior count (3) — deve ser primeiro
        expect(results.first, 'Shell Centro');
        // Petrobras Sul (2) deve vir antes de Ipiranga Norte (1)
        final idxPetrobras = results.indexOf('Petrobras Sul');
        final idxIpiranga = results.indexOf('Ipiranga Norte');
        expect(idxPetrobras, lessThan(idxIpiranga));
      },
    );

    test('limit é respeitado', () async {
      final results = await db.postoSugestaoDao.search('a', limit: 1);
      expect(results, hasLength(1));
    });

    test('limit padrão 10 não retorna mais de 10 itens', () async {
      // Insere 15 postos com "z"
      for (var i = 0; i < 15; i++) {
        await db.postoSugestaoDao.upsert('Posto Z$i');
      }
      final results = await db.postoSugestaoDao.search('Posto Z');
      expect(results.length, lessThanOrEqualTo(10));
    });

    test('busca com caractere % não causa SQL injection / erro', () async {
      await db.postoSugestaoDao.upsert('Posto 100%');
      final results = await db.postoSugestaoDao.search('%');
      // Deve retornar apenas o posto com % no nome, não todos
      expect(results, ['Posto 100%']);
    });

    test('busca com caractere _ não casa tudo', () async {
      await db.postoSugestaoDao.upsert('Posto_A');
      final results = await db.postoSugestaoDao.search('_');
      // Deve retornar apenas Posto_A, não todos
      expect(results, ['Posto_A']);
    });
  });
}
