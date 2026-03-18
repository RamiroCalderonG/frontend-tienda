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
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.2,
                ),
                itemCount: modulos.length,
                itemBuilder: (context, i) => _ModuloCard(
                  modulo: modulos[i],
                  onTap: () => context.push(modulos[i].route),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(modulo.icon, size: 24, color: cs.primary),
              ),
              Text(
                modulo.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
