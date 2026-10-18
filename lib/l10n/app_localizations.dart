import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// Nome do aplicativo exibido na AppBar da Home
  ///
  /// In pt, this message translates to:
  /// **'Carro na Mão'**
  String get appTitle;

  /// Subtítulo exibido na tela Home
  ///
  /// In pt, this message translates to:
  /// **'Gastos, consumo e lembretes em um só lugar.'**
  String get appSubtitulo;

  /// Tooltip do botão de comparador na AppBar
  ///
  /// In pt, this message translates to:
  /// **'Comparador'**
  String get tooltipComparador;

  /// Tooltip do botão de configurações na AppBar
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get tooltipConfiguracoes;

  /// Tooltip do menu popup de seleção de veículo
  ///
  /// In pt, this message translates to:
  /// **'Trocar veículo'**
  String get tooltipTrocarVeiculo;

  /// Label da aba Home na NavigationBar
  ///
  /// In pt, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Label da aba Abastecer na NavigationBar
  ///
  /// In pt, this message translates to:
  /// **'Abastecer'**
  String get navAbastecer;

  /// Label da aba Manutenção na NavigationBar
  ///
  /// In pt, this message translates to:
  /// **'Manutenção'**
  String get navManutencao;

  /// Label da aba Despesas na NavigationBar
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get navDespesas;

  /// Label da aba Lembretes na NavigationBar
  ///
  /// In pt, this message translates to:
  /// **'Lembretes'**
  String get navLembretes;

  /// Título da tela de lista de abastecimentos
  ///
  /// In pt, this message translates to:
  /// **'Abastecimentos'**
  String get abastecimentosTitulo;

  /// Título da tela de novo abastecimento
  ///
  /// In pt, this message translates to:
  /// **'Novo abastecimento'**
  String get abastecimentoNovoTitulo;

  /// Título da tela de editar abastecimento
  ///
  /// In pt, this message translates to:
  /// **'Editar abastecimento'**
  String get abastecimentoEditarTitulo;

  /// Label do FAB da tela de abastecimentos
  ///
  /// In pt, this message translates to:
  /// **'Abastecer'**
  String get abastecimentoFab;

  /// Mensagem de lista vazia na tela com filtros
  ///
  /// In pt, this message translates to:
  /// **'Nenhum abastecimento encontrado para os filtros selecionados.'**
  String get abastecimentoListaVaziaFiltro;

  /// Mensagem de lista vazia na tela simples de abastecimentos
  ///
  /// In pt, this message translates to:
  /// **'Nenhum abastecimento registrado ainda.\nToque em \"Abastecer\" para começar.'**
  String get abastecimentoListaVazia;

  /// Aviso exibido quando não há veículo cadastrado na tela de abastecimentos
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um veículo para começar a registrar abastecimentos.'**
  String get semVeiculoCadastrarAbastecimento;

  /// Aviso exibido no form de abastecimento quando não há veículo
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um veículo antes de registrar abastecimentos.'**
  String get semVeiculoCadastrarAbastecimentoForm;

  /// Label do botão de cadastrar veículo
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar veículo'**
  String get botaoCadastrarVeiculo;

  /// Mensagem de erro genérica
  ///
  /// In pt, this message translates to:
  /// **'Erro: {mensagem}'**
  String erroGenerico(String mensagem);

  /// Label do campo Data no form de abastecimento
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get abastecimentoCampoData;

  /// Label do campo Hodômetro no form de abastecimento
  ///
  /// In pt, this message translates to:
  /// **'Hodômetro (km)'**
  String get abastecimentoCampoHodometro;

  /// Label do campo Combustível no form de abastecimento
  ///
  /// In pt, this message translates to:
  /// **'Combustível'**
  String get abastecimentoCampoCombustivel;

  /// Label do campo Preço por litro no form de abastecimento
  ///
  /// In pt, this message translates to:
  /// **'Preço por litro (R\$)'**
  String get abastecimentoCampoPreco;

  /// Texto auxiliar do campo Preço no form de abastecimento
  ///
  /// In pt, this message translates to:
  /// **'Preencha 2 dos 3 e o terceiro é calculado.'**
  String get abastecimentoCampoPrecoHelper;

  /// Label do campo Litros no form de abastecimento
  ///
  /// In pt, this message translates to:
  /// **'Litros'**
  String get abastecimentoCampoLitros;

  /// Label do campo Valor total no form de abastecimento
  ///
  /// In pt, this message translates to:
  /// **'Valor total (R\$)'**
  String get abastecimentoCampoValorTotal;

  /// Label do campo Posto no form de abastecimento
  ///
  /// In pt, this message translates to:
  /// **'Posto (opcional)'**
  String get abastecimentoCampoPosto;

  /// Label do switch de tanque cheio
  ///
  /// In pt, this message translates to:
  /// **'Tanque cheio'**
  String get abastecimentoTanqueCheio;

  /// Subtítulo do switch de tanque cheio
  ///
  /// In pt, this message translates to:
  /// **'Importante para cálculo de consumo (km/L).'**
  String get abastecimentoTanqueCheioSubtitulo;

  /// Aviso banner de km retroativo
  ///
  /// In pt, this message translates to:
  /// **'O km informado é menor que o último registrado. Você pode salvar normalmente se for um abastecimento retroativo.'**
  String get abastecimentoAvisoKmRetroativo;

  /// Snackbar de erro ao salvar abastecimento
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar: {erro}'**
  String abastecimentoNaoPossivel(String erro);

  /// Mensagem de validação de campo obrigatório
  ///
  /// In pt, this message translates to:
  /// **'Obrigatório'**
  String get validacaoObrigatorio;

  /// Mensagem de validação de km inválido
  ///
  /// In pt, this message translates to:
  /// **'Km inválido'**
  String get validacaoKmInvalido;

  /// Mensagem de validação quando campo decimal está vazio
  ///
  /// In pt, this message translates to:
  /// **'Preencha 2 dos 3 campos'**
  String get validacaoDecimalObrigatorio;

  /// Mensagem de validação de valor inválido
  ///
  /// In pt, this message translates to:
  /// **'Valor inválido'**
  String get validacaoValorInvalido;

  /// Label do botão Salvar
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get botaoSalvar;

  /// Título da tela de lista de veículos
  ///
  /// In pt, this message translates to:
  /// **'Veículos'**
  String get veiculosTitulo;

  /// Título da tela de novo veículo
  ///
  /// In pt, this message translates to:
  /// **'Novo veículo'**
  String get veiculoNovoTitulo;

  /// Título da tela de editar veículo
  ///
  /// In pt, this message translates to:
  /// **'Editar veículo'**
  String get veiculoEditarTitulo;

  /// Label do FAB da tela de veículos
  ///
  /// In pt, this message translates to:
  /// **'Novo veículo'**
  String get veiculoFab;

  /// Segmento Ativos no toggle de veículos
  ///
  /// In pt, this message translates to:
  /// **'Ativos'**
  String get veiculoAtivos;

  /// Segmento Arquivados no toggle de veículos
  ///
  /// In pt, this message translates to:
  /// **'Arquivados'**
  String get veiculoArquivados;

  /// Mensagem de empty state para veículos ativos
  ///
  /// In pt, this message translates to:
  /// **'Nenhum veículo cadastrado. Toque em \"Novo veículo\" para começar.'**
  String get veiculoNenhumAtivo;

  /// Mensagem de empty state para veículos arquivados
  ///
  /// In pt, this message translates to:
  /// **'Nenhum veículo arquivado.'**
  String get veiculoNenhumArquivado;

  /// Erro ao carregar lista de veículos
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar: {erro}'**
  String veiculoErroCarregar(String erro);

  /// Opção Editar no menu de veículo
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get veiculoMenuEditar;

  /// Opção Arquivar no menu de veículo
  ///
  /// In pt, this message translates to:
  /// **'Arquivar'**
  String get veiculoMenuArquivar;

  /// Opção Restaurar no menu de veículo
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get veiculoMenuRestaurar;

  /// Snackbar ao arquivar veículo
  ///
  /// In pt, this message translates to:
  /// **'{placa} arquivado'**
  String veiculoArquivadoSnack(String placa);

  /// Snackbar ao restaurar veículo
  ///
  /// In pt, this message translates to:
  /// **'{placa} restaurado'**
  String veiculoRestauradoSnack(String placa);

  /// Label do campo Placa no form de veículo
  ///
  /// In pt, this message translates to:
  /// **'Placa'**
  String get veiculoCampoPlaca;

  /// Helper text do campo Placa
  ///
  /// In pt, this message translates to:
  /// **'Mercosul (ABC1D23) ou antigo (ABC1234)'**
  String get veiculoCampoPlacaHelper;

  /// Label do campo Apelido no form de veículo
  ///
  /// In pt, this message translates to:
  /// **'Apelido (opcional)'**
  String get veiculoCampoApelido;

  /// Label do campo Marca no form de veículo
  ///
  /// In pt, this message translates to:
  /// **'Marca'**
  String get veiculoCampoMarca;

  /// Helper text do campo Marca
  ///
  /// In pt, this message translates to:
  /// **'Sugestões da base. Pode digitar livremente.'**
  String get veiculoCampoMarcaHelper;

  /// Label do campo Modelo no form de veículo
  ///
  /// In pt, this message translates to:
  /// **'Modelo'**
  String get veiculoCampoModelo;

  /// Helper text do campo Modelo quando sem sugestões
  ///
  /// In pt, this message translates to:
  /// **'Digite livremente (sem sugestões para esta marca).'**
  String get veiculoCampoModeloHelperSemSugestoes;

  /// Helper text do campo Modelo quando com sugestões
  ///
  /// In pt, this message translates to:
  /// **'Sugestões da base. Pode digitar livremente.'**
  String get veiculoCampoModeloHelperComSugestoes;

  /// Label do campo Ano no form de veículo
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get veiculoCampoAno;

  /// Label do campo Tipo no form de veículo
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get veiculoCampoTipo;

  /// Label do campo Combustível no form de veículo
  ///
  /// In pt, this message translates to:
  /// **'Combustível'**
  String get veiculoCampoCombustivel;

  /// Label do campo Hodômetro no form de veículo
  ///
  /// In pt, this message translates to:
  /// **'Hodômetro atual (km)'**
  String get veiculoCampoHodometro;

  /// Erro de placa duplicada
  ///
  /// In pt, this message translates to:
  /// **'Já existe um veículo com essa placa.'**
  String get veiculoPlacaExistente;

  /// Snackbar de erro ao salvar veículo
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar: {erro}'**
  String veiculoNaoPossivel(String erro);

  /// Mensagem de validação de ano inválido
  ///
  /// In pt, this message translates to:
  /// **'Ano inválido'**
  String get validacaoAnoInvalido;

  /// Mensagem de validação de ano fora da faixa
  ///
  /// In pt, this message translates to:
  /// **'Ano fora da faixa'**
  String get validacaoAnoForaDaFaixa;

  /// Título da tela do comparador
  ///
  /// In pt, this message translates to:
  /// **'Comparador álcool × gasolina'**
  String get comparadorTitulo;

  /// Label do dropdown de veículo no comparador
  ///
  /// In pt, this message translates to:
  /// **'Veículo'**
  String get comparadorCampoVeiculo;

  /// Label do campo preço do álcool
  ///
  /// In pt, this message translates to:
  /// **'Preço do álcool (R\$/L)'**
  String get comparadorCampoAlcool;

  /// Label do campo preço da gasolina
  ///
  /// In pt, this message translates to:
  /// **'Preço da gasolina (R\$/L)'**
  String get comparadorCampoGasolina;

  /// Label do botão Comparar
  ///
  /// In pt, this message translates to:
  /// **'Comparar'**
  String get comparadorBotao;

  /// Snackbar quando não há veículo selecionado no comparador
  ///
  /// In pt, this message translates to:
  /// **'Selecione um veículo.'**
  String get comparadorSemVeiculo;

  /// Mensagem de empty state no comparador
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um veículo primeiro para usar o comparador.'**
  String get comparadorSemVeiculoCadastrado;

  /// Resultado do comparador: álcool vence
  ///
  /// In pt, this message translates to:
  /// **'Álcool compensa'**
  String get comparadorAlcoolCompensa;

  /// Resultado do comparador: gasolina vence
  ///
  /// In pt, this message translates to:
  /// **'Gasolina compensa'**
  String get comparadorGasolinaCompensa;

  /// Resultado do comparador: empate
  ///
  /// In pt, this message translates to:
  /// **'Empate técnico'**
  String get comparadorEmpate;

  /// Badge de método histórico no comparador
  ///
  /// In pt, this message translates to:
  /// **'Baseado no histórico do veículo'**
  String get comparadorMetodoHistorico;

  /// Badge de método regra 70% no comparador
  ///
  /// In pt, this message translates to:
  /// **'Regra dos 70%'**
  String get comparadorMetodoRegra70;

  /// Texto exibido quando não há histórico para calcular
  ///
  /// In pt, this message translates to:
  /// **'Sem histórico suficiente de abastecimentos com tanque cheio para calcular o custo por km. Resultado baseado na regra empírica de 70%.'**
  String get comparadorSemHistoricoTexto;

  /// Prefixo dos campos de preço no comparador
  ///
  /// In pt, this message translates to:
  /// **'R\$ '**
  String get comparadorPrefixoPreco;

  /// Título da tela de configurações
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get configuracoesTitulo;

  /// Título do item Veículos nas configurações
  ///
  /// In pt, this message translates to:
  /// **'Veículos'**
  String get configuracoesVeiculosTitulo;

  /// Subtítulo do item Veículos nas configurações
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar, editar e arquivar'**
  String get configuracoesVeiculosSubtitulo;

  /// Chip de filtro Todos (combustível)
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get filtroTodos;

  /// Label do tipo de veículo Carro
  ///
  /// In pt, this message translates to:
  /// **'Carro'**
  String get tipoVeiculoCarro;

  /// Label do tipo de veículo Moto
  ///
  /// In pt, this message translates to:
  /// **'Moto'**
  String get tipoVeiculoMoto;

  /// Label do combustível Gasolina
  ///
  /// In pt, this message translates to:
  /// **'Gasolina'**
  String get tipoCombustivelGasolina;

  /// Label do combustível Álcool
  ///
  /// In pt, this message translates to:
  /// **'Álcool'**
  String get tipoCombustivelAlcool;

  /// Label do combustível Flex
  ///
  /// In pt, this message translates to:
  /// **'Flex (gasolina + álcool)'**
  String get tipoCombustivelFlex;

  /// Label do combustível Diesel
  ///
  /// In pt, this message translates to:
  /// **'Diesel'**
  String get tipoCombustivelDiesel;

  /// Label do combustível GNV
  ///
  /// In pt, this message translates to:
  /// **'GNV'**
  String get tipoCombustivelGnv;

  /// Label do combustível Elétrico
  ///
  /// In pt, this message translates to:
  /// **'Elétrico'**
  String get tipoCombustivelEletrico;

  /// Label do filtro de período Últimos 30 dias
  ///
  /// In pt, this message translates to:
  /// **'Últimos 30d'**
  String get filtroPeriodoUltimos30d;

  /// Label do filtro de período Últimos 90 dias
  ///
  /// In pt, this message translates to:
  /// **'Últimos 90d'**
  String get filtroPeriodoUltimos90d;

  /// Label do filtro de período Últimos 12 meses
  ///
  /// In pt, this message translates to:
  /// **'Últimos 12m'**
  String get filtroPeriodoUltimos12m;

  /// Label do filtro de período Tudo
  ///
  /// In pt, this message translates to:
  /// **'Tudo'**
  String get filtroPeriodoTudo;

  /// Título da tela de lista de manutenções
  ///
  /// In pt, this message translates to:
  /// **'Manutenções'**
  String get manutencoesTitulo;

  /// Título da tela de nova manutenção
  ///
  /// In pt, this message translates to:
  /// **'Nova manutenção'**
  String get manutencaoNovoTitulo;

  /// Título da tela de editar manutenção
  ///
  /// In pt, this message translates to:
  /// **'Editar manutenção'**
  String get manutencaoEditarTitulo;

  /// Label do FAB da tela de manutenções
  ///
  /// In pt, this message translates to:
  /// **'Nova manutenção'**
  String get manutencaoFab;

  /// Label do campo Tipo no form de manutenção
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get manutencaoCampoTipo;

  /// Label do campo Descrição (nome_livre) no form de manutenção
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get manutencaoCampoNomeLivre;

  /// Label do campo Data no form de manutenção
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get manutencaoCampoData;

  /// Label do campo Hodômetro no form de manutenção
  ///
  /// In pt, this message translates to:
  /// **'Hodômetro (km)'**
  String get manutencaoCampoKm;

  /// Label do campo Valor no form de manutenção
  ///
  /// In pt, this message translates to:
  /// **'Valor (R\$) (opcional)'**
  String get manutencaoCampoValor;

  /// Label do campo Oficina no form de manutenção
  ///
  /// In pt, this message translates to:
  /// **'Oficina (opcional)'**
  String get manutencaoCampoOficina;

  /// Label do campo Observações no form de manutenção
  ///
  /// In pt, this message translates to:
  /// **'Observações (opcional)'**
  String get manutencaoCampoObservacoes;

  /// Título da seção de sugestão de próximo intervalo
  ///
  /// In pt, this message translates to:
  /// **'Sugestão de próximo intervalo'**
  String get manutencaoProximoIntervalo;

  /// Label do campo Próximo km no form de manutenção
  ///
  /// In pt, this message translates to:
  /// **'Próximo km (sugestão)'**
  String get manutencaoCampoProximoKm;

  /// Label do campo Próximo em meses no form de manutenção
  ///
  /// In pt, this message translates to:
  /// **'Meses até o próximo (sugestão)'**
  String get manutencaoCampoProximoMeses;

  /// Snackbar de erro ao salvar manutenção
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar: {erro}'**
  String manutencaoNaoPossivel(String erro);

  /// Mensagem de lista vazia na tela de manutenções
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma manutenção registrada ainda.\nToque em \"Nova manutenção\" para começar.'**
  String get manutencoesListaVazia;

  /// Aviso exibido quando não há veículo cadastrado na tela de manutenções
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um veículo para começar a registrar manutenções.'**
  String get semVeiculoCadastrarManutencao;

  /// Label do switch de agrupamento por tipo na tela de manutenções
  ///
  /// In pt, this message translates to:
  /// **'Agrupar por tipo'**
  String get manutencoesAgruparPorTipo;

  /// Exibição do nome livre quando tipo é 'outros'
  ///
  /// In pt, this message translates to:
  /// **'{descricao}'**
  String manutencoesOutrosComDescricao(String descricao);

  /// Título da tela de lista de despesas
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get despesasTitulo;

  /// Título da tela de nova despesa recorrente
  ///
  /// In pt, this message translates to:
  /// **'Nova despesa'**
  String get despesaNovoTitulo;

  /// Título da tela de editar despesa recorrente
  ///
  /// In pt, this message translates to:
  /// **'Editar despesa'**
  String get despesaEditarTitulo;

  /// Snackbar de erro ao salvar despesa
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar: {erro}'**
  String despesaNaoPossivel(String erro);

  /// Aviso exibido no form de manutenção quando não há veículo
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um veículo antes de registrar manutenções.'**
  String get semVeiculoCadastrarManutencaoForm;

  /// Label do tipo de manutenção Óleo do motor
  ///
  /// In pt, this message translates to:
  /// **'Óleo do motor'**
  String get tipoManutencaoOleoMotor;

  /// Label do tipo de manutenção Filtro de óleo
  ///
  /// In pt, this message translates to:
  /// **'Filtro de óleo'**
  String get tipoManutencaoFiltroOleo;

  /// Label do tipo de manutenção Filtro de ar
  ///
  /// In pt, this message translates to:
  /// **'Filtro de ar'**
  String get tipoManutencaoFiltroAr;

  /// Label do tipo de manutenção Filtro de combustível
  ///
  /// In pt, this message translates to:
  /// **'Filtro de combustível'**
  String get tipoManutencaoFiltroCombustivel;

  /// Label do tipo de manutenção Filtro de cabine
  ///
  /// In pt, this message translates to:
  /// **'Filtro de cabine'**
  String get tipoManutencaoFiltroCabine;

  /// Label do tipo de manutenção Velas de ignição
  ///
  /// In pt, this message translates to:
  /// **'Velas de ignição'**
  String get tipoManutencaoVelas;

  /// Label do tipo de manutenção Correia dentada
  ///
  /// In pt, this message translates to:
  /// **'Correia dentada'**
  String get tipoManutencaoCorreiaDentada;

  /// Label do tipo de manutenção Correia de acessórios
  ///
  /// In pt, this message translates to:
  /// **'Correia de acessórios'**
  String get tipoManutencaoCorreiaAcessorios;

  /// Label do tipo de manutenção Pneus
  ///
  /// In pt, this message translates to:
  /// **'Pneus'**
  String get tipoManutencaoPneus;

  /// Label do tipo de manutenção Alinhamento e balanceamento
  ///
  /// In pt, this message translates to:
  /// **'Alinhamento e balanceamento'**
  String get tipoManutencaoAlinhamentoBalanceamento;

  /// Label do tipo de manutenção Pastilhas de freio
  ///
  /// In pt, this message translates to:
  /// **'Pastilhas de freio'**
  String get tipoManutencaoPastilhasFreio;

  /// Label do tipo de manutenção Discos de freio
  ///
  /// In pt, this message translates to:
  /// **'Discos de freio'**
  String get tipoManutencaoDiscosFreio;

  /// Label do tipo de manutenção Óleo do câmbio
  ///
  /// In pt, this message translates to:
  /// **'Óleo do câmbio'**
  String get tipoManutencaoOleoCambio;

  /// Label do tipo de manutenção Fluido de freio
  ///
  /// In pt, this message translates to:
  /// **'Fluido de freio'**
  String get tipoManutencaoFluidoFreio;

  /// Label do tipo de manutenção Revisão geral
  ///
  /// In pt, this message translates to:
  /// **'Revisão geral'**
  String get tipoManutencaoRevisaoGeral;

  /// Label do tipo de manutenção Rodízio de pneus
  ///
  /// In pt, this message translates to:
  /// **'Rodízio de pneus'**
  String get tipoManutencaoRodizioPneus;

  /// Label do tipo de manutenção Outros
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get tipoManutencaoOutros;

  /// Label do campo Nome no form de despesa
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get despesaCampoNome;

  /// Label do campo Categoria no form de despesa
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get despesaCampoCategoria;

  /// Label do campo Valor no form de despesa
  ///
  /// In pt, this message translates to:
  /// **'Valor (R\$)'**
  String get despesaCampoValor;

  /// Label do campo Frequência no form de despesa
  ///
  /// In pt, this message translates to:
  /// **'Frequência'**
  String get despesaCampoFrequencia;

  /// Label do campo Dia do mês no form de despesa
  ///
  /// In pt, this message translates to:
  /// **'Dia do mês (1-28)'**
  String get despesaCampoDiaDoMes;

  /// Helper text do campo Dia do mês
  ///
  /// In pt, this message translates to:
  /// **'Dia de vencimento mensal/anual (máx. 28).'**
  String get despesaCampoDiaDoMesHelper;

  /// Label do campo Data de início no form de despesa
  ///
  /// In pt, this message translates to:
  /// **'Data de início'**
  String get despesaCampoDataInicio;

  /// Label do campo Data de fim no form de despesa
  ///
  /// In pt, this message translates to:
  /// **'Data de fim (opcional)'**
  String get despesaCampoDataFim;

  /// Texto quando nenhuma data de fim foi selecionada
  ///
  /// In pt, this message translates to:
  /// **'Sem data de fim'**
  String get despesaDataFimVazia;

  /// Tooltip do botão de limpar data de fim
  ///
  /// In pt, this message translates to:
  /// **'Limpar data de fim'**
  String get despesaLimparDataFim;

  /// Label do switch Ativa no form de despesa
  ///
  /// In pt, this message translates to:
  /// **'Ativa'**
  String get despesaCampoAtiva;

  /// Subtítulo do switch Ativa no form de despesa
  ///
  /// In pt, this message translates to:
  /// **'Desative para suspender as ocorrências futuras.'**
  String get despesaCampoAtivaSubtitulo;

  /// Aviso no form de despesa quando não há veículo
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um veículo antes de registrar despesas.'**
  String get semVeiculoCadastrarDespesaForm;

  /// Mensagem de validação de dia do mês inválido
  ///
  /// In pt, this message translates to:
  /// **'Dia inválido (1-28)'**
  String get validacaoDiaDoMesInvalido;

  /// Label da categoria de despesa Lavagem
  ///
  /// In pt, this message translates to:
  /// **'Lavagem'**
  String get categoriaDespesaLavagem;

  /// Label da categoria de despesa Estacionamento
  ///
  /// In pt, this message translates to:
  /// **'Estacionamento'**
  String get categoriaDespesaEstacionamento;

  /// Label da categoria de despesa Pedágio
  ///
  /// In pt, this message translates to:
  /// **'Pedágio'**
  String get categoriaDespesaPedagio;

  /// Label da categoria de despesa Financiamento
  ///
  /// In pt, this message translates to:
  /// **'Financiamento'**
  String get categoriaDespesaFinanciamento;

  /// Label da categoria de despesa Outra
  ///
  /// In pt, this message translates to:
  /// **'Outra'**
  String get categoriaDespesaOutra;

  /// Label da frequência de despesa Única
  ///
  /// In pt, this message translates to:
  /// **'Única'**
  String get frequenciaDespesaUnica;

  /// Label da frequência de despesa Semanal
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get frequenciaDespesaSemanal;

  /// Label da frequência de despesa Mensal
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get frequenciaDespesaMensal;

  /// Label da frequência de despesa Anual
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get frequenciaDespesaAnual;

  /// Título da tela de lista de ocorrências de despesas
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get despesasListTitulo;

  /// Label do FAB da tela de lista de ocorrências de despesas
  ///
  /// In pt, this message translates to:
  /// **'Nova despesa'**
  String get despesasListFab;

  /// Mensagem de empty state na lista de ocorrências de despesas
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma ocorrência encontrada.\nCrie uma despesa recorrente para começar.'**
  String get despesasListVazia;

  /// Aviso exibido quando não há veículo cadastrado na tela de despesas
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um veículo para começar a registrar despesas.'**
  String get semVeiculoCadastrarDespesa;

  /// Label do status de ocorrência Pendente
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get ocorrenciaStatusPendente;

  /// Label do status de ocorrência Paga
  ///
  /// In pt, this message translates to:
  /// **'Paga'**
  String get ocorrenciaStatusPaga;

  /// Label do status de ocorrência Pulada
  ///
  /// In pt, this message translates to:
  /// **'Pulada'**
  String get ocorrenciaStatusPulada;

  /// Ação para marcar ocorrência como paga
  ///
  /// In pt, this message translates to:
  /// **'Marcar paga'**
  String get ocorrenciaAcaoMarcarPaga;

  /// Ação para pular ocorrência
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get ocorrenciaAcaoPular;

  /// Ação para editar o valor pago de uma ocorrência
  ///
  /// In pt, this message translates to:
  /// **'Editar valor pago'**
  String get ocorrenciaAcaoEditarValor;

  /// Título do dialog de marcar ocorrência como paga
  ///
  /// In pt, this message translates to:
  /// **'Marcar como paga'**
  String get ocorrenciaDialogMarcarPagaTitulo;

  /// Título do dialog de editar valor pago
  ///
  /// In pt, this message translates to:
  /// **'Editar valor pago'**
  String get ocorrenciaDialogEditarValorTitulo;

  /// Label do campo valor no dialog de marcar paga/editar valor
  ///
  /// In pt, this message translates to:
  /// **'Valor pago (R\$)'**
  String get ocorrenciaDialogCampoValor;

  /// Label do campo data de pagamento no dialog
  ///
  /// In pt, this message translates to:
  /// **'Data de pagamento'**
  String get ocorrenciaDialogCampoData;

  /// Botão de confirmação nos dialogs de ocorrência
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get ocorrenciaDialogConfirmar;

  /// Botão de cancelamento nos dialogs de ocorrência
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get ocorrenciaDialogCancelar;

  /// Corpo da notificação agendada 7 dias antes da data alvo do lembrete
  ///
  /// In pt, this message translates to:
  /// **'Vence em {data}'**
  String notifLembreteDataCorpo(String data);

  /// Corpo da notificação imediata quando o km alvo de um lembrete é atingido
  ///
  /// In pt, this message translates to:
  /// **'Km alvo de {km} atingido!'**
  String notifLembreteKmCorpo(int km);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
