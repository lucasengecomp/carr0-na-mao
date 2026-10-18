// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Carro na Mão';

  @override
  String get appSubtitulo => 'Gastos, consumo e lembretes em um só lugar.';

  @override
  String get tooltipComparador => 'Comparador';

  @override
  String get tooltipConfiguracoes => 'Configurações';

  @override
  String get tooltipTrocarVeiculo => 'Trocar veículo';

  @override
  String get navHome => 'Home';

  @override
  String get navAbastecer => 'Abastecer';

  @override
  String get navManutencao => 'Manutenção';

  @override
  String get navDespesas => 'Despesas';

  @override
  String get navLembretes => 'Lembretes';

  @override
  String get abastecimentosTitulo => 'Abastecimentos';

  @override
  String get abastecimentoNovoTitulo => 'Novo abastecimento';

  @override
  String get abastecimentoEditarTitulo => 'Editar abastecimento';

  @override
  String get abastecimentoFab => 'Abastecer';

  @override
  String get abastecimentoListaVaziaFiltro =>
      'Nenhum abastecimento encontrado para os filtros selecionados.';

  @override
  String get abastecimentoListaVazia =>
      'Nenhum abastecimento registrado ainda.\nToque em \"Abastecer\" para começar.';

  @override
  String get semVeiculoCadastrarAbastecimento =>
      'Cadastre um veículo para começar a registrar abastecimentos.';

  @override
  String get semVeiculoCadastrarAbastecimentoForm =>
      'Cadastre um veículo antes de registrar abastecimentos.';

  @override
  String get botaoCadastrarVeiculo => 'Cadastrar veículo';

  @override
  String erroGenerico(String mensagem) {
    return 'Erro: $mensagem';
  }

  @override
  String get abastecimentoCampoData => 'Data';

  @override
  String get abastecimentoCampoHodometro => 'Hodômetro (km)';

  @override
  String get abastecimentoCampoCombustivel => 'Combustível';

  @override
  String get abastecimentoCampoPreco => 'Preço por litro (R\$)';

  @override
  String get abastecimentoCampoPrecoHelper =>
      'Preencha 2 dos 3 e o terceiro é calculado.';

  @override
  String get abastecimentoCampoLitros => 'Litros';

  @override
  String get abastecimentoCampoValorTotal => 'Valor total (R\$)';

  @override
  String get abastecimentoCampoPosto => 'Posto (opcional)';

  @override
  String get abastecimentoTanqueCheio => 'Tanque cheio';

  @override
  String get abastecimentoTanqueCheioSubtitulo =>
      'Importante para cálculo de consumo (km/L).';

  @override
  String get abastecimentoAvisoKmRetroativo =>
      'O km informado é menor que o último registrado. Você pode salvar normalmente se for um abastecimento retroativo.';

  @override
  String abastecimentoNaoPossivel(String erro) {
    return 'Não foi possível salvar: $erro';
  }

  @override
  String get validacaoObrigatorio => 'Obrigatório';

  @override
  String get validacaoKmInvalido => 'Km inválido';

  @override
  String get validacaoDecimalObrigatorio => 'Preencha 2 dos 3 campos';

  @override
  String get validacaoValorInvalido => 'Valor inválido';

  @override
  String get botaoSalvar => 'Salvar';

  @override
  String get veiculosTitulo => 'Veículos';

  @override
  String get veiculoNovoTitulo => 'Novo veículo';

  @override
  String get veiculoEditarTitulo => 'Editar veículo';

  @override
  String get veiculoFab => 'Novo veículo';

  @override
  String get veiculoAtivos => 'Ativos';

  @override
  String get veiculoArquivados => 'Arquivados';

  @override
  String get veiculoNenhumAtivo =>
      'Nenhum veículo cadastrado. Toque em \"Novo veículo\" para começar.';

  @override
  String get veiculoNenhumArquivado => 'Nenhum veículo arquivado.';

  @override
  String veiculoErroCarregar(String erro) {
    return 'Erro ao carregar: $erro';
  }

  @override
  String get veiculoMenuEditar => 'Editar';

  @override
  String get veiculoMenuArquivar => 'Arquivar';

  @override
  String get veiculoMenuRestaurar => 'Restaurar';

  @override
  String veiculoArquivadoSnack(String placa) {
    return '$placa arquivado';
  }

  @override
  String veiculoRestauradoSnack(String placa) {
    return '$placa restaurado';
  }

  @override
  String get veiculoCampoPlaca => 'Placa';

  @override
  String get veiculoCampoPlacaHelper =>
      'Mercosul (ABC1D23) ou antigo (ABC1234)';

  @override
  String get veiculoCampoApelido => 'Apelido (opcional)';

  @override
  String get veiculoCampoMarca => 'Marca';

  @override
  String get veiculoCampoMarcaHelper =>
      'Sugestões da base. Pode digitar livremente.';

  @override
  String get veiculoCampoModelo => 'Modelo';

  @override
  String get veiculoCampoModeloHelperSemSugestoes =>
      'Digite livremente (sem sugestões para esta marca).';

  @override
  String get veiculoCampoModeloHelperComSugestoes =>
      'Sugestões da base. Pode digitar livremente.';

  @override
  String get veiculoCampoAno => 'Ano';

  @override
  String get veiculoCampoTipo => 'Tipo';

  @override
  String get veiculoCampoCombustivel => 'Combustível';

  @override
  String get veiculoCampoHodometro => 'Hodômetro atual (km)';

  @override
  String get veiculoPlacaExistente => 'Já existe um veículo com essa placa.';

  @override
  String veiculoNaoPossivel(String erro) {
    return 'Não foi possível salvar: $erro';
  }

  @override
  String get validacaoAnoInvalido => 'Ano inválido';

  @override
  String get validacaoAnoForaDaFaixa => 'Ano fora da faixa';

  @override
  String get comparadorTitulo => 'Comparador álcool × gasolina';

  @override
  String get comparadorCampoVeiculo => 'Veículo';

  @override
  String get comparadorCampoAlcool => 'Preço do álcool (R\$/L)';

  @override
  String get comparadorCampoGasolina => 'Preço da gasolina (R\$/L)';

  @override
  String get comparadorBotao => 'Comparar';

  @override
  String get comparadorSemVeiculo => 'Selecione um veículo.';

  @override
  String get comparadorSemVeiculoCadastrado =>
      'Cadastre um veículo primeiro para usar o comparador.';

  @override
  String get comparadorAlcoolCompensa => 'Álcool compensa';

  @override
  String get comparadorGasolinaCompensa => 'Gasolina compensa';

  @override
  String get comparadorEmpate => 'Empate técnico';

  @override
  String get comparadorMetodoHistorico => 'Baseado no histórico do veículo';

  @override
  String get comparadorMetodoRegra70 => 'Regra dos 70%';

  @override
  String get comparadorSemHistoricoTexto =>
      'Sem histórico suficiente de abastecimentos com tanque cheio para calcular o custo por km. Resultado baseado na regra empírica de 70%.';

  @override
  String get comparadorPrefixoPreco => 'R\$ ';

  @override
  String get configuracoesTitulo => 'Configurações';

  @override
  String get configuracoesVeiculosTitulo => 'Veículos';

  @override
  String get configuracoesVeiculosSubtitulo => 'Cadastrar, editar e arquivar';

  @override
  String get filtroTodos => 'Todos';

  @override
  String get tipoVeiculoCarro => 'Carro';

  @override
  String get tipoVeiculoMoto => 'Moto';

  @override
  String get tipoCombustivelGasolina => 'Gasolina';

  @override
  String get tipoCombustivelAlcool => 'Álcool';

  @override
  String get tipoCombustivelFlex => 'Flex (gasolina + álcool)';

  @override
  String get tipoCombustivelDiesel => 'Diesel';

  @override
  String get tipoCombustivelGnv => 'GNV';

  @override
  String get tipoCombustivelEletrico => 'Elétrico';

  @override
  String get filtroPeriodoUltimos30d => 'Últimos 30d';

  @override
  String get filtroPeriodoUltimos90d => 'Últimos 90d';

  @override
  String get filtroPeriodoUltimos12m => 'Últimos 12m';

  @override
  String get filtroPeriodoTudo => 'Tudo';

  @override
  String get manutencoesTitulo => 'Manutenções';

  @override
  String get manutencaoNovoTitulo => 'Nova manutenção';

  @override
  String get manutencaoEditarTitulo => 'Editar manutenção';

  @override
  String get manutencaoFab => 'Nova manutenção';

  @override
  String get manutencaoCampoTipo => 'Tipo';

  @override
  String get manutencaoCampoNomeLivre => 'Descrição';

  @override
  String get manutencaoCampoData => 'Data';

  @override
  String get manutencaoCampoKm => 'Hodômetro (km)';

  @override
  String get manutencaoCampoValor => 'Valor (R\$) (opcional)';

  @override
  String get manutencaoCampoOficina => 'Oficina (opcional)';

  @override
  String get manutencaoCampoObservacoes => 'Observações (opcional)';

  @override
  String get manutencaoProximoIntervalo => 'Sugestão de próximo intervalo';

  @override
  String get manutencaoCampoProximoKm => 'Próximo km (sugestão)';

  @override
  String get manutencaoCampoProximoMeses => 'Meses até o próximo (sugestão)';

  @override
  String manutencaoNaoPossivel(String erro) {
    return 'Não foi possível salvar: $erro';
  }

  @override
  String get despesasTitulo => 'Despesas';

  @override
  String get despesaNovoTitulo => 'Nova despesa';

  @override
  String get despesaEditarTitulo => 'Editar despesa';

  @override
  String despesaNaoPossivel(String erro) {
    return 'Não foi possível salvar: $erro';
  }

  @override
  String get semVeiculoCadastrarManutencaoForm =>
      'Cadastre um veículo antes de registrar manutenções.';

  @override
  String get tipoManutencaoOleoMotor => 'Óleo do motor';

  @override
  String get tipoManutencaoFiltroOleo => 'Filtro de óleo';

  @override
  String get tipoManutencaoFiltroAr => 'Filtro de ar';

  @override
  String get tipoManutencaoFiltroCombustivel => 'Filtro de combustível';

  @override
  String get tipoManutencaoFiltroCabine => 'Filtro de cabine';

  @override
  String get tipoManutencaoVelas => 'Velas de ignição';

  @override
  String get tipoManutencaoCorreiaDentada => 'Correia dentada';

  @override
  String get tipoManutencaoCorreiaAcessorios => 'Correia de acessórios';

  @override
  String get tipoManutencaoPneus => 'Pneus';

  @override
  String get tipoManutencaoAlinhamentoBalanceamento =>
      'Alinhamento e balanceamento';

  @override
  String get tipoManutencaoPastilhasFreio => 'Pastilhas de freio';

  @override
  String get tipoManutencaoDiscosFreio => 'Discos de freio';

  @override
  String get tipoManutencaoOleoCambio => 'Óleo do câmbio';

  @override
  String get tipoManutencaoFluidoFreio => 'Fluido de freio';

  @override
  String get tipoManutencaoRevisaoGeral => 'Revisão geral';

  @override
  String get tipoManutencaoRodizioPneus => 'Rodízio de pneus';

  @override
  String get tipoManutencaoOutros => 'Outros';

  @override
  String get despesaCampoNome => 'Nome';

  @override
  String get despesaCampoCategoria => 'Categoria';

  @override
  String get despesaCampoValor => 'Valor (R\$)';

  @override
  String get despesaCampoFrequencia => 'Frequência';

  @override
  String get despesaCampoDiaDoMes => 'Dia do mês (1-28)';

  @override
  String get despesaCampoDiaDoMesHelper =>
      'Dia de vencimento mensal/anual (máx. 28).';

  @override
  String get despesaCampoDataInicio => 'Data de início';

  @override
  String get despesaCampoDataFim => 'Data de fim (opcional)';

  @override
  String get despesaDataFimVazia => 'Sem data de fim';

  @override
  String get despesaLimparDataFim => 'Limpar data de fim';

  @override
  String get despesaCampoAtiva => 'Ativa';

  @override
  String get despesaCampoAtivaSubtitulo =>
      'Desative para suspender as ocorrências futuras.';

  @override
  String get semVeiculoCadastrarDespesaForm =>
      'Cadastre um veículo antes de registrar despesas.';

  @override
  String get validacaoDiaDoMesInvalido => 'Dia inválido (1-28)';

  @override
  String get categoriaDespesaLavagem => 'Lavagem';

  @override
  String get categoriaDespesaEstacionamento => 'Estacionamento';

  @override
  String get categoriaDespesaPedagio => 'Pedágio';

  @override
  String get categoriaDespesaFinanciamento => 'Financiamento';

  @override
  String get categoriaDespesaOutra => 'Outra';

  @override
  String get frequenciaDespesaUnica => 'Única';

  @override
  String get frequenciaDespesaSemanal => 'Semanal';

  @override
  String get frequenciaDespesaMensal => 'Mensal';

  @override
  String get frequenciaDespesaAnual => 'Anual';

  @override
  String notifLembreteDataCorpo(String data) {
    return 'Vence em $data';
  }

  @override
  String notifLembreteKmCorpo(int km) {
    final intl.NumberFormat kmNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kmString = kmNumberFormat.format(km);

    return 'Km alvo de $kmString atingido!';
  }
}
