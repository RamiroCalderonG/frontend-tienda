import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/productos/productos_screen.dart';
import '../screens/ventas/ventas_screen.dart';
import '../screens/reportes/reportes_screen.dart';
import '../screens/usuarios/usuarios_screen.dart';
import '../screens/inventario/inventario_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = authAsync.isLoading;
      if (isLoading) return null;

      final isAuthenticated = authAsync.valueOrNull?.isAuthenticated ?? false;
      final onLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !onLogin) return '/login';
      if (isAuthenticated && onLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/productos',
        builder: (context, state) => const ProductosScreen(),
      ),
      GoRoute(
        path: '/ventas',
        builder: (context, state) => const VentasScreen(),
      ),
      GoRoute(
        path: '/reportes',
        builder: (context, state) => const ReportesScreen(),
      ),
      GoRoute(
        path: '/usuarios',
        builder: (context, state) => const UsuariosScreen(),
      ),
      GoRoute(
        path: '/inventario',
        builder: (context, state) => const InventarioScreen(),
      ),
    ],
  );
});
