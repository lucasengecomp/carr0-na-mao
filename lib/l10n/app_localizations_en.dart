// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Carro na Mão';

  @override
  String get appSubtitulo =>
      'Expenses, fuel consumption and reminders in one place.';

  @override
  String get tooltipComparador => 'Fuel Comparator';

  @override
  String get tooltipConfiguracoes => 'Settings';

  @override
  String get tooltipTrocarVeiculo => 'Switch vehicle';

  @override
  String get navHome => 'Home';

  @override
  String get navAbastecer => 'Fuel';

  @override
  String get navManutencao => 'Maintenance';

  @override
  String get navDespesas => 'Expenses';

  @override
  String get navLembretes => 'Reminders';

  @override
  String get abastecimentosTitulo => 'Fuel History';

  @override
  String get abastecimentoNovoTitulo => 'New fuel-up';

  @override
  String get abastecimentoEditarTitulo => 'Edit fuel-up';

  @override
  String get abastecimentoFab => 'Fuel up';

  @override
  String get abastecimentoListaVaziaFiltro =>
      'No fuel-ups found for the selected filters.';

  @override
  String get abastecimentoListaVazia =>
      'No fuel-ups registered yet.\nTap \"Fuel up\" to get started.';

  @override
  String get semVeiculoCadastrarAbastecimento =>
      'Register a vehicle to start recording fuel-ups.';

  @override
  String get semVeiculoCadastrarAbastecimentoForm =>
      'Register a vehicle before recording fuel-ups.';

  @override
  String get botaoCadastrarVeiculo => 'Register vehicle';

  @override
  String erroGenerico(String mensagem) {
    return 'Error: $mensagem';
  }

  @override
  String get abastecimentoCampoData => 'Date';

  @override
  String get abastecimentoCampoHodometro => 'Odometer (km)';

  @override
  String get abastecimentoCampoCombustivel => 'Fuel type';

  @override
  String get abastecimentoCampoPreco => 'Price per liter (R\$)';

  @override
  String get abastecimentoCampoPrecoHelper =>
      'Fill in 2 of the 3 fields and the third is calculated.';

  @override
  String get abastecimentoCampoLitros => 'Liters';

  @override
  String get abastecimentoCampoValorTotal => 'Total value (R\$)';

  @override
  String get abastecimentoCampoPosto => 'Gas station (optional)';

  @override
  String get abastecimentoTanqueCheio => 'Full tank';

  @override
  String get abastecimentoTanqueCheioSubtitulo =>
      'Important for fuel consumption calculation (km/L).';

  @override
  String get abastecimentoAvisoKmRetroativo =>
      'The odometer reading is lower than the last recorded. You can save normally if this is a retroactive fuel-up.';

  @override
  String abastecimentoNaoPossivel(String erro) {
    return 'Could not save: $erro';
  }

  @override
  String get abastecimentoAcaoExcluir => 'Delete';

  @override
  String get abastecimentoExcluirTitulo => 'Delete fuel-up';

  @override
  String get abastecimentoExcluirMensagem =>
      'Are you sure you want to delete this fuel-up? This action cannot be undone.';

  @override
  String get abastecimentoExcluido => 'Fuel-up deleted.';

  @override
  String get validacaoObrigatorio => 'Required';

  @override
  String get validacaoKmInvalido => 'Invalid odometer';

  @override
  String get validacaoDecimalObrigatorio => 'Fill in 2 of the 3 fields';

  @override
  String get validacaoValorInvalido => 'Invalid value';

  @override
  String get botaoSalvar => 'Save';

  @override
  String get veiculosTitulo => 'Vehicles';

  @override
  String get veiculoNovoTitulo => 'New vehicle';

  @override
  String get veiculoEditarTitulo => 'Edit vehicle';

  @override
  String get veiculoFab => 'New vehicle';

  @override
  String get veiculoAtivos => 'Active';

  @override
  String get veiculoArquivados => 'Archived';

  @override
  String get veiculoNenhumAtivo =>
      'No vehicles registered. Tap \"New vehicle\" to get started.';

  @override
  String get veiculoNenhumArquivado => 'No archived vehicles.';

  @override
  String veiculoErroCarregar(String erro) {
    return 'Error loading: $erro';
  }

  @override
  String get veiculoMenuEditar => 'Edit';

  @override
  String get veiculoMenuArquivar => 'Archive';

  @override
  String get veiculoMenuRestaurar => 'Restore';

  @override
  String veiculoArquivadoSnack(String placa) {
    return '$placa archived';
  }

  @override
  String veiculoRestauradoSnack(String placa) {
    return '$placa restored';
  }

  @override
  String get veiculoCampoPlaca => 'License plate';

  @override
  String get veiculoCampoPlacaHelper =>
      'Mercosul (ABC1D23) or old format (ABC1234)';

  @override
  String get veiculoCampoApelido => 'Nickname (optional)';

  @override
  String get veiculoCampoMarca => 'Make';

  @override
  String get veiculoCampoMarcaHelper =>
      'Suggestions from database. You can type freely.';

  @override
  String get veiculoCampoModelo => 'Model';

  @override
  String get veiculoCampoModeloHelperSemSugestoes =>
      'Type freely (no suggestions for this make).';

  @override
  String get veiculoCampoModeloHelperComSugestoes =>
      'Suggestions from database. You can type freely.';

  @override
  String get veiculoCampoAno => 'Year';

  @override
  String get veiculoCampoTipo => 'Type';

  @override
  String get veiculoCampoCombustivel => 'Fuel type';

  @override
  String get veiculoCampoHodometro => 'Current odometer (km)';

  @override
  String get veiculoPlacaExistente =>
      'A vehicle with this license plate already exists.';

  @override
  String veiculoNaoPossivel(String erro) {
    return 'Could not save: $erro';
  }

  @override
  String get validacaoAnoInvalido => 'Invalid year';

  @override
  String get validacaoAnoForaDaFaixa => 'Year out of range';

  @override
  String get comparadorTitulo => 'Ethanol × Gasoline Comparator';

  @override
  String get comparadorCampoVeiculo => 'Vehicle';

  @override
  String get comparadorCampoAlcool => 'Ethanol price (R\$/L)';

  @override
  String get comparadorCampoGasolina => 'Gasoline price (R\$/L)';

  @override
  String get comparadorBotao => 'Compare';

  @override
  String get comparadorSemVeiculo => 'Select a vehicle.';

  @override
  String get comparadorSemVeiculoCadastrado =>
      'Register a vehicle first to use the comparator.';

  @override
  String get comparadorAlcoolCompensa => 'Ethanol is better';

  @override
  String get comparadorGasolinaCompensa => 'Gasoline is better';

  @override
  String get comparadorEmpate => 'Technical tie';

  @override
  String get comparadorMetodoHistorico => 'Based on vehicle history';

  @override
  String get comparadorMetodoRegra70 => '70% rule';

  @override
  String get comparadorSemHistoricoTexto =>
      'Not enough full-tank fuel-up history to calculate cost per km. Result based on the empirical 70% rule.';

  @override
  String get comparadorPrefixoPreco => 'R\$ ';

  @override
  String get configuracoesTitulo => 'Settings';

  @override
  String get configuracoesVeiculosTitulo => 'Vehicles';

  @override
  String get configuracoesVeiculosSubtitulo => 'Register, edit and archive';

  @override
  String get filtroTodos => 'All';

  @override
  String get tipoVeiculoCarro => 'Car';

  @override
  String get tipoVeiculoMoto => 'Motorcycle';

  @override
  String get tipoCombustivelGasolina => 'Gasoline';

  @override
  String get tipoCombustivelAlcool => 'Ethanol';

  @override
  String get tipoCombustivelFlex => 'Flex (gasoline + ethanol)';

  @override
  String get tipoCombustivelDiesel => 'Diesel';

  @override
  String get tipoCombustivelGnv => 'CNG';

  @override
  String get tipoCombustivelEletrico => 'Electric';

  @override
  String get filtroPeriodoUltimos30d => 'Last 30d';

  @override
  String get filtroPeriodoUltimos90d => 'Last 90d';

  @override
  String get filtroPeriodoUltimos12m => 'Last 12m';

  @override
  String get filtroPeriodoTudo => 'All time';

  @override
  String get manutencoesTitulo => 'Maintenance';

  @override
  String get manutencaoNovoTitulo => 'New maintenance';

  @override
  String get manutencaoEditarTitulo => 'Edit maintenance';

  @override
  String get manutencaoFab => 'New maintenance';

  @override
  String get manutencaoCampoTipo => 'Type';

  @override
  String get manutencaoCampoNomeLivre => 'Description';

  @override
  String get manutencaoCampoData => 'Date';

  @override
  String get manutencaoCampoKm => 'Odometer (km)';

  @override
  String get manutencaoCampoValor => 'Value (R\$) (optional)';

  @override
  String get manutencaoCampoOficina => 'Workshop (optional)';

  @override
  String get manutencaoCampoObservacoes => 'Notes (optional)';

  @override
  String get manutencaoProximoIntervalo => 'Next interval suggestion';

  @override
  String get manutencaoCampoProximoKm => 'Next km (suggestion)';

  @override
  String get manutencaoCampoProximoMeses => 'Months until next (suggestion)';

  @override
  String manutencaoNaoPossivel(String erro) {
    return 'Could not save: $erro';
  }

  @override
  String get manutencoesListaVazia =>
      'No maintenance recorded yet.\nTap \"New maintenance\" to get started.';

  @override
  String get semVeiculoCadastrarManutencao =>
      'Register a vehicle to start recording maintenance.';

  @override
  String get manutencoesAgruparPorTipo => 'Group by type';

  @override
  String manutencoesOutrosComDescricao(String descricao) {
    return '$descricao';
  }

  @override
  String get despesasTitulo => 'Expenses';

  @override
  String get despesaNovoTitulo => 'New expense';

  @override
  String get despesaEditarTitulo => 'Edit expense';

  @override
  String despesaNaoPossivel(String erro) {
    return 'Could not save: $erro';
  }

  @override
  String get semVeiculoCadastrarManutencaoForm =>
      'Register a vehicle before recording maintenance.';

  @override
  String get tipoManutencaoOleoMotor => 'Engine oil';

  @override
  String get tipoManutencaoFiltroOleo => 'Oil filter';

  @override
  String get tipoManutencaoFiltroAr => 'Air filter';

  @override
  String get tipoManutencaoFiltroCombustivel => 'Fuel filter';

  @override
  String get tipoManutencaoFiltroCabine => 'Cabin filter';

  @override
  String get tipoManutencaoVelas => 'Spark plugs';

  @override
  String get tipoManutencaoCorreiaDentada => 'Timing belt';

  @override
  String get tipoManutencaoCorreiaAcessorios => 'Accessory belt';

  @override
  String get tipoManutencaoPneus => 'Tires';

  @override
  String get tipoManutencaoAlinhamentoBalanceamento =>
      'Wheel alignment and balancing';

  @override
  String get tipoManutencaoPastilhasFreio => 'Brake pads';

  @override
  String get tipoManutencaoDiscosFreio => 'Brake discs';

  @override
  String get tipoManutencaoOleoCambio => 'Transmission oil';

  @override
  String get tipoManutencaoFluidoFreio => 'Brake fluid';

  @override
  String get tipoManutencaoRevisaoGeral => 'General service';

  @override
  String get tipoManutencaoRodizioPneus => 'Tire rotation';

  @override
  String get tipoManutencaoOutros => 'Other';

  @override
  String get despesaCampoNome => 'Name';

  @override
  String get despesaCampoCategoria => 'Category';

  @override
  String get despesaCampoValor => 'Amount (R\$)';

  @override
  String get despesaCampoFrequencia => 'Frequency';

  @override
  String get despesaCampoDiaDoMes => 'Day of month (1-28)';

  @override
  String get despesaCampoDiaDoMesHelper => 'Monthly/annual due day (max 28).';

  @override
  String get despesaCampoDataInicio => 'Start date';

  @override
  String get despesaCampoDataFim => 'End date (optional)';

  @override
  String get despesaDataFimVazia => 'No end date';

  @override
  String get despesaLimparDataFim => 'Clear end date';

  @override
  String get despesaCampoAtiva => 'Active';

  @override
  String get despesaCampoAtivaSubtitulo =>
      'Disable to suspend future occurrences.';

  @override
  String get semVeiculoCadastrarDespesaForm =>
      'Register a vehicle before recording expenses.';

  @override
  String get validacaoDiaDoMesInvalido => 'Invalid day (1-28)';

  @override
  String get categoriaDespesaLavagem => 'Car wash';

  @override
  String get categoriaDespesaEstacionamento => 'Parking';

  @override
  String get categoriaDespesaPedagio => 'Toll';

  @override
  String get categoriaDespesaFinanciamento => 'Financing';

  @override
  String get categoriaDespesaOutra => 'Other';

  @override
  String get frequenciaDespesaUnica => 'One-time';

  @override
  String get frequenciaDespesaSemanal => 'Weekly';

  @override
  String get frequenciaDespesaMensal => 'Monthly';

  @override
  String get frequenciaDespesaAnual => 'Annual';

  @override
  String get despesasListTitulo => 'Expenses';

  @override
  String get despesasListFab => 'New expense';

  @override
  String get despesasListVazia =>
      'No occurrences found.\nCreate a recurring expense to get started.';

  @override
  String get semVeiculoCadastrarDespesa =>
      'Register a vehicle to start recording expenses.';

  @override
  String get ocorrenciaStatusPendente => 'Pending';

  @override
  String get ocorrenciaStatusPaga => 'Paid';

  @override
  String get ocorrenciaStatusPulada => 'Skipped';

  @override
  String get ocorrenciaAcaoMarcarPaga => 'Mark as paid';

  @override
  String get ocorrenciaAcaoPular => 'Skip';

  @override
  String get ocorrenciaAcaoEditarValor => 'Edit paid amount';

  @override
  String get ocorrenciaDialogMarcarPagaTitulo => 'Mark as paid';

  @override
  String get ocorrenciaDialogEditarValorTitulo => 'Edit paid amount';

  @override
  String get ocorrenciaDialogCampoValor => 'Paid amount (R\$)';

  @override
  String get ocorrenciaDialogCampoData => 'Payment date';

  @override
  String get ocorrenciaDialogConfirmar => 'Confirm';

  @override
  String get ocorrenciaDialogCancelar => 'Cancel';

  @override
  String notifLembreteDataCorpo(String data) {
    return 'Due on $data';
  }

  @override
  String notifLembreteKmCorpo(int km) {
    final intl.NumberFormat kmNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kmString = kmNumberFormat.format(km);

    return 'Target odometer of $kmString km reached!';
  }

  @override
  String get lembretesTitle => 'Reminders';

  @override
  String get lembretesTabPendentes => 'Pending';

  @override
  String get lembretesTabAtrasados => 'Overdue';

  @override
  String get lembretesTabConcluidos => 'Done';

  @override
  String get lembretesVazioPendentes =>
      'No pending reminders.\nAdd reminders to get notified.';

  @override
  String get lembretesVazioAtrasados =>
      'No overdue reminders.\nAll up to date!';

  @override
  String get lembretesVazioConcluidos => 'No completed reminders yet.';

  @override
  String get lembretesFab => 'New reminder';

  @override
  String get lembretesStatusPendente => 'Pending';

  @override
  String get lembretesStatusConcluido => 'Done';

  @override
  String get lembretesStatusAdiado => 'Snoozed';

  @override
  String get lembretesEmBreve => 'Coming soon';

  @override
  String get lembreteDetalheTitulo => 'Reminder detail';

  @override
  String get lembreteDetalheNaoEncontrado => 'Reminder not found.';

  @override
  String get lembreteDetalheCampoVeiculo => 'Vehicle';

  @override
  String get lembreteDetalheCampoTipo => 'Type';

  @override
  String get lembreteDetalheCampoDescricao => 'Description';

  @override
  String get lembreteDetalheCampoDataAlvo => 'Target date';

  @override
  String get lembreteDetalheCampoKmAlvo => 'Target odometer';

  @override
  String get lembreteDetalheCampoStatus => 'Status';

  @override
  String get lembreteDetalheCampoManutencao => 'Associated maintenance';

  @override
  String get lembreteDetalheAcaoConcluir => 'Complete';

  @override
  String get lembreteDetalheAcaoAdiar => 'Snooze';

  @override
  String get lembreteDetalheAcaoExcluir => 'Delete';

  @override
  String get lembreteDetalheConcluirTitulo => 'Complete reminder';

  @override
  String get lembreteDetalheConcluirMensagem =>
      'Mark this reminder as completed?';

  @override
  String get lembreteDetalheConcluirRegistrarManutencao => 'Record maintenance';

  @override
  String get lembreteDetalheExcluirTitulo => 'Delete reminder';

  @override
  String get lembreteDetalheExcluirMensagem =>
      'Are you sure you want to delete this reminder? This action cannot be undone.';

  @override
  String get lembreteDetalheAdiarTitulo => 'Snooze reminder';

  @override
  String get lembreteDetalheAdiarDataAlvo => 'New target date (optional)';

  @override
  String get lembreteDetalheAdiarKmAlvo => 'New target odometer (optional)';

  @override
  String get lembreteDetalheAdiarSemCampos =>
      'Enter at least a date or odometer reading.';

  @override
  String get lembreteDetalheConcluido => 'Reminder completed.';

  @override
  String get lembreteDetalheAdiado => 'Reminder snoozed.';

  @override
  String get lembreteDetalheExcluido => 'Reminder deleted.';

  @override
  String lembreteDetalheErroAcao(String erro) {
    return 'Error executing action: $erro';
  }

  @override
  String get lembreteFormNovoTitulo => 'New reminder';

  @override
  String get lembreteFormEditarTitulo => 'Edit reminder';

  @override
  String get lembreteFormCampoDescricao => 'Description';

  @override
  String get lembreteFormCampoVeiculo => 'Vehicle';

  @override
  String get lembreteFormCampoDataAlvo => 'Target date (optional)';

  @override
  String get lembreteFormSemDataAlvo => 'Not set';

  @override
  String get lembreteFormLimparDataAlvo => 'Clear target date';

  @override
  String get lembreteFormCampoKmAlvo => 'Target km (optional)';

  @override
  String get lembreteFormValidacaoDataOuKm =>
      'Provide at least a target date or a target km';

  @override
  String get lembreteFormValidacaoDescricaoMin => 'Minimum 2 characters';

  @override
  String lembreteFormNaoPossivel(String erro) {
    return 'Could not save: $erro';
  }

  @override
  String get botaoCancelar => 'Cancel';

  @override
  String get botaoConfirmar => 'Confirm';

  @override
  String get botaoSelecionar => 'Select';

  @override
  String get lembreteDetalheSemData => 'Not defined';

  @override
  String get lembreteDetalheSemKm => 'Not defined';

  @override
  String get lembreteDetalheSemManutencao => 'None';

  @override
  String lembreteDetalheManutencaoId(int id) {
    return 'ID $id';
  }

  @override
  String get semVeiculoCadastrarLembreteForm =>
      'Register a vehicle before creating reminders.';

  @override
  String get exportarDadosTitulo => 'Export data';

  @override
  String get exportarDadosSubtitulo =>
      'Generates CSV files with all vehicle records';

  @override
  String get exportarBotao => 'Export CSV';

  @override
  String get exportarSemVeiculo => 'Select a vehicle to export.';

  @override
  String get exportarSucesso => 'Files exported successfully!';

  @override
  String exportarErro(String erro) {
    return 'Export error: $erro';
  }

  @override
  String exportarShareSubject(String placa) {
    return 'Carro na Mão — $placa';
  }

  @override
  String get graficosTooltip => 'Charts';

  @override
  String get graficosTitulo => 'Charts';

  @override
  String get graficosGastosEvolucao => 'Expense evolution (last 12 months)';

  @override
  String get graficosConsumoEvolucao =>
      'Avg. consumption km/l (last 12 months)';

  @override
  String get graficosDistribuicao =>
      'Distribution by category (last 12 months)';

  @override
  String get graficosSemDadosGastos =>
      'No expenses recorded in the last 12 months.';

  @override
  String get graficosSemDadosConsumo =>
      'Insufficient data.\nRecord full-tank fuel-ups to see consumption.';

  @override
  String get graficosSemDadosDistribuicao =>
      'No expenses in the last 12 months.';

  @override
  String get graficosLegendaAbastec => 'Fuel';

  @override
  String get graficosLegendaManut => 'Maint.';

  @override
  String get graficosLegendaDespesas => 'Expenses';

  @override
  String get a11ySalvando => 'Saving';

  @override
  String get a11yToquePAraAbrir => 'Tap to open the picker';

  @override
  String get configuracoesPrivacidadeTitulo => 'Privacy policy';

  @override
  String get configuracoesPrivacidadeSubtitulo =>
      'Zero data collection · data stays on device';

  @override
  String get configuracoesPrivacidadeUrl =>
      'https://lucasengecomp.github.io/carr0-na-mao/privacidade/';
}
