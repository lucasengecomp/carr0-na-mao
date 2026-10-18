import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/abastecimentos/abastecimento_form_screen.dart';
import 'screens/abastecimentos/abastecimentos_list_screen.dart';
import 'screens/comparador/comparador_screen.dart';
import 'screens/config/config_screen.dart';
import 'screens/dashboard/dashboard_graficos_screen.dart';
import 'screens/dashboard/dashboard_home_screen.dart';
import 'screens/despesas/despesa_form_screen.dart';
import 'screens/despesas/despesas_list_screen.dart';
import 'screens/lembretes/lembretes_list_screen.dart';
import 'screens/manutencoes/manutencao_form_screen.dart';
import 'screens/manutencoes/manutencoes_list_screen.dart';
import 'screens/veiculos/veiculo_form_screen.dart';
import 'screens/veiculos/veiculos_list_screen.dart';
import 'shell_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScaffold(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/abastecimentos',
              builder: (context, state) => const AbastecimentosListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/manutencoes',
              builder: (context, state) => const ManutencoesListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/despesas',
              builder: (context, state) => const DespesasListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lembretes',
              builder: (context, state) => const LembretesListScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/abastecimentos/novo',
      builder: (context, state) => const AbastecimentoFormScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/abastecimentos/:id/editar',
      builder: (context, state) =>
          AbastecimentoFormScreen(id: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/manutencoes/novo',
      builder: (context, state) => const ManutencaoFormScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/manutencoes/:id/editar',
      builder: (context, state) =>
          ManutencaoFormScreen(id: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/despesas/novo',
      builder: (context, state) => const DespesaFormScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/despesas/:id/editar',
      builder: (context, state) =>
          DespesaFormScreen(id: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/comparador',
      builder: (context, state) => const ComparadorScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/dashboard/graficos',
      builder: (context, state) {
        final placa = state.uri.queryParameters['placa'] ?? '';
        return DashboardGraficosScreen(placa: placa);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/config',
      builder: (context, state) => const ConfigScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/veiculos',
      builder: (context, state) => const VeiculosListScreen(),
      routes: [
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: 'novo',
          builder: (context, state) => const VeiculoFormScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: ':placa/editar',
          builder: (context, state) =>
              VeiculoFormScreen(placa: state.pathParameters['placa']),
        ),
      ],
    ),
  ],
);
