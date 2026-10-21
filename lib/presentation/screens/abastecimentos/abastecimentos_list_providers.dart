import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';

/// Períodos de filtro disponíveis na tela de lista de abastecimentos.
enum FiltroPeriodo {
  ultimos30dias,
  ultimos90dias,
  ultimos12meses,
  tudo;

  String label(AppLocalizations l10n) => switch (this) {
    FiltroPeriodo.ultimos30dias => l10n.filtroPeriodoUltimos30d,
    FiltroPeriodo.ultimos90dias => l10n.filtroPeriodoUltimos90d,
    FiltroPeriodo.ultimos12meses => l10n.filtroPeriodoUltimos12m,
    FiltroPeriodo.tudo => l10n.filtroPeriodoTudo,
  };

  /// Retorna a data de corte (inclusive) ou null quando o filtro é "tudo".
  DateTime? get desde {
    final agora = DateTime.now();
    return switch (this) {
      FiltroPeriodo.ultimos30dias => agora.subtract(const Duration(days: 30)),
      FiltroPeriodo.ultimos90dias => agora.subtract(const Duration(days: 90)),
      FiltroPeriodo.ultimos12meses => DateTime(
        agora.year - 1,
        agora.month,
        agora.day,
      ),
      FiltroPeriodo.tudo => null,
    };
  }
}

/// Estado dos filtros da tela de lista de abastecimentos.
///
/// [tiposCombustivel]:
///   - null  → sem filtro aplicado (equivale a "todos selecionados").
///   - Set não-vazio → filtra pelos tipos incluídos no set.
///   - Set vazio → nenhum tipo selecionado; a tela exibe estado vazio com
///     mensagem explicativa (evita a ambiguidade "vazio = tudo").
class FiltrosAbastecimento {
  const FiltrosAbastecimento({
    this.periodo = FiltroPeriodo.tudo,
    this.tiposCombustivel,
  });

  final FiltroPeriodo periodo;

  /// null = todos selecionados (sem filtro ativo).
  /// Set vazio = nenhum selecionado → estado vazio.
  /// Set não-vazio = filtra pelos tipos listados.
  final Set<TipoCombustivelAbastecimento>? tiposCombustivel;

  FiltrosAbastecimento copyWith({
    FiltroPeriodo? periodo,
    Object? tiposCombustivel = _sentinel,
  }) {
    return FiltrosAbastecimento(
      periodo: periodo ?? this.periodo,
      tiposCombustivel: tiposCombustivel == _sentinel
          ? this.tiposCombustivel
          : tiposCombustivel as Set<TipoCombustivelAbastecimento>?,
    );
  }
}

// Sentinel para diferenciar null intencional de "não fornecido" no copyWith.
const Object _sentinel = Object();

/// Notifier que guarda e expõe os filtros ativos da tela de lista.
class FiltrosAbastecimentoNotifier extends Notifier<FiltrosAbastecimento> {
  @override
  FiltrosAbastecimento build() => const FiltrosAbastecimento();

  void setPeriodo(FiltroPeriodo periodo) {
    state = state.copyWith(periodo: periodo);
  }

  /// Alterna (toggle) um tipo de combustível no set de filtros.
  ///
  /// - Se [tiposCombustivel] for null (estado inicial "todos"), inicia um set
  ///   com todos os tipos e remove o que foi desmarcado.
  /// - Se o tipo já estava selecionado, remove-o.
  /// - Se não estava, adiciona-o.
  /// - Se o resultado for um set com todos os tipos, normaliza para null
  ///   (equivalente ao estado "sem filtro").
  void toggleTipoCombustivel(TipoCombustivelAbastecimento tipo) {
    final todos = TipoCombustivelAbastecimento.values.toSet();
    final atual = state.tiposCombustivel ?? todos;
    final novo = Set<TipoCombustivelAbastecimento>.of(atual);

    if (novo.contains(tipo)) {
      novo.remove(tipo);
    } else {
      novo.add(tipo);
    }

    // Todos selecionados → normaliza para null (sem filtro explícito).
    state = state.copyWith(
      tiposCombustivel: novo.length == todos.length ? null : novo,
    );
  }

  void limpar() {
    state = const FiltrosAbastecimento();
  }
}

final filtrosAbastecimentoProvider =
    NotifierProvider<FiltrosAbastecimentoNotifier, FiltrosAbastecimento>(
      FiltrosAbastecimentoNotifier.new,
    );

/// Lista reativa de abastecimentos com filtros aplicados.
/// Vazia quando a placa for null.
final abastecimentosFiltradosProvider =
    StreamProvider.family<List<Abastecimento>, String?>((ref, placa) {
      if (placa == null) return Stream.value(const <Abastecimento>[]);
      final filtros = ref.watch(filtrosAbastecimentoProvider);
      return ref
          .watch(abastecimentosDaoProvider)
          .watchFiltered(
            placa: placa,
            desde: filtros.periodo.desde,
            tiposCombustivel: filtros.tiposCombustivel,
          );
    });
