import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/producto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categorias_provider.dart';
import '../../providers/productos_provider.dart';
import 'categorias_dialog.dart';
import 'producto_dialog.dart';

class ProductosScreen extends ConsumerStatefulWidget {
  const ProductosScreen({super.key});

  @override
  ConsumerState<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends ConsumerState<ProductosScreen> {
  String? _categoriaFiltro;
  String _busqueda = '';

  Future<void> _confirmarEliminar(Producto producto) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${producto.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(productosProvider.notifier).eliminar(producto.id);
    }
  }

  void _abrirDialog({Producto? producto}) {
    showDialog(
      context: context,
      builder: (_) => ProductoDialog(producto: producto),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productosProvider);
    final categoriasAsync = ref.watch(categoriasProvider);
    final isAdmin = ref.watch(authProvider).valueOrNull?.user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Categorías',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const CategoriasDialog(),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(productosProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _abrirDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo producto'),
            )
          : null,
      body: Column(
        children: [
          // Barra de búsqueda + filtro categorías
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
                  ),
                ),
              ],
            ),
          ),
          // Chips de categorías
          categoriasAsync.when(
            data: (cats) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: _categoriaFiltro == null,
                    onSelected: (_) => setState(() => _categoriaFiltro = null),
                  ),
                  const SizedBox(width: 8),
                  ...cats.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(c.nombre),
                          selected: _categoriaFiltro == c.id,
                          onSelected: (_) => setState(() =>
                              _categoriaFiltro = _categoriaFiltro == c.id ? null : c.id),
                        ),
                      )),
                ],
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 8),
          // Lista de productos
          Expanded(
            child: productosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (productos) {
                final filtrados = productos.where((p) {
                  final matchBusqueda = _busqueda.isEmpty ||
                      p.nombre.toLowerCase().contains(_busqueda);
                  final matchCategoria = _categoriaFiltro == null ||
                      p.categoriaId == _categoriaFiltro;
                  return matchBusqueda && matchCategoria;
                }).toList();

                if (filtrados.isEmpty) {
                  return const Center(child: Text('No hay productos'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ProductoCard(
                    producto: filtrados[i],
                    isAdmin: isAdmin,
                    onEditar: () => _abrirDialog(producto: filtrados[i]),
                    onEliminar: () => _confirmarEliminar(filtrados[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final bool isAdmin;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _ProductoCard({
    required this.producto,
    required this.isAdmin,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                producto.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (!producto.activo)
              const Chip(label: Text('Inactivo'), backgroundColor: Colors.grey),
            if (producto.stockBajo && producto.activo)
              Chip(
                label: const Text('Stock bajo'),
                backgroundColor: Colors.orange.shade100,
                labelStyle: const TextStyle(color: Colors.deepOrange),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (producto.categoria != null)
              Text(producto.categoria!.nombre,
                  style: TextStyle(color: cs.primary, fontSize: 12)),
            if (producto.descripcion != null)
              Text(producto.descripcion!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                _InfoChip(label: 'Precio', value: '\$${producto.precio.toStringAsFixed(2)}'),
                const SizedBox(width: 8),
                _InfoChip(label: 'Costo', value: '\$${producto.costo.toStringAsFixed(2)}'),
                const SizedBox(width: 8),
                _InfoChip(
                  label: 'Stock',
                  value: '${producto.stock}',
                  color: producto.stockBajo ? Colors.deepOrange : null,
                ),
              ],
            ),
          ],
        ),
        trailing: isAdmin
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEditar),
                  IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: onEliminar),
                ],
              )
            : null,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
