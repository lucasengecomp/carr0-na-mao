import '../../../data/database/enums.dart';
import '../../../l10n/app_localizations.dart';

extension TipoCombustivelAbastecimentoLabel on TipoCombustivelAbastecimento {
  String label(AppLocalizations l10n) => switch (this) {
    TipoCombustivelAbastecimento.gasolina => l10n.tipoCombustivelGasolina,
    TipoCombustivelAbastecimento.alcool => l10n.tipoCombustivelAlcool,
    TipoCombustivelAbastecimento.diesel => l10n.tipoCombustivelDiesel,
    TipoCombustivelAbastecimento.gnv => l10n.tipoCombustivelGnv,
    TipoCombustivelAbastecimento.eletrico => l10n.tipoCombustivelEletrico,
  };
}

/// Combustíveis compatíveis com um veículo. Flex aceita gasolina e álcool;
/// os demais tipos só aceitam o próprio combustível (GNV coexiste com o
/// combustível original mas é tratado como opção adicional).
List<TipoCombustivelAbastecimento> combustiveisParaVeiculo(
  TipoCombustivelVeiculo tipoVeiculo,
) {
  switch (tipoVeiculo) {
    case TipoCombustivelVeiculo.flex:
      return const [
        TipoCombustivelAbastecimento.gasolina,
        TipoCombustivelAbastecimento.alcool,
        TipoCombustivelAbastecimento.gnv,
      ];
    case TipoCombustivelVeiculo.gasolina:
      return const [
        TipoCombustivelAbastecimento.gasolina,
        TipoCombustivelAbastecimento.gnv,
      ];
    case TipoCombustivelVeiculo.alcool:
      return const [TipoCombustivelAbastecimento.alcool];
    case TipoCombustivelVeiculo.diesel:
      return const [TipoCombustivelAbastecimento.diesel];
    case TipoCombustivelVeiculo.gnv:
      return const [
        TipoCombustivelAbastecimento.gnv,
        TipoCombustivelAbastecimento.gasolina,
      ];
    case TipoCombustivelVeiculo.eletrico:
      return const [TipoCombustivelAbastecimento.eletrico];
  }
}
