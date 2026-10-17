import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/comparador_service.dart';
import '../../../l10n/app_localizations.dart';
import '../veiculos/veiculos_providers.dart';
import 'comparador_providers.dart';

class ComparadorScreen extends ConsumerStatefulWidget {
  const ComparadorScreen({super.key});

  @override
  ConsumerState<ComparadorScreen> createState() => _ComparadorScreenState();
}

class _ComparadorScreenState extends ConsumerState<ComparadorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alcoolCtrl = TextEditingController();
  final _gasolinaCtrl = TextEditingController();
  String? _placaSelecionada;
  ResultadoComparador? _resultado;
  bool _calculando = false;

  @override
  void dispose() {
    _alcoolCtrl.dispose();
    _gasolinaCtrl.dispose();
    super.dispose();
  }

  double? _parsePreco(String raw) {
    final normalizado = raw.trim().replaceAll(',', '.');
    final v = double.tryParse(normalizado);
    if (v == null || v <= 0) return null;
    return v;
  }

  String? _validatePreco(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) return l10n.validacaoObrigatorio;
    final n = _parsePreco(v);
    if (n == null) return l10n.validacaoValorInvalido;
    return null;
  }

  Future<void> _comparar() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    final placa = _placaSelecionada;
    if (placa == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.comparadorSemVeiculo)));
      return;
    }
    setState(() => _calculando = true);
    try {
      final historico = await ref.read(
        historicoAbastecimentosProvider(placa).future,
      );
      final service = ref.read(comparadorServiceProvider);
      final resultado = service.comparar(
        precoAlcool: _parsePreco(_alcoolCtrl.text)!,
        precoGasolina: _parsePreco(_gasolinaCtrl.text)!,
        historico: historico,
      );
      if (!mounted) return;
      setState(() => _resultado = resultado);
    } finally {
      if (mounted) setState(() => _calculando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final veiculos = ref.watch(veiculosAtivosProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.comparadorTitulo)),
      body: veiculos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.erroGenerico(e.toString()))),
        data: (lista) {
          if (lista.isEmpty) {
            return const _SemVeiculos();
          }
          _placaSelecionada ??= lista.first.placa;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _VeiculoDropdown(
                  veiculos: lista,
                  placa: _placaSelecionada!,
                  onChanged: (p) => setState(() {
                    _placaSelecionada = p;
                    _resultado = null;
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _alcoolCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.comparadorCampoAlcool,
                    prefixText: l10n.comparadorPrefixoPreco,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                  ],
                  validator: _validatePreco,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _gasolinaCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.comparadorCampoGasolina,
                    prefixText: l10n.comparadorPrefixoPreco,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                  ],
                  validator: _validatePreco,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _calculando ? null : () => unawaited(_comparar()),
                  icon: _calculando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate_outlined),
                  label: Text(l10n.comparadorBotao),
                ),
                if (_resultado != null) ...[
                  const SizedBox(height: 24),
                  _ResultadoCard(resultado: _resultado!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VeiculoDropdown extends StatelessWidget {
  const _VeiculoDropdown({
    required this.veiculos,
    required this.placa,
    required this.onChanged,
  });

  final List<Veiculo> veiculos;
  final String placa;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      initialValue: placa,
      decoration: InputDecoration(labelText: l10n.comparadorCampoVeiculo),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      items: [
        for (final v in veiculos)
          DropdownMenuItem(value: v.placa, child: Text(_labelVeiculo(v))),
      ],
    );
  }

  static String _labelVeiculo(Veiculo v) {
    final titulo = (v.apelido?.isNotEmpty ?? false)
        ? v.apelido!
        : '${v.marca} ${v.modelo}';
    return '$titulo · ${v.placa}';
  }
}

class _ResultadoCard extends StatelessWidget {
  const _ResultadoCard({required this.resultado});

  final ResultadoComparador resultado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final (titulo, cor, icone) = switch (resultado.vencedor) {
      CombustivelMaisVantajoso.alcool => (
        l10n.comparadorAlcoolCompensa,
        cs.tertiaryContainer,
        Icons.local_gas_station,
      ),
      CombustivelMaisVantajoso.gasolina => (
        l10n.comparadorGasolinaCompensa,
        cs.primaryContainer,
        Icons.local_gas_station,
      ),
      CombustivelMaisVantajoso.empate => (
        l10n.comparadorEmpate,
        cs.secondaryContainer,
        Icons.balance,
      ),
    };

    return Card(
      color: cor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetodoBadge(metodo: resultado.metodo),
            const SizedBox(height: 16),
            if (resultado.metodo == MetodoComparador.historico) ...[
              _LinhaCusto(
                label: l10n.comparadorAlcoolCompensa,
                custoPorKm: resultado.custoPorKmAlcool!,
                kmPorLitro: resultado.kmPorLitroAlcool!,
              ),
              const SizedBox(height: 6),
              _LinhaCusto(
                label: l10n.comparadorGasolinaCompensa,
                custoPorKm: resultado.custoPorKmGasolina!,
                kmPorLitro: resultado.kmPorLitroGasolina!,
              ),
            ] else
              Text(
                l10n.comparadorSemHistoricoTexto,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _MetodoBadge extends StatelessWidget {
  const _MetodoBadge({required this.metodo});

  final MetodoComparador metodo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, icone) = switch (metodo) {
      MetodoComparador.historico => (
        l10n.comparadorMetodoHistorico,
        Icons.history,
      ),
      MetodoComparador.regraSetenta => (
        l10n.comparadorMetodoRegra70,
        Icons.rule,
      ),
    };
    return Chip(
      avatar: Icon(icone, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _LinhaCusto extends StatelessWidget {
  const _LinhaCusto({
    required this.label,
    required this.custoPorKm,
    required this.kmPorLitro,
  });

  final String label;
  final double custoPorKm;
  final double kmPorLitro;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(
          child: Text(
            'R\$ ${custoPorKm.toStringAsFixed(3)}/km '
            '· ${kmPorLitro.toStringAsFixed(1)} km/L',
          ),
        ),
      ],
    );
  }
}

class _SemVeiculos extends StatelessWidget {
  const _SemVeiculos();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.comparadorSemVeiculoCadastrado,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
