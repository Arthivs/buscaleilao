import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/imoveis/imoveis_screen.dart';
import '../screens/imoveis/imovel_detalhe_screen.dart';
import '../screens/mapa/mapa_screen.dart';
import '../screens/simulador/simulador_screen.dart';
import '../screens/alertas/alertas_screen.dart';
import '../widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isLoginPage = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/registrar');

      if (!isAuth && !isLoginPage) return '/login';
      if (isAuth && isLoginPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/registrar', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/imoveis', builder: (_, __) => const ImoveisScreen()),
          GoRoute(
            path: '/imoveis/:id',
            builder: (_, state) => ImovelDetalheScreen(
              imovelId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(path: '/mapa', builder: (_, __) => const MapaScreen()),
          GoRoute(
            path: '/simulador',
            builder: (_, state) => SimuladorScreen(
              imovelId: int.tryParse(state.uri.queryParameters['imovel_id'] ?? ''),
            ),
          ),
          GoRoute(path: '/alertas', builder: (_, __) => const AlertasScreen()),
        ],
      ),
    ],
  );
});
