import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import '../../../domain/placa_validator.dart';
import '../../../l10n/app_localizations.dart';
import 'enum_labels.dart';

class VeiculoFormScreen extends ConsumerStatefulWidget {
  const VeiculoFormScreen({this.placa, super.key});

  final String? placa;

  @override
  ConsumerState<VeiculoFormScreen> createState() => _VeiculoFormScreenState();
}

class _VeiculoFormScreenState extends ConsumerState<VeiculoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaCtrl = TextEditingController();
  final _apelidoCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _marcaFocus = FocusNode();
  final _modeloFocus = FocusNode();
  final _anoCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  TipoVeiculo _tipo = TipoVeiculo.carro;
  TipoCombustivelVeiculo _combustivel = TipoCombustivelVeiculo.flex;
  bool _saving = false;

  List<String> _marcas = const [];
  List<String> _modelos = const [];
  String _marcaCarregada = '';

  bool get _isEdit => widget.placa != null;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMarcas());
    if (_isEdit) {
      unawaited(_loadExisting());
    }
  }

  @override
  void dispose() {
    _placaCtrl.dispose();
    _apelidoCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _marcaFocus.dispose();
    _modeloFocus.dispose();
    _anoCtrl.dispose();
    _kmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMarcas() async {
    final list = await ref.read(marcasModelosDaoProvider).listMarcas();
    if (!mounted) return;
    setState(() => _marcas = list);
  }

  Future<void> _ensureModelosDaMarca(String marca) async {
    final norm = marca.trim();
    if (norm.isEmpty) {
      setState(() {
        _modelos = const [];
        _marcaCarregada = '';
      });
      return;
    }
    if (norm == _marcaCarregada) return;
    final list = await ref
        .read(marcasModelosDaoProvider)
        .listModelosByMarca(norm);
    if (!mounted) return;
    setState(() {
      _modelos = list;
      _marcaCarregada = norm;
    });
  }

  Future<void> _loadExisting() async {
    final dao = ref.read(veiculosDaoProvider);
    final v = await dao.byPlaca(widget.placa!);
    if (v == null || !mounted) return;
    setState(() {
      _placaCtrl.text = v.placa;
      _apelidoCtrl.text = v.apelido ?? '';
      _marcaCtrl.text = v.marca;
      _modeloCtrl.text = v.modelo;
      _anoCtrl.text = v.ano.toString();
      _kmCtrl.text = v.kmInicial.toString();
      _tipo = v.tipo;
      _combustivel = v.combustivel;
    });
    unawaited(_ensureModelosDaMarca(v.marca));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final placaNorm = PlacaValidator.normalize(_placaCtrl.text);
      final apelido = _apelidoCtrl.text.trim();
      final apelidoValue = apelido.isEmpty ? null : apelido;
      final dao = ref.read(veiculosDaoProvider);
      if (_isEdit) {
        await dao.updateByPlaca(
          placaNorm,
          VeiculosCompanion(
            apelido: Value(apelidoValue),
            marca: Value(_marcaCtrl.text.trim()),
            modelo: Value(_modeloCtrl.text.trim()),
            ano: Value(int.parse(_anoCtrl.text)),
            tipo: Value(_tipo),
            combustivel: Value(_combustivel),
            kmInicial: Value(int.parse(_kmCtrl.text)),
          ),
        );
      } else {
        await dao.insertVeiculo(
          VeiculosCompanion.insert(
            placa: placaNorm,
            apelido: Value(apelidoValue),
            marca: _marcaCtrl.text.trim(),
            modelo: _modeloCtrl.text.trim(),
            ano: int.parse(_anoCtrl.text),
            tipo: _tipo,
            combustivel: _combustivel,
            kmInicial: int.parse(_kmCtrl.text),
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      final msg = e.toString().contains('UNIQUE')
          ? l10n.veiculoPlacaExistente
          : l10n.veiculoNaoPossivel(e.toString());
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateObrigatorio(String? v) {
    final l10n = AppLocalizations.of(context)!;
    return (v == null || v.trim().isEmpty) ? l10n.validacaoObrigatorio : null;
  }

  String? _validateAno(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.validacaoObrigatorio;
    final ano = int.tryParse(v);
    if (ano == null) return l10n.validacaoAnoInvalido;
    final atual = DateTime.now().year;
    if (ano < 1900 || ano > atual + 1) return l10n.validacaoAnoForaDaFaixa;
    return null;
  }

  String? _validateKm(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) return l10n.validacaoObrigatorio;
    final km = int.tryParse(v);
    if (km == null || km < 0) return l10n.validacaoKmInvalido;
    return null;
  }

  Iterable<String> _filtrar(List<String> fonte, String q) {
    final norm = q.trim().toLowerCase();
    if (norm.isEmpty) return fonte;
    return fonte.where((item) => item.toLowerCase().contains(norm));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? l10n.veiculoEditarTitulo : l10n.veiculoNovoTitulo,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _placaCtrl,
                enabled: !_isEdit,
                decoration: InputDecoration(
                  labelText: l10n.veiculoCampoPlaca,
                  helperText: l10n.veiculoCampoPlacaHelper,
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(7),
                  _UpperCaseTextFormatter(),
                ],
                validator: (v) => PlacaValidator.validate(v ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apelidoCtrl,
                decoration: InputDecoration(
                  labelText: l10n.veiculoCampoApelido,
                ),
              ),
              const SizedBox(height: 12),
              RawAutocomplete<String>(
                textEditingController: _marcaCtrl,
                focusNode: _marcaFocus,
                optionsBuilder: (tev) => _filtrar(_marcas, tev.text),
                onSelected: (sel) {
                  _marcaCtrl.text = sel;
                  _modeloCtrl.clear();
                  unawaited(_ensureModelosDaMarca(sel));
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) =>
                        TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: l10n.veiculoCampoMarca,
                            helperText: l10n.veiculoCampoMarcaHelper,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: _validateObrigatorio,
                          onFieldSubmitted: (_) => onFieldSubmitted(),
                          onChanged: (v) => unawaited(_ensureModelosDaMarca(v)),
                        ),
                optionsViewBuilder: (ctx, onSelected, options) =>
                    _OpcoesOverlay(
                      options: options.toList(growable: false),
                      onSelected: onSelected,
                    ),
              ),
              const SizedBox(height: 12),
              RawAutocomplete<String>(
                textEditingController: _modeloCtrl,
                focusNode: _modeloFocus,
                optionsBuilder: (tev) => _filtrar(_modelos, tev.text),
                onSelected: (sel) {
                  _modeloCtrl.text = sel;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) =>
                        TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: l10n.veiculoCampoModelo,
                            helperText: _modelos.isEmpty
                                ? l10n.veiculoCampoModeloHelperSemSugestoes
                                : l10n.veiculoCampoModeloHelperComSugestoes,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: _validateObrigatorio,
                          onFieldSubmitted: (_) => onFieldSubmitted(),
                        ),
                optionsViewBuilder: (ctx, onSelected, options) =>
                    _OpcoesOverlay(
                      options: options.toList(growable: false),
                      onSelected: onSelected,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _anoCtrl,
                decoration: InputDecoration(labelText: l10n.veiculoCampoAno),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: _validateAno,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TipoVeiculo>(
                initialValue: _tipo,
                decoration: InputDecoration(labelText: l10n.veiculoCampoTipo),
                onChanged: (v) => setState(() => _tipo = v!),
                items: [
                  for (final t in TipoVeiculo.values)
                    DropdownMenuItem(value: t, child: Text(t.label(l10n))),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TipoCombustivelVeiculo>(
                initialValue: _combustivel,
                decoration: InputDecoration(
                  labelText: l10n.veiculoCampoCombustivel,
                ),
                onChanged: (v) => setState(() => _combustivel = v!),
                items: [
                  for (final c in TipoCombustivelVeiculo.values)
                    DropdownMenuItem(value: c, child: Text(c.label(l10n))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kmCtrl,
                decoration: InputDecoration(
                  labelText: l10n.veiculoCampoHodometro,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validateKm,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : () => unawaited(_submit()),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.botaoSalvar),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcoesOverlay extends StatelessWidget {
  const _OpcoesOverlay({required this.options, required this.onSelected});

  final List<String> options;
  final AutocompleteOnSelected<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240, maxWidth: 400),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (ctx, i) => InkWell(
              onTap: () => onSelected(options[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(options[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
