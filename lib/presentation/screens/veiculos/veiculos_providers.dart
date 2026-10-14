import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/database/app_database.dart';
import '../../../data/providers.dart';

final veiculosAtivosProvider = StreamProvider<List<Veiculo>>(
  (ref) => ref.watch(veiculosDaoProvider).watchAtivos(),
);

final veiculosArquivadosProvider = StreamProvider<List<Veiculo>>(
  (ref) => ref.watch(veiculosDaoProvider).watchArquivados(),
);

/// Placa persistida da última seleção do usuário. Pode apontar para um
/// veículo que não existe mais (arquivado/excluído); use
/// [veiculoAtivoProvider] para obter o veículo efetivo.
class VeiculoSelecionadoNotifier extends AsyncNotifier<String?> {
  static const _prefKey = 'veiculo_selecionado_placa';

  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }

  Future<void> selecionar(String? placa) async {
    state = AsyncData(placa);
    final prefs = await SharedPreferences.getInstance();
    if (placa == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, placa);
    }
  }
}

final veiculoSelecionadoProvider =
    AsyncNotifierProvider<VeiculoSelecionadoNotifier, String?>(
      VeiculoSelecionadoNotifier.new,
    );

/// Veículo efetivamente ativo na UI: respeita a seleção persistida quando
/// ela ainda consta nos ativos; caso contrário, cai no primeiro ativo.
/// Retorna `null` quando não há veículos ativos cadastrados.
final veiculoAtivoProvider = Provider<Veiculo?>((ref) {
  final ativos = ref.watch(veiculosAtivosProvider).value ?? const [];
  if (ativos.isEmpty) return null;
  final selecionada = ref.watch(veiculoSelecionadoProvider).value;
  if (selecionada != null) {
    for (final v in ativos) {
      if (v.placa == selecionada) return v;
    }
  }
  return ativos.first;
});
