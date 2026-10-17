import '../../../data/database/enums.dart';
import '../../../l10n/app_localizations.dart';

extension TipoVeiculoLabel on TipoVeiculo {
  String label(AppLocalizations l10n) => switch (this) {
    TipoVeiculo.carro => l10n.tipoVeiculoCarro,
    TipoVeiculo.moto => l10n.tipoVeiculoMoto,
  };
}

extension TipoCombustivelVeiculoLabel on TipoCombustivelVeiculo {
  String label(AppLocalizations l10n) => switch (this) {
    TipoCombustivelVeiculo.gasolina => l10n.tipoCombustivelGasolina,
    TipoCombustivelVeiculo.alcool => l10n.tipoCombustivelAlcool,
    TipoCombustivelVeiculo.flex => l10n.tipoCombustivelFlex,
    TipoCombustivelVeiculo.diesel => l10n.tipoCombustivelDiesel,
    TipoCombustivelVeiculo.gnv => l10n.tipoCombustivelGnv,
    TipoCombustivelVeiculo.eletrico => l10n.tipoCombustivelEletrico,
  };
}
