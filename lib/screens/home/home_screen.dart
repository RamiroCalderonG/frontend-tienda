import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).valueOrNull;
    final user = auth?.user;
    final store = auth?.store;
    final cs = Theme.of(context).colorScheme;

    final modulos = user?.isSuperAdmin == true
        ? [
            _Modulo(icon: Icons.add_business_outlined, label: 'Tiendas', route: '/tiendas'),
          ]
        : [
            _Modulo(icon: Icons.point_of_sale_outlined, label: 'Ventas', route: '/ventas'),
            _Modulo(icon: Icons.inventory_2_outlined, label: 'Productos', route: '/productos'),
            _Modulo(icon: Icons.bar_chart_outlined, label: 'Reportes', route: '/reportes'),
            _Modulo(icon: Icons.warehouse_outlined, label: 'Inventario', route: '/inventario'),
            if (user?.isAdmin == true)
              _Modulo(icon: Icons.people_outline, label: 'Usuarios', route: '/usuarios'),
            if (user?.isAdmin == true)
              _Modulo(icon: Icons.tune_outlined, label: 'Ajustes', route: '/ajustes'),
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: cs.surface,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 16,
              bottom: 20,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store?.name ?? 'Tienda',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hola, ${user?.name ?? ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Cerrar sesión',
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topCenter,
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: modulos
                      .map((m) => _ModuloCard(
                            modulo: m,
                            onTap: () => context.push(m.route),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Modulo {
  final IconData icon;
  final String label;
  final String route;
  const _Modulo({required this.icon, required this.label, required this.route});
}

class _ModuloCard extends StatelessWidget {
  final _Modulo modulo;
  final VoidCallback onTap;

  const _ModuloCard({required this.modulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 150,
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(modulo.icon, size: 22, color: cs.primary),
              ),
              Text(
                modulo.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
