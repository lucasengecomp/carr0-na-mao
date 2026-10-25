/// Labels PT-BR para enums usados no export (CSV e XLSX).
///
/// Independente de BuildContext e AppLocalizations — o export é sempre PT-BR.
library;

import '../data/database/enums.dart';

extension TipoCombustivelAbastecimentoExportLabel
    on TipoCombustivelAbastecimento {
  String get labelPt => switch (this) {
    TipoCombustivelAbastecimento.gasolina => 'Gasolina',
    TipoCombustivelAbastecimento.alcool => 'Álcool',
    TipoCombustivelAbastecimento.diesel => 'Diesel',
    TipoCombustivelAbastecimento.gnv => 'GNV',
    TipoCombustivelAbastecimento.eletrico => 'Elétrico',
  };
}

extension TipoManutencaoExportLabel on TipoManutencao {
  String get labelPt => switch (this) {
    TipoManutencao.oleoMotor => 'Óleo do motor',
    TipoManutencao.filtroOleo => 'Filtro de óleo',
    TipoManutencao.filtroAr => 'Filtro de ar',
    TipoManutencao.filtroCombustivel => 'Filtro de combustível',
    TipoManutencao.filtroCabine => 'Filtro de cabine',
    TipoManutencao.velas => 'Velas de ignição',
    TipoManutencao.correiaDentada => 'Correia dentada',
    TipoManutencao.correiaAcessorios => 'Correia de acessórios',
    TipoManutencao.pneus => 'Pneus',
    TipoManutencao.alinhamentoBalanceamento => 'Alinhamento e balanceamento',
    TipoManutencao.pastilhasFreio => 'Pastilhas de freio',
    TipoManutencao.discosFreio => 'Discos de freio',
    TipoManutencao.oleoCambio => 'Óleo do câmbio',
    TipoManutencao.fluidoFreio => 'Fluido de freio',
    TipoManutencao.revisaoGeral => 'Revisão geral',
    TipoManutencao.rodizioPneus => 'Rodízio de pneus',
    TipoManutencao.outros => 'Outros',
  };
}

extension CategoriaDespesaExportLabel on CategoriaDespesa {
  String get labelPt => switch (this) {
    CategoriaDespesa.lavagem => 'Lavagem',
    CategoriaDespesa.estacionamento => 'Estacionamento',
    CategoriaDespesa.pedagio => 'Pedágio',
    CategoriaDespesa.financiamento => 'Financiamento',
    CategoriaDespesa.outra => 'Outra',
  };
}

extension FrequenciaDespesaExportLabel on FrequenciaDespesa {
  String get labelPt => switch (this) {
    FrequenciaDespesa.unica => 'Única',
    FrequenciaDespesa.semanal => 'Semanal',
    FrequenciaDespesa.mensal => 'Mensal',
    FrequenciaDespesa.anual => 'Anual',
  };
}

extension StatusOcorrenciaExportLabel on StatusOcorrencia {
  String get labelPt => switch (this) {
    StatusOcorrencia.pendente => 'Pendente',
    StatusOcorrencia.paga => 'Paga',
    StatusOcorrencia.pulada => 'Pulada',
  };
}

extension StatusLembreteExportLabel on StatusLembrete {
  String get labelPt => switch (this) {
    StatusLembrete.pendente => 'Pendente',
    StatusLembrete.concluido => 'Concluído',
    StatusLembrete.adiado => 'Adiado',
  };
}
