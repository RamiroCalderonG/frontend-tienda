import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categorias_provider.dart';
import '../../providers/productos_provider.dart';
import '../../services/venta_service.dart';

class VentasScreen extends ConsumerStatefulWidget {
  const VentasScreen({super.key});

  @override
  ConsumerState<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends ConsumerState<VentasScreen> {
  final List<TicketItem> _ticket = [];
  String? _categoriaFiltro;
  bool _procesando = false;

  double get _total => _ticket.fold(0, (sum, i) => sum + i.subtotal);

  void _agregarProducto(Producto producto) {
    setState(() {
      final idx = _ticket.indexWhere((i) => i.productoId == producto.id);
      if (idx >= 0) {
        if (_ticket[idx].cantidad < producto.stock) {
          _ticket[idx].cantidad++;
        }
      } else {
        _ticket.add(TicketItem(
          productoId: producto.id,
          nombre: producto.nombre,
          precio: producto.precio,
        ));
      }
    });
  }

  void _quitarUno(int idx) {
    setState(() {
      if (_ticket[idx].cantidad > 1) {
        _ticket[idx].cantidad--;
      } else {
        _ticket.removeAt(idx);
      }
    });
  }

  void _cancelar() {
    setState(() => _ticket.clear());
  }

  Future<void> _cobrar(String metodoPago) async {
    if (_ticket.isEmpty) return;
    setState(() => _procesando = true);

    try {
      final ventaService = VentaService(ref.read(apiClientProvider));
      await ventaService.crear(metodoPago: metodoPago, items: _ticket);

      await ref.read(productosProvider.notifier).refresh();

      setState(() => _ticket.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta registrada — ${metodoPago == 'efectivo' ? 'Efectivo' : 'Transferencia'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
      body: Row(
        children: [
          _productosPanel(),
          _ticketPanel(),
        ],
      ),
    );
  }

  Widget _productosPanel() {
    final productosAsync = ref.watch(productosProvider);
    final categoriasAsync = ref.watch(categoriasProvider);

    return Expanded(
      child: Column(
        children: [
          // Filtro categorías
          categoriasAsync.when(
            data: (cats) => cats.isEmpty
                ? const SizedBox()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Todos'),
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
          // Grid de productos
          Expanded(
            child: productosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (productos) {
                final filtrados = productos.where((p) {
                  final tieneStock = p.stock > 0 && p.activo;
                  final matchCat = _categoriaFiltro == null || p.categoriaId == _categoriaFiltro;
                  return tieneStock && matchCat;
                }).toList();

                if (filtrados.isEmpty) {
                  return const Center(child: Text('No hay productos disponibles'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    mainAxisExtent: 100,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtrados.length,
                  itemBuilder: (_, i) => _ProductoBtn(
                    producto: filtrados[i],
                    onTap: () => _agregarProducto(filtrados[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketPanel() {
    final productosAsync = ref.watch(productosProvider);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Header ticket
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (_ticket.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                    tooltip: 'Cancelar venta',
                    onPressed: _cancelar,
                  ),
              ],
            ),
          ),
          // Items del ticket
          Expanded(
            child: _ticket.isEmpty
                ? const Center(
                    child: Text(
                      'Toca un producto\npara agregarlo',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _ticket.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _TicketItemRow(
                      item: _ticket[i],
                      onMenos: () => _quitarUno(i),
                      onMas: () {
                        final productos = productosAsync.valueOrNull ?? [];
                        final p = productos.firstWhere(
                          (p) => p.id == _ticket[i].productoId,
                          orElse: () => throw Exception(),
                        );
                        _agregarProducto(p);
                      },
                    ),
                  ),
          ),
          // Total y botones de cobro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (_ticket.isEmpty || _procesando) ? null : () => _cobrar('efectivo'),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Cobrar — Efectivo'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: (_ticket.isEmpty || _procesando) ? null : () => _cobrar('transferencia'),
                    icon: const Icon(Icons.phone_android_outlined),
                    label: const Text('Cobrar — Transferencia'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ───────────────────────────────────────

class _TicketItemRow extends StatelessWidget {
  final TicketItem item;
  final VoidCallback onMenos;
  final VoidCallback onMas;

  const _TicketItemRow({required this.item, required this.onMenos, required this.onMas});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('\$${item.precio.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: onMenos,
                borderRadius: BorderRadius.circular(4),
                child: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${item.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              InkWell(
                onTap: onMas,
                borderRadius: BorderRadius.circular(4),
                child: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '\$${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ProductoBtn extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const _ProductoBtn({required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                producto.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${producto.precio.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              'Stock: ${producto.stock}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
