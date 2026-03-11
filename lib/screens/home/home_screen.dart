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

    return Scaffold(
      appBar: AppBar(
        title: Text(store?.name ?? 'Tienda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${user?.name ?? ''}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              'Rol: ${user?.role ?? ''}  •  ${store?.name ?? ''}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Text(
              'Módulos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _ModuloCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Productos',
                  onTap: () => context.push('/productos'),
                ),
                _ModuloCard(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Ventas',
                  onTap: () => context.push('/ventas'),
                ),
                _ModuloCard(icon: Icons.bar_chart_outlined, label: 'Reportes', onTap: () => context.push('/reportes')),
                if (user?.isAdmin == true)
                  _ModuloCard(
                    icon: Icons.people_outline,
                    label: 'Usuarios',
                    onTap: () => context.push('/usuarios'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuloCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ModuloCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disponible = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        height: 120,
        decoration: BoxDecoration(
          color: disponible
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disponible
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: disponible
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: disponible ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
            ),
            if (!disponible)
              const Text('Próximamente', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
