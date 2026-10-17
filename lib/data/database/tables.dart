import 'package:drift/drift.dart';

import 'enums.dart';

class Veiculos extends Table {
  TextColumn get placa => text().withLength(min: 7, max: 7)();
  TextColumn get apelido => text().nullable()();
  TextColumn get marca => text()();
  TextColumn get modelo => text()();
  IntColumn get ano => integer()();
  TextColumn get tipo => textEnum<TipoVeiculo>()();
  TextColumn get combustivel => textEnum<TipoCombustivelVeiculo>()();
  IntColumn get kmInicial => integer()();
  BoolColumn get arquivado => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {placa};
}

class Abastecimentos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get veiculoPlaca =>
      text().references(Veiculos, #placa, onDelete: KeyAction.cascade)();
  DateTimeColumn get data => dateTime()();
  IntColumn get km => integer()();
  TextColumn get tipoCombustivel => textEnum<TipoCombustivelAbastecimento>()();
  RealColumn get precoLitro => real()();
  RealColumn get valorTotal => real()();
  RealColumn get litros => real()();
  TextColumn get posto => text().nullable()();
  BoolColumn get tanqueCheio => boolean().withDefault(const Constant(true))();
}

@DataClassName('Manutencao')
class Manutencoes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get veiculoPlaca =>
      text().references(Veiculos, #placa, onDelete: KeyAction.cascade)();
  TextColumn get tipo => textEnum<TipoManutencao>()();
  TextColumn get nomeLivre => text().nullable()();
  DateTimeColumn get data => dateTime()();
  IntColumn get km => integer()();
  RealColumn get valor => real().nullable()();
  TextColumn get oficina => text().nullable()();
  TextColumn get observacoes => text().nullable()();
}

@DataClassName('DespesaRecorrente')
class DespesasRecorrentes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get veiculoPlaca =>
      text().references(Veiculos, #placa, onDelete: KeyAction.cascade)();
  TextColumn get nome => text()();
  TextColumn get categoria => textEnum<CategoriaDespesa>()();
  RealColumn get valor => real()();
  TextColumn get frequencia => textEnum<FrequenciaDespesa>()();

  /// Dia do mês (1-28) usado para despesas mensais e anuais.
  /// Nulo para despesas únicas.
  IntColumn get diaDoMes => integer().nullable()();
  DateTimeColumn get dataInicio => dateTime()();
  DateTimeColumn get dataFim => dateTime().nullable()();
  BoolColumn get ativa => boolean().withDefault(const Constant(true))();
}

@DataClassName('OcorrenciaDespesa')
class OcorrenciasDespesa extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get despesaId => integer().references(
    DespesasRecorrentes,
    #id,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get dataVencimento => dateTime()();
  DateTimeColumn get dataPagamento => dateTime().nullable()();
  RealColumn get valorPago => real().nullable()();
  TextColumn get status => textEnum<StatusOcorrencia>()();
}

class Lembretes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get veiculoPlaca =>
      text().references(Veiculos, #placa, onDelete: KeyAction.cascade)();
  IntColumn get manutencaoId => integer().nullable().references(
    Manutencoes,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get tipo => text()();
  TextColumn get descricao => text()();
  DateTimeColumn get dataAlvo => dateTime().nullable()();
  IntColumn get kmAlvo => integer().nullable()();
  TextColumn get status => textEnum<StatusLembrete>()();

  @override
  List<String> get customConstraints => [
    'CHECK (data_alvo IS NOT NULL OR km_alvo IS NOT NULL)',
  ];
}

@DataClassName('PostoSugestao')
class PostosSugestao extends Table {
  TextColumn get nome => text()();
  DateTimeColumn get ultimoUso => dateTime()();
  IntColumn get usoCount => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {nome};
}

@DataClassName('TipoManutencaoPadrao')
class TiposManutencaoPadrao extends Table {
  TextColumn get tipo => textEnum<TipoManutencao>()();
  IntColumn get intervaloKm => integer().nullable()();
  IntColumn get intervaloMeses => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {tipo};
}

/// Base curada de marcas de veículos, alimentada do asset
/// `assets/data/marcas_modelos.json`. Usuário pode criar entradas livres se
/// a marca desejada não estiver listada.
class Marcas extends Table {
  TextColumn get nome => text()();

  @override
  Set<Column<Object>> get primaryKey => {nome};
}

/// Modelos pertencentes a uma marca. Mesma lógica de seed curado + fallback
/// livre.
class Modelos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get marca =>
      text().references(Marcas, #nome, onDelete: KeyAction.cascade)();
  TextColumn get nome => text()();

  @override
  List<String> get customConstraints => ['UNIQUE (marca, nome)'];
}
