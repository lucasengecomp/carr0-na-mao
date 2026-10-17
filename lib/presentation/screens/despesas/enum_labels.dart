import '../../../data/database/enums.dart';
import '../../../l10n/app_localizations.dart';

extension CategoriaDespesaLabel on CategoriaDespesa {
  String label(AppLocalizations l10n) => switch (this) {
    CategoriaDespesa.lavagem => l10n.categoriaDespesaLavagem,
    CategoriaDespesa.estacionamento => l10n.categoriaDespesaEstacionamento,
    CategoriaDespesa.pedagio => l10n.categoriaDespesaPedagio,
    CategoriaDespesa.financiamento => l10n.categoriaDespesaFinanciamento,
    CategoriaDespesa.outra => l10n.categoriaDespesaOutra,
  };
}

extension FrequenciaDespesaLabel on FrequenciaDespesa {
  String label(AppLocalizations l10n) => switch (this) {
    FrequenciaDespesa.unica => l10n.frequenciaDespesaUnica,
    FrequenciaDespesa.semanal => l10n.frequenciaDespesaSemanal,
    FrequenciaDespesa.mensal => l10n.frequenciaDespesaMensal,
    FrequenciaDespesa.anual => l10n.frequenciaDespesaAnual,
  };
}
