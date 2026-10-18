import 'package:flutter/material.dart';

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

extension StatusOcorrenciaLabel on StatusOcorrencia {
  String label(AppLocalizations l10n) => switch (this) {
    StatusOcorrencia.pendente => l10n.ocorrenciaStatusPendente,
    StatusOcorrencia.paga => l10n.ocorrenciaStatusPaga,
    StatusOcorrencia.pulada => l10n.ocorrenciaStatusPulada,
  };

  Color chipColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (this) {
      StatusOcorrencia.pendente => cs.surfaceContainerHighest,
      StatusOcorrencia.paga => cs.primaryContainer,
      StatusOcorrencia.pulada => cs.secondaryContainer,
    };
  }

  Color chipTextColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (this) {
      StatusOcorrencia.pendente => cs.onSurfaceVariant,
      StatusOcorrencia.paga => cs.onPrimaryContainer,
      StatusOcorrencia.pulada => cs.onSecondaryContainer,
    };
  }
}
