import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/abastecimentos_service.dart';
import '../veiculos/veiculos_providers.dart';
import 'abastecimentos_providers.dart' show ultimoKmProvider;
import 'enum_labels.dart';

/// Form de abastecimento. Em modo novo, usa o veículo ativo da Home; em modo
/// edição, carrega o abastecimento pelo id e trava o veículo.
class AbastecimentoFormScreen extends ConsumerStatefulWidget {
  const AbastecimentoFormScreen({this.id, super.key});

  final int? id;

  @override
  ConsumerState<AbastecimentoFormScreen> createState() =>
      _AbastecimentoFormScreenState();
}

class _AbastecimentoFormScreenState
    extends ConsumerState<AbastecimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kmCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _litrosCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _postoCtrl = TextEditingController();

  DateTime _data = DateTime.now();
  TipoCombustivelAbastecimento? _combustivel;
  bool _tanqueCheio = true;
  bool _saving = false;

  /// Qual dos três campos foi preenchido automaticamente pelo cálculo.
  /// `null` = nenhum foi calculado ainda (todos manuais ou vazios).
  _CampoCalculo? _ultimoCalculado;

  /// Guard para evitar recursão: quando `_recalcular` escreve num controller,
  /// o `onChanged` dispara novamente. Esta flag descarta esse re-enter.
  bool _writingProgrammatically = false;

  /// `true` quando o km informado é menor que o último registrado para o
  /// veículo — exibe banner de aviso não-bloqueante (RF-06).
  bool _avisoKmRetroativo = false;

  /// Último km registrado para o veículo ativo, mantido sincronizado com o
  /// [ultimoKmProvider] pelo `build`. Permite que `_verificarKm` opere
  /// sincronamente sem `unawaited`, evitando race conditions em testes.
  int? _ultimoKmCache;

  /// Veículo em modo edição (carregado pelo id). Em modo novo, o veículo
  /// vem reativamente do [veiculoAtivoProvider] no build.
  Veiculo? _veiculoEdit;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) unawaited(_loadExisting());
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _precoCtrl.dispose();
    _litrosCtrl.dispose();
    _valorCtrl.dispose();
    _postoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final dao = ref.read(abastecimentosDaoProvider);
    final a = await dao.byId(widget.id!);
    if (a == null || !mounted) return;
    final veiculo = await ref.read(veiculosDaoProvider).byPlaca(a.veiculoPlaca);
    if (!mounted) return;
    setState(() {
      _veiculoEdit = veiculo;
      _data = a.data;
      _combustivel = a.tipoCombustivel;
      _tanqueCheio = a.tanqueCheio;
      _kmCtrl.text = a.km.toString();
      _precoCtrl.text = _fmtNumber(a.precoLitro);
      _litrosCtrl.text = _fmtNumber(a.litros);
      _valorCtrl.text = _fmtNumber(a.valorTotal);
      _postoCtrl.text = a.posto ?? '';
    });
  }

  /// Preenchimento automático do terceiro campo quando os outros 2 têm valor
  /// numérico válido.
  ///
  /// Estratégia (Opção A da issue #51):
  ///
  /// * [_ultimoCalculado] registra qual campo foi escrito automaticamente pela
  ///   última chamada a este método.
  /// * Quando o usuário edita um campo ([editado]) que NÃO é o calculado,
  ///   o campo calculado fica como alvo e é sempre sobrescrito — resolvendo o
  ///   bug de "travar no primeiro valor".
  /// * Quando o usuário edita exatamente o campo calculado, ele está assumindo
  ///   controle manual: resetamos [_ultimoCalculado] e determinamos o novo alvo
  ///   como o campo vazio dentre os dois restantes (comportamento original).
  /// * [_writingProgrammatically] evita recursão: escrever num controller
  ///   dispara [onChanged] → [_recalcular] novamente; o guard descarta essa
  ///   re-entrada.
  void _recalcular(_CampoCalculo editado) {
    if (_writingProgrammatically) return;

    final preco = _parseDecimal(_precoCtrl.text);
    final litros = _parseDecimal(_litrosCtrl.text);
    final valor = _parseDecimal(_valorCtrl.text);

    void escrever(TextEditingController ctrl, String texto) {
      _writingProgrammatically = true;
      ctrl.text = texto;
      _writingProgrammatically = false;
    }

    // ── Caso 1: o usuário editou o campo que estava calculado ──────────────
    // Ele assumiu controle manual daquele campo. Resetamos o tracking e
    // tentamos calcular o campo vazio dentre os outros dois.
    if (editado == _ultimoCalculado) {
      _ultimoCalculado = null;
      switch (editado) {
        case _CampoCalculo.preco:
          if (preco != null && litros != null && _valorCtrl.text.isEmpty) {
            escrever(_valorCtrl, _fmtNumber(preco * litros));
            _ultimoCalculado = _CampoCalculo.valor;
          } else if (preco != null &&
              valor != null &&
              _litrosCtrl.text.isEmpty) {
            escrever(_litrosCtrl, _fmtNumber(valor / preco));
            _ultimoCalculado = _CampoCalculo.litros;
          }
        case _CampoCalculo.litros:
          if (preco != null && litros != null && _valorCtrl.text.isEmpty) {
            escrever(_valorCtrl, _fmtNumber(preco * litros));
            _ultimoCalculado = _CampoCalculo.valor;
          } else if (litros != null &&
              valor != null &&
              _precoCtrl.text.isEmpty) {
            escrever(_precoCtrl, _fmtNumber(valor / litros));
            _ultimoCalculado = _CampoCalculo.preco;
          }
        case _CampoCalculo.valor:
          if (valor != null && preco != null && _litrosCtrl.text.isEmpty) {
            escrever(_litrosCtrl, _fmtNumber(valor / preco));
            _ultimoCalculado = _CampoCalculo.litros;
          } else if (valor != null &&
              litros != null &&
              _precoCtrl.text.isEmpty) {
            escrever(_precoCtrl, _fmtNumber(valor / litros));
            _ultimoCalculado = _CampoCalculo.preco;
          }
      }
      return;
    }

    // ── Caso 2: o usuário editou um campo diferente do calculado ───────────
    // O alvo é [_ultimoCalculado] (se existir) ou o campo vazio que não é
    // [editado] (primeira digitação — comportamento original).
    final alvo = _ultimoCalculado ?? _campoVazioExceto(editado);
    if (alvo == null) return;

    switch (alvo) {
      case _CampoCalculo.valor:
        if (preco != null && litros != null) {
          escrever(_valorCtrl, _fmtNumber(preco * litros));
          _ultimoCalculado = _CampoCalculo.valor;
        }
      case _CampoCalculo.litros:
        if (valor != null && preco != null) {
          escrever(_litrosCtrl, _fmtNumber(valor / preco));
          _ultimoCalculado = _CampoCalculo.litros;
        }
      case _CampoCalculo.preco:
        if (valor != null && litros != null) {
          escrever(_precoCtrl, _fmtNumber(valor / litros));
          _ultimoCalculado = _CampoCalculo.preco;
        }
    }
  }

  /// Retorna o campo que está vazio (texto vazio) e que não é [exceto].
  /// Se ambos os outros campos têm conteúdo (todos preenchidos manualmente),
  /// retorna `null` — não há alvo para cálculo automático.
  _CampoCalculo? _campoVazioExceto(_CampoCalculo exceto) {
    final todos = _CampoCalculo.values.where((c) => c != exceto);
    for (final campo in todos) {
      final ctrl = switch (campo) {
        _CampoCalculo.preco => _precoCtrl,
        _CampoCalculo.litros => _litrosCtrl,
        _CampoCalculo.valor => _valorCtrl,
      };
      if (ctrl.text.isEmpty) return campo;
    }
    return null;
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(hoje.year - 10),
      lastDate: hoje,
    );
    if (escolhida != null) {
      setState(() => _data = escolhida);
    }
  }

  Future<void> _submit(Veiculo veiculo) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final preco = _parseDecimal(_precoCtrl.text)!;
      final litros = _parseDecimal(_litrosCtrl.text)!;
      final valor = _parseDecimal(_valorCtrl.text)!;
      final postoTxt = _postoCtrl.text.trim();
      final service = ref.read(abastecimentosServiceProvider);
      if (_isEdit) {
        final atual = await service.byId(widget.id!);
        if (atual == null) return;
        await service.updateAbastecimento(
          atual.copyWith(
            data: _data,
            km: int.parse(_kmCtrl.text),
            tipoCombustivel: _combustivel!,
            precoLitro: preco,
            litros: litros,
            valorTotal: valor,
            posto: Value(postoTxt.isEmpty ? null : postoTxt),
            tanqueCheio: _tanqueCheio,
          ),
        );
      } else {
        await service.insertAbastecimento(
          AbastecimentosCompanion.insert(
            veiculoPlaca: veiculo.placa,
            data: _data,
            km: int.parse(_kmCtrl.text),
            tipoCombustivel: _combustivel!,
            precoLitro: preco,
            valorTotal: valor,
            litros: litros,
            posto: Value(postoTxt.isEmpty ? null : postoTxt),
            tanqueCheio: Value(_tanqueCheio),
          ),
        );
      }
      // Salva o posto no histórico de sugestões (se preenchido)
      if (postoTxt.isNotEmpty) {
        await ref.read(postoSugestaoDaoProvider).upsert(postoTxt);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.abastecimentoNaoPossivel(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Verifica se o km digitado é retroativo em relação ao último abastecimento
  /// e atualiza [_avisoKmRetroativo]. Usa [_ultimoKmCache], que é mantido
  /// sincronizado pelo `build` via `ref.watch(ultimoKmProvider)`, para operar
  /// de forma síncrona e evitar race conditions (RF-06).
  void _verificarKm() {
    final kmDigitado = int.tryParse(_kmCtrl.text);
    final retroativo =
        kmDigitado != null &&
        _ultimoKmCache != null &&
        kmDigitado < _ultimoKmCache!;
    if (retroativo != _avisoKmRetroativo) {
      setState(() => _avisoKmRetroativo = retroativo);
    }
  }

  String? _validateKm(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.validacaoObrigatorio;
    final km = int.tryParse(v);
    if (km == null || km < 0) return l10n.validacaoKmInvalido;
    return null;
  }

  String? _validateDecimal(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.validacaoDecimalObrigatorio;
    final n = _parseDecimal(v);
    if (n == null || n <= 0) return l10n.validacaoValorInvalido;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? l10n.abastecimentoEditarTitulo
              : l10n.abastecimentoNovoTitulo,
        ),
        actions: [
          if (_isEdit)
            Semantics(
              label: l10n.abastecimentoAcaoExcluir,
              button: true,
              child: IconButton(
                key: const Key('btn_excluir_abastecimento_appbar'),
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.abastecimentoAcaoExcluir,
                onPressed: () => unawaited(_excluir(context)),
              ),
            ),
        ],
      ),
      body: _isEdit ? _buildEditBody() : _buildNewBody(),
    );
  }

  Future<void> _excluir(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExcluirAbastecimentoDialog(),
    );
    if (confirm != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final service = ref.read(abastecimentosServiceProvider);
      await service.deleteAbastecimento(widget.id!);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.abastecimentoExcluido)),
      );
      Navigator.of(context).pop();
    } on Object catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.abastecimentoNaoPossivel(e.toString()))),
      );
    }
  }

  Widget _buildEditBody() {
    final veiculo = _veiculoEdit;
    if (veiculo == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildForm(veiculo);
  }

  Widget _buildNewBody() {
    final l10n = AppLocalizations.of(context)!;
    // Aguarda o stream do Drift resolver para distinguir "ainda carregando"
    // de "não há veículo cadastrado".
    final ativos = ref.watch(veiculosAtivosProvider);
    return ativos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.erroGenerico(e.toString()))),
      data: (_) {
        final veiculo = ref.watch(veiculoAtivoProvider);
        if (veiculo == null) return const _AvisoSemVeiculo();
        _combustivel ??= combustiveisParaVeiculo(veiculo.combustivel).first;
        return _buildForm(veiculo);
      },
    );
  }

  Widget _buildForm(Veiculo veiculo) {
    final l10n = AppLocalizations.of(context)!;
    final combustiveis = combustiveisParaVeiculo(veiculo.combustivel);
    final combustivelSelecionado =
        _combustivel != null && combustiveis.contains(_combustivel)
        ? _combustivel
        : combustiveis.first;

    // Sincroniza _ultimoKmCache com o FutureProvider para que _verificarKm
    // opere de forma síncrona (sem unawaited) — evita race condition em testes.
    // Atribuição direta durante build é segura pois _ultimoKmCache é apenas um
    // cache auxiliar e não dispara setState.
    final ultimoKmAsync = ref.watch(ultimoKmProvider(veiculo.placa));
    _ultimoKmCache = ultimoKmAsync.asData?.value;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VeiculoChip(veiculo: veiculo),
            const SizedBox(height: 16),
            Semantics(
              label: '${l10n.abastecimentoCampoData}: ${_fmtData(_data)}',
              hint: l10n.a11yToquePAraAbrir,
              button: true,
              child: InkWell(
                onTap: () => unawaited(_escolherData()),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.abastecimentoCampoData,
                  ),
                  child: Text(_fmtData(_data)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('abast_km'),
              controller: _kmCtrl,
              decoration: InputDecoration(
                labelText: l10n.abastecimentoCampoHodometro,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateKm,
              onChanged: (_) => _verificarKm(),
            ),
            if (_avisoKmRetroativo) ...[
              const SizedBox(height: 8),
              _AvisoKmRetroativo(mensagem: l10n.abastecimentoAvisoKmRetroativo),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<TipoCombustivelAbastecimento>(
              initialValue: combustivelSelecionado,
              decoration: InputDecoration(
                labelText: l10n.abastecimentoCampoCombustivel,
              ),
              onChanged: (v) => setState(() => _combustivel = v),
              items: [
                for (final c in combustiveis)
                  DropdownMenuItem(value: c, child: Text(c.label(l10n))),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('abast_preco'),
              controller: _precoCtrl,
              decoration: InputDecoration(
                labelText: l10n.abastecimentoCampoPreco,
                helperText: l10n.abastecimentoCampoPrecoHelper,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_DecimalFormatter()],
              validator: _validateDecimal,
              onChanged: (_) => _recalcular(_CampoCalculo.preco),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('abast_litros'),
              controller: _litrosCtrl,
              decoration: InputDecoration(
                labelText: l10n.abastecimentoCampoLitros,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_DecimalFormatter()],
              validator: _validateDecimal,
              onChanged: (_) => _recalcular(_CampoCalculo.litros),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('abast_valor'),
              controller: _valorCtrl,
              decoration: InputDecoration(
                labelText: l10n.abastecimentoCampoValorTotal,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_DecimalFormatter()],
              validator: _validateDecimal,
              onChanged: (_) => _recalcular(_CampoCalculo.valor),
            ),
            const SizedBox(height: 12),
            _PostoAutocomplete(controller: _postoCtrl),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.abastecimentoTanqueCheio),
              subtitle: Text(l10n.abastecimentoTanqueCheioSubtitulo),
              value: _tanqueCheio,
              onChanged: (v) => setState(() => _tanqueCheio = v),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: _saving ? l10n.a11ySalvando : l10n.botaoSalvar,
              button: true,
              child: FilledButton(
                onPressed: _saving ? null : () => unawaited(_submit(veiculo)),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.botaoSalvar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisoSemVeiculo extends StatelessWidget {
  const _AvisoSemVeiculo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.semVeiculoCadastrarAbastecimentoForm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner inline exibido quando o km informado é menor que o último
/// registrado para o veículo. Não bloqueia o salvamento (RF-06).
class _AvisoKmRetroativo extends StatelessWidget {
  const _AvisoKmRetroativo({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensagem,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VeiculoChip extends StatelessWidget {
  const _VeiculoChip({required this.veiculo});

  final Veiculo veiculo;

  @override
  Widget build(BuildContext context) {
    final apelido = veiculo.apelido;
    final titulo = (apelido != null && apelido.isNotEmpty)
        ? apelido
        : '${veiculo.marca} ${veiculo.modelo}';
    final icone = veiculo.tipo == TipoVeiculo.carro
        ? Icons.directions_car
        : Icons.two_wheeler;
    return Semantics(
      label: '$titulo · ${veiculo.placa}',
      child: Row(
        children: [
          ExcludeSemantics(child: Icon(icone, size: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                '$titulo · ${veiculo.placa}',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de autocomplete para o campo Posto.
/// Busca sugestões no [PostoSugestaoDao] ordenadas por frequência de uso.
///
/// Usa [Autocomplete<String>] do Material, que gerencia overlay, ancoragem e
/// hit testing internamente — eliminando o tap-through no botão Salvar que
/// ocorria com o [RawAutocomplete] + [CompositedTransformFollower] (#91).
class _PostoAutocomplete extends ConsumerStatefulWidget {
  const _PostoAutocomplete({required this.controller});

  final TextEditingController controller;

  @override
  ConsumerState<_PostoAutocomplete> createState() => _PostoAutocompleteState();
}

class _PostoAutocompleteState extends ConsumerState<_PostoAutocomplete> {
  /// FocusNode próprio passado ao [Autocomplete]. Necessário para que o par
  /// (textEditingController + focusNode) seja gerenciado externamente.
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<Iterable<String>> _fetchSugestoes(String query) async {
    final dao = ref.read(postoSugestaoDaoProvider);
    return dao.search(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Passamos o controller externo diretamente ao Autocomplete. Quando o
    // usuário digita ou seleciona uma sugestão, o widget.controller já é
    // atualizado — não há necessidade de listener extra de sincronização.
    // onSelected é chamado pelo Autocomplete para atualizar o textController
    // após a seleção; o form pai lê widget.controller.text em _submit().
    return Autocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable<String>.empty();
        return _fetchSugestoes(query);
      },
      displayStringForOption: (s) => s,
      fieldViewBuilder:
          (context, fieldController, focusNode, onFieldSubmitted) {
            return TextFormField(
              key: const Key('abast_posto'),
              controller: fieldController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: l10n.abastecimentoCampoPosto,
              ),
              textCapitalization: TextCapitalization.words,
              onFieldSubmitted: (_) => onFieldSubmitted(),
            );
          },
      onSelected: (option) {
        widget.controller.text = option;
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog de confirmação de exclusão (StatefulWidget local — padrão do app)
// ---------------------------------------------------------------------------

class _ExcluirAbastecimentoDialog extends StatelessWidget {
  const _ExcluirAbastecimentoDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.abastecimentoExcluirTitulo),
      content: Text(l10n.abastecimentoExcluirMensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.botaoCancelar),
        ),
        FilledButton(
          key: const Key('btn_excluir_abastecimento_confirmar'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.abastecimentoAcaoExcluir),
        ),
      ],
    );
  }
}

enum _CampoCalculo { preco, litros, valor }

/// Aceita dígitos e um separador decimal (vírgula ou ponto). Normaliza para
/// vírgula ao digitar, mas o parse aceita ambos.
class _DecimalFormatter extends TextInputFormatter {
  static final _permitido = RegExp(r'[0-9.,]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    var jaTemSeparador = false;
    for (final c in newValue.text.characters) {
      if (!_permitido.hasMatch(c)) continue;
      if (c == ',' || c == '.') {
        if (jaTemSeparador) continue;
        jaTemSeparador = true;
        buffer.write(',');
      } else {
        buffer.write(c);
      }
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

double? _parseDecimal(String s) {
  if (s.isEmpty) return null;
  return double.tryParse(s.replaceAll(',', '.'));
}

String _fmtNumber(double n) {
  // 3 casas decimais, removendo zeros à direita e separador quando sobrar
  // vazio (ex.: 2.000 → "2").
  final s = n.toStringAsFixed(3);
  var trimmed = s;
  if (trimmed.contains('.')) {
    trimmed = trimmed.replaceFirst(RegExp(r'0+$'), '');
    trimmed = trimmed.replaceFirst(RegExp(r'\.$'), '');
  }
  return trimmed.replaceAll('.', ',');
}

String _fmtData(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}
