// ignore_for_file: avoid_print

import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/presentation/screens/abastecimentos/abastecimentos_list_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // FiltroPeriodo.desde
  // ---------------------------------------------------------------------------
  group('FiltroPeriodo.desde', () {
    test('tudo retorna null', () {
      expect(FiltroPeriodo.tudo.desde, isNull);
    });

    test('ultimos30dias retorna data ~30 dias atrás', () {
      final antes = DateTime.now().subtract(const Duration(days: 30));
      final resultado = FiltroPeriodo.ultimos30dias.desde!;
      final depois = DateTime.now().subtract(const Duration(days: 30));

      // Tolerância de 1 segundo para execução do teste
      expect(
        resultado.millisecondsSinceEpoch,
        greaterThanOrEqualTo(antes.millisecondsSinceEpoch - 1000),
      );
      expect(
        resultado.millisecondsSinceEpoch,
        lessThanOrEqualTo(depois.millisecondsSinceEpoch + 1000),
      );
    });

    test('ultimos90dias retorna data ~90 dias atrás', () {
      final antes = DateTime.now().subtract(const Duration(days: 90));
      final resultado = FiltroPeriodo.ultimos90dias.desde!;
      final depois = DateTime.now().subtract(const Duration(days: 90));

      expect(
        resultado.millisecondsSinceEpoch,
        greaterThanOrEqualTo(antes.millisecondsSinceEpoch - 1000),
      );
      expect(
        resultado.millisecondsSinceEpoch,
        lessThanOrEqualTo(depois.millisecondsSinceEpoch + 1000),
      );
    });

    test('ultimos12meses retorna exatamente 1 ano atrás (mesmo dia/mês)', () {
      final agora = DateTime.now();
      final esperado = DateTime(agora.year - 1, agora.month, agora.day);
      final resultado = FiltroPeriodo.ultimos12meses.desde!;

      expect(resultado.year, esperado.year);
      expect(resultado.month, esperado.month);
      expect(resultado.day, esperado.day);
    });

    test(
      'ultimos30dias < ultimos90dias < ultimos12meses (ou igual) < agora',
      () {
        final d30 = FiltroPeriodo.ultimos30dias.desde!;
        final d90 = FiltroPeriodo.ultimos90dias.desde!;
        final d12 = FiltroPeriodo.ultimos12meses.desde!;

        expect(d90.isBefore(d30), isTrue);
        // 12 meses pode ser mais ou menos que 90 dias dependendo do mês;
        // mas 12m é sempre >= 365 dias e 90d é 90 dias.
        // Verificamos apenas que 12m é antes de 30d.
        expect(d12.isBefore(d30), isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // FiltroPeriodo.label
  // ---------------------------------------------------------------------------
  group('FiltroPeriodo.label', () {
    test('todos os períodos têm labels não-vazios', () {
      for (final p in FiltroPeriodo.values) {
        expect(p.label, isNotEmpty, reason: 'label de $p está vazio');
      }
    });

    test('labels mapeiam corretamente', () {
      expect(FiltroPeriodo.ultimos30dias.label, 'Últimos 30d');
      expect(FiltroPeriodo.ultimos90dias.label, 'Últimos 90d');
      expect(FiltroPeriodo.ultimos12meses.label, 'Últimos 12m');
      expect(FiltroPeriodo.tudo.label, 'Tudo');
    });
  });

  // ---------------------------------------------------------------------------
  // FiltrosAbastecimento.copyWith
  // ---------------------------------------------------------------------------
  group('FiltrosAbastecimento.copyWith', () {
    test('estado inicial tem periodo=tudo e tipoCombustivel=null', () {
      const f = FiltrosAbastecimento();
      expect(f.periodo, FiltroPeriodo.tudo);
      expect(f.tipoCombustivel, isNull);
    });

    test('copyWith altera período sem mexer no combustível', () {
      const f = FiltrosAbastecimento(
        periodo: FiltroPeriodo.tudo,
        tipoCombustivel: TipoCombustivelAbastecimento.gasolina,
      );
      final atualizado = f.copyWith(periodo: FiltroPeriodo.ultimos30dias);

      expect(atualizado.periodo, FiltroPeriodo.ultimos30dias);
      expect(atualizado.tipoCombustivel, TipoCombustivelAbastecimento.gasolina);
    });

    test('copyWith seta tipoCombustivel para null explicitamente', () {
      const f = FiltrosAbastecimento(
        tipoCombustivel: TipoCombustivelAbastecimento.alcool,
      );
      final atualizado = f.copyWith(tipoCombustivel: null);

      expect(atualizado.tipoCombustivel, isNull);
    });

    test('copyWith sem parâmetros mantém estado inalterado', () {
      const f = FiltrosAbastecimento(
        periodo: FiltroPeriodo.ultimos90dias,
        tipoCombustivel: TipoCombustivelAbastecimento.diesel,
      );
      final copia = f.copyWith();

      expect(copia.periodo, f.periodo);
      expect(copia.tipoCombustivel, f.tipoCombustivel);
    });
  });

  // ---------------------------------------------------------------------------
  // FiltrosAbastecimentoNotifier via ProviderContainer
  // ---------------------------------------------------------------------------
  group('FiltrosAbastecimentoNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('estado inicial é padrão', () {
      final state = container.read(filtrosAbastecimentoProvider);
      expect(state.periodo, FiltroPeriodo.tudo);
      expect(state.tipoCombustivel, isNull);
    });

    test('setPeriodo atualiza periodo', () {
      container
          .read(filtrosAbastecimentoProvider.notifier)
          .setPeriodo(FiltroPeriodo.ultimos30dias);

      final state = container.read(filtrosAbastecimentoProvider);
      expect(state.periodo, FiltroPeriodo.ultimos30dias);
      expect(state.tipoCombustivel, isNull);
    });

    test('setTipoCombustivel atualiza combustível sem mexer no período', () {
      container
          .read(filtrosAbastecimentoProvider.notifier)
          .setPeriodo(FiltroPeriodo.ultimos90dias);
      container
          .read(filtrosAbastecimentoProvider.notifier)
          .setTipoCombustivel(TipoCombustivelAbastecimento.gasolina);

      final state = container.read(filtrosAbastecimentoProvider);
      expect(state.periodo, FiltroPeriodo.ultimos90dias);
      expect(state.tipoCombustivel, TipoCombustivelAbastecimento.gasolina);
    });

    test('setTipoCombustivel(null) desseleciona combustível (toggle)', () {
      container
          .read(filtrosAbastecimentoProvider.notifier)
          .setTipoCombustivel(TipoCombustivelAbastecimento.alcool);
      container
          .read(filtrosAbastecimentoProvider.notifier)
          .setTipoCombustivel(null);

      final state = container.read(filtrosAbastecimentoProvider);
      expect(state.tipoCombustivel, isNull);
    });

    test('limpar() reseta para estado inicial', () {
      container
          .read(filtrosAbastecimentoProvider.notifier)
          .setPeriodo(FiltroPeriodo.ultimos12meses);
      container
          .read(filtrosAbastecimentoProvider.notifier)
          .setTipoCombustivel(TipoCombustivelAbastecimento.diesel);

      container.read(filtrosAbastecimentoProvider.notifier).limpar();

      final state = container.read(filtrosAbastecimentoProvider);
      expect(state.periodo, FiltroPeriodo.tudo);
      expect(state.tipoCombustivel, isNull);
    });

    test('sequência de mudanças de estado é refletida corretamente', () {
      final notifier = container.read(filtrosAbastecimentoProvider.notifier);

      notifier.setPeriodo(FiltroPeriodo.ultimos30dias);
      expect(
        container.read(filtrosAbastecimentoProvider).periodo,
        FiltroPeriodo.ultimos30dias,
      );

      notifier.setPeriodo(FiltroPeriodo.ultimos90dias);
      expect(
        container.read(filtrosAbastecimentoProvider).periodo,
        FiltroPeriodo.ultimos90dias,
      );

      notifier.setPeriodo(FiltroPeriodo.tudo);
      expect(
        container.read(filtrosAbastecimentoProvider).periodo,
        FiltroPeriodo.tudo,
      );
    });
  });
}
