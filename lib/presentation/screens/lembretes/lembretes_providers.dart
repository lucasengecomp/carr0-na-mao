import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/enums.dart';
import '../../../data/providers.dart';

/// Stream global de todos os lembretes (sem filtro de status), ordenados por
/// data_alvo asc, km_alvo asc. A filtragem por status é feita em Dart pelos
/// providers abaixo.
final _todosLembretesProvider = StreamProvider<List<Lembrete>>(
  (ref) => ref.watch(lembretesDaoProvider).watchAll(),
);

/// Mapa de km atual por placa, derivado do maior km registrado em abastecimentos.
/// Usado para determinar se um lembrete por km está atrasado (issue #68).
///
/// Chave: placa do veículo.
/// Valor: maior km registrado nos abastecimentos daquele veículo.
/// Veículos sem abastecimento simplesmente não aparecem no mapa (tratado como
/// km desconhecido — lembrete por km NÃO é classificado como atrasado).
final kmAtualPorVeiculoProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(abastecimentosDaoProvider).watchAll().map((lista) {
    final mapa = <String, int>{};
    for (final a in lista) {
      final atual = mapa[a.veiculoPlaca];
      if (atual == null || a.km > atual) {
        mapa[a.veiculoPlaca] = a.km;
      }
    }
    return mapa;
  });
});

/// Retorna true se o lembrete está atrasado:
///   status IN (pendente, adiado)  E
///   ( dataAlvo < início de hoje  OU  (kmAlvo != null E kmAtual > kmAlvo) )
///
/// Lembretes adiados também participam da lógica de atraso (issue #116):
/// se a nova data_alvo já passou, o lembrete é exibido como atrasado.
bool _isAtrasado(Lembrete l, Map<String, int> kmAtualPorPlaca) {
  if (l.status != StatusLembrete.pendente &&
      l.status != StatusLembrete.adiado) {
    return false;
  }
  final hoje = DateTime.now();
  final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
  final atrasadoPorData = l.dataAlvo != null && l.dataAlvo!.isBefore(inicioDia);
  final kmAtual = kmAtualPorPlaca[l.veiculoPlaca];
  final atrasadoPorKm =
      l.kmAlvo != null && kmAtual != null && kmAtual > l.kmAlvo!;
  return atrasadoPorData || atrasadoPorKm;
}

/// Lembretes pendentes: status IN (pendente, adiado) E NÃO atrasado.
///
/// Lembretes com status adiado e nova data futura aparecem aqui junto com
/// os pendentes puros, preservando o histórico de adiamento (issue #116).
///
/// Decisão de escopo: lista **global** (todos os veículos). A issue não
/// especifica filtro por veículo ativo; exibir todos dá ao usuário uma visão
/// completa da frota. O veículo é mostrado na linha via [placa].
final lembretesPendentesProvider = StreamProvider<List<Lembrete>>((ref) {
  final todosAsync = ref.watch(_todosLembretesProvider);
  final kmAsync = ref.watch(kmAtualPorVeiculoProvider);
  if (todosAsync.isLoading || kmAsync.isLoading) return const Stream.empty();
  if (todosAsync.hasError) {
    return Stream.error(todosAsync.error!, todosAsync.stackTrace!);
  }
  if (kmAsync.hasError) {
    return Stream.error(kmAsync.error!, kmAsync.stackTrace!);
  }
  final lista = todosAsync.value ?? const <Lembrete>[];
  final kmMap = kmAsync.value ?? const <String, int>{};
  final filtrada =
      lista
          .where(
            (Lembrete l) =>
                (l.status == StatusLembrete.pendente ||
                    l.status == StatusLembrete.adiado) &&
                !_isAtrasado(l, kmMap),
          )
          .toList()
        ..sort(_sortPendentes);
  return Stream.value(filtrada);
});

/// Lembretes atrasados: status IN (pendente, adiado) E
///   (dataAlvo < início de hoje OU kmAtual > kmAlvo).
///
/// Lembretes adiados cuja nova data já passou também aparecem aqui
/// (issue #116).
final lembretesAtrasadosProvider = StreamProvider<List<Lembrete>>((ref) {
  final todosAsync = ref.watch(_todosLembretesProvider);
  final kmAsync = ref.watch(kmAtualPorVeiculoProvider);
  if (todosAsync.isLoading || kmAsync.isLoading) return const Stream.empty();
  if (todosAsync.hasError) {
    return Stream.error(todosAsync.error!, todosAsync.stackTrace!);
  }
  if (kmAsync.hasError) {
    return Stream.error(kmAsync.error!, kmAsync.stackTrace!);
  }
  final lista = todosAsync.value ?? const <Lembrete>[];
  final kmMap = kmAsync.value ?? const <String, int>{};
  final filtrada = lista.where((Lembrete l) => _isAtrasado(l, kmMap)).toList()
    ..sort(_sortAtrasados);
  return Stream.value(filtrada);
});

/// Lembretes concluídos: status == concluido apenas.
///
/// Lembretes adiados não aparecem mais aqui; eles ficam em Pendentes ou
/// Atrasados conforme a nova data_alvo (issue #116).
final lembretesConcluidosProvider = StreamProvider<List<Lembrete>>((ref) {
  final todosAsync = ref.watch(_todosLembretesProvider);
  if (todosAsync.isLoading) return const Stream.empty();
  if (todosAsync.hasError) {
    return Stream.error(todosAsync.error!, todosAsync.stackTrace!);
  }
  final lista = todosAsync.value ?? const <Lembrete>[];
  final filtrada =
      lista.where((Lembrete l) => l.status == StatusLembrete.concluido).toList()
        ..sort(_sortConcluidos);
  return Stream.value(filtrada);
});

// ── Comparadores ─────────────────────────────────────────────────────────────

int _sortPendentes(Lembrete a, Lembrete b) {
  // Lembretes com data vêm antes dos sem data; entre si, mais próximos primeiro.
  if (a.dataAlvo != null && b.dataAlvo != null) {
    return a.dataAlvo!.compareTo(b.dataAlvo!);
  }
  if (a.dataAlvo != null) return -1;
  if (b.dataAlvo != null) return 1;
  // Sem data → ordena por km_alvo asc.
  final aKm = a.kmAlvo ?? 0;
  final bKm = b.kmAlvo ?? 0;
  return aKm.compareTo(bKm);
}

int _sortAtrasados(Lembrete a, Lembrete b) {
  // Mais atrasados primeiro (data menor = mais urgente).
  if (a.dataAlvo != null && b.dataAlvo != null) {
    return a.dataAlvo!.compareTo(b.dataAlvo!);
  }
  return 0;
}

int _sortConcluidos(Lembrete a, Lembrete b) {
  // Mais recentes primeiro.
  if (a.dataAlvo != null && b.dataAlvo != null) {
    return b.dataAlvo!.compareTo(a.dataAlvo!);
  }
  if (a.dataAlvo != null) return -1;
  if (b.dataAlvo != null) return 1;
  return 0;
}
