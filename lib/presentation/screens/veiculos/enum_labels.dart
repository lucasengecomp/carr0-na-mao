import '../../../data/database/enums.dart';

extension TipoVeiculoLabel on TipoVeiculo {
  String get label => switch (this) {
    TipoVeiculo.carro => 'Carro',
    TipoVeiculo.moto => 'Moto',
  };
}

extension TipoCombustivelVeiculoLabel on TipoCombustivelVeiculo {
  String get label => switch (this) {
    TipoCombustivelVeiculo.gasolina => 'Gasolina',
    TipoCombustivelVeiculo.alcool => 'Álcool',
    TipoCombustivelVeiculo.flex => 'Flex (gasolina + álcool)',
    TipoCombustivelVeiculo.diesel => 'Diesel',
    TipoCombustivelVeiculo.gnv => 'GNV',
    TipoCombustivelVeiculo.eletrico => 'Elétrico',
  };
}
