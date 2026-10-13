import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/placeholder_screen.dart';
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
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/abastecimentos',
              builder: (context, state) => const PlaceholderScreen(
                titulo: 'Abastecimentos',
                descricao: 'Lista e cadastro de abastecimentos (issue #12).',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/manutencoes',
              builder: (context, state) => const PlaceholderScreen(
                titulo: 'Manutenções',
                descricao: 'Lista e cadastro de manutenções (issue #17).',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/despesas',
              builder: (context, state) => const PlaceholderScreen(
                titulo: 'Despesas',
                descricao: 'Despesas recorrentes e ocorrências (issue #21).',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lembretes',
              builder: (context, state) => const PlaceholderScreen(
                titulo: 'Lembretes',
                descricao: 'Lembretes de manutenção e avulsos (issue #25).',
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/comparador',
      builder: (context, state) => const PlaceholderScreen(
        titulo: 'Comparador',
        descricao: 'Comparador álcool x gasolina (issue #30).',
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/config',
      builder: (context, state) => const PlaceholderScreen(
        titulo: 'Configurações',
        descricao: 'Veículos, export, política de privacidade.',
      ),
    ),
  ],
);
