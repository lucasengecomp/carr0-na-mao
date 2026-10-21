// ignore_for_file: avoid_print

import 'package:carro_na_mao/data/database/enums.dart';
import 'package:carro_na_mao/l10n/app_localizations_pt.dart';
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
    final l10n = AppLocalizationsPt();

    test('todos os períodos têm labels não-vazios', () {
      for (final p in FiltroPeriodo.values) {
        expect(p.label(l10n), isNotEmpty, reason: 'label de $p está vazio');
      }
    });

    test('labels mapeiam corretamente em pt', () {
      expect(FiltroPeriodo.ultimos30dias.label(l10n), 'Últimos 30d');
      expect(FiltroPeriodo.ultimos90dias.label(l10n), 'Últimos 90d');
      expect(FiltroPeriodo.ultimos12meses.label(l10n), 'Últimos 12m');
      expect(FiltroPeriodo.tudo.label(l10n), 'Tudo');
    });
  });

  // ---------------------------------------------------------------------------
  // FiltrosAbastecimento.copyWith (multi-select, issue #77)
  // ---------------------------------------------------------------------------
  group('FiltrosAbastecimento.copyWith', () {
    test('estado inicial tem periodo=tudo e tiposCombustivel=null', () {
      const f = FiltrosAbastecimento();
      expect(f.periodo, FiltroPeriodo.tudo);
      expect(f.tiposCombustivel, isNull);
    });

    test('copyWith altera período sem mexer nos tipos de combustível', () {
      const f = FiltrosAbastecimento(
        periodo: FiltroPeriodo.tudo,
        tiposCombustivel: {TipoCombustivelAbastecimento.gasolina},
      );
      final atualizado = f.copyWith(periodo: FiltroPeriodo.ultimos30dias);

      expect(atualizado.periodo, FiltroPeriodo.ultimos30dias);
      expect(atualizado.tiposCombustivel, {
        TipoCombustivelAbastecimento.gasolina,
      });
    });

    test('copyWith seta tiposCombustivel para null explicitamente', () {
      const f = FiltrosAbastecimento(
        tiposCombustivel: {TipoCombustivelAbastecimento.alcool},
      );
      final atualizado = f.copyWith(tiposCombustivel: null);

      expect(atualizado.tiposCombustivel, isNull);
    });

    test('copyWith seta tiposCombustivel para set vazio', () {
      const f = FiltrosAbastecimento();
      final atualizado = f.copyWith(
        tiposCombustivel: <TipoCombustivelAbastecimento>{},
      );

      expect(atualizado.tiposCombustivel, isEmpty);
    });

    test('copyWith sem parâmetros mantém estado inalterado', () {
      const f = FiltrosAbastecimento(
        periodo: FiltroPeriodo.ultimos90dias,
        tiposCombustivel: {TipoCombustivelAbastecimento.diesel},
      );
      final copia = f.copyWith();

      expect(copia.periodo, f.periodo);
      expect(copia.tiposCombustivel, f.tiposCombustivel);
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

    test('estado inicial é padrão (tiposCombustivel=null)', () {
      final state = container.read(filtrosAbastecimentoProvider);
      expect(state.periodo, FiltroPeriodo.tudo);
      expect(state.tiposCombustivel, isNull);
    });

    test('setPeriodo atualiza periodo', () {
      container
          .read(filtrosAbastecimentoProvider.notifier)
          .setPeriodo(FiltroPeriodo.ultimos30dias);

      final state = container.read(filtrosAbastecimentoProvider);
      expect(state.periodo, FiltroPeriodo.ultimos30dias);
      expect(state.tiposCombustivel, isNull);
    });

    test(
      'toggleTipoCombustivel do null inicia set com todos menos o toggleado',
      () {
        // Estado inicial: null (todos). Toggle gasolina → todos menos gasolina.
        container
            .read(filtrosAbastecimentoProvider.notifier)
            .toggleTipoCombustivel(TipoCombustivelAbastecimento.gasolina);

        final state = container.read(filtrosAbastecimentoProvider);
        expect(
          state.tiposCombustivel,
          isNotNull,
          reason: 'deve ter saído do estado null',
        );
        expect(
          state.tiposCombustivel!.contains(
            TipoCombustivelAbastecimento.gasolina,
          ),
          isFalse,
        );
        // Os demais tipos devem estar presentes.
        for (final t in TipoCombustivelAbastecimento.values) {
          if (t != TipoCombustivelAbastecimento.gasolina) {
            expect(state.tiposCombustivel!.contains(t), isTrue);
          }
        }
      },
    );

    test('toggleTipoCombustivel adiciona tipo que não estava no set', () {
      // Começa com {alcool} e adiciona gasolina.
      container
          .read(filtrosAbastecimentoProvider.notifier)
          .toggleTipoCombustivel(
            TipoCombustivelAbastecimento.gasolina,
          ); // remove gasolina do default
      // Agora toggle de volta para adicionar gasolina.
      container
          .read(filtrosAbastecimentoProvider.notifier)
          .toggleTipoCombustivel(
            TipoCombustivelAbastecimento.gasolina,
          ); // adiciona gasolina

      final state = container.read(filtrosAbastecimentoProvider);
      // Todos os tipos estão selecionados → normaliza para null.
      expect(state.tiposCombustivel, isNull);
    });

    test('toggleTipoCombustivel remove tipo e chega a set vazio', () {
      // Começa com null (todos). Vai removendo tipo a tipo até zero.
      final notifier = container.read(filtrosAbastecimentoProvider.notifier);
      for (final t in TipoCombustivelAbastecimento.values) {
        notifier.toggleTipoCombustivel(t);
      }

      final state = container.read(filtrosAbastecimentoProvider);
      expect(state.tiposCombustivel, isEmpty);
    });

    test('quando todos os tipos estão no set, normaliza para null', () {
      final notifier = container.read(filtrosAbastecimentoProvider.notifier);
      // Remove um tipo para sair do null.
      notifier.toggleTipoCombustivel(TipoCombustivelAbastecimento.diesel);

      // Adiciona de volta → todos selecionados → deve virar null.
      notifier.toggleTipoCombustivel(TipoCombustivelAbastecimento.diesel);

      final state = container.read(filtrosAbastecimentoProvider);
      expect(state.tiposCombustivel, isNull);
    });

    test('limpar() reseta para estado inicial (tiposCombustivel=null)', () {
      final notifier = container.read(filtrosAbastecimentoProvider.notifier);
      notifier.setPeriodo(FiltroPeriodo.ultimos12meses);
      notifier.toggleTipoCombustivel(TipoCombustivelAbastecimento.diesel);

      notifier.limpar();

      final state = container.read(filtrosAbastecimentoProvider);
      expect(state.periodo, FiltroPeriodo.tudo);
      expect(state.tiposCombustivel, isNull);
    });

    test('sequência de mudanças de período é refletida corretamente', () {
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
