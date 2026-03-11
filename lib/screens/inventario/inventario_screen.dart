import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/movimiento.dart';
import '../../models/producto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/productos_provider.dart';
import '../../services/inventario_service.dart';

class InventarioScreen extends ConsumerStatefulWidget {
  const InventarioScreen({super.key});

  @override
  ConsumerState<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends ConsumerState<InventarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Movimiento> _movimientos = [];
  bool _cargandoHistorial = false;

  final _fmtFecha = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1 && _movimientos.isEmpty) _cargarHistorial();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  InventarioService get _service =>
      InventarioService(ref.read(apiClientProvider));

  Future<void> _cargarHistorial() async {
    setState(() => _cargandoHistorial = true);
    try {
      final result = await _service.listarMovimientos();
      if (mounted) setState(() => _movimientos = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoHistorial = false);
    }
  }

  Future<void> _doRestock(Producto producto) async {
    final result = await showDialog<Movimiento>(
      context: context,
      builder: (_) => _RestockDialog(producto: producto, service: _service),
    );
    if (result != null) {
      // Refresca productos para actualizar stock mostrado
      await ref.read(productosProvider.notifier).refresh();
      // Si el historial ya estaba cargado, agrega al inicio
      if (_movimientos.isNotEmpty) {
        setState(() => _movimientos = [result, ..._movimientos]);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restock de ${producto.nombre}: +${result.cantidad} unidades'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Restock'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tab Restock ─────────────────────────────────────
          productosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (productos) {
              final activos = productos.where((p) => p.activo).toList()
                ..sort((a, b) => a.nombre.compareTo(b.nombre));
              if (activos.isEmpty) {
                return const Center(child: Text('No hay productos'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: activos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _ProductoRestockTile(
                  producto: activos[i],
                  onRestock: () => _doRestock(activos[i]),
                ),
              );
            },
          ),
          // ── Tab Historial ────────────────────────────────────
          _cargandoHistorial
              ? const Center(child: CircularProgressIndicator())
              : _movimientos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Sin movimientos registrados'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _cargarHistorial,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Cargar historial'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarHistorial,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _movimientos.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _MovimientoTile(
                          movimiento: _movimientos[i],
                          fmtFecha: _fmtFecha,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}

// ── Tile producto (tab Restock) ──────────────────────────────

class _ProductoRestockTile extends StatelessWidget {
  final Producto producto;
  final VoidCallback onRestock;

  const _ProductoRestockTile({required this.producto, required this.onRestock});

  @override
  Widget build(BuildContext context) {
    final stockBajo = producto.stock <= producto.stockMinimo;
    return ListTile(
      title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: producto.categoria != null ? Text(producto.categoria!) : null,
      leading: CircleAvatar(
        backgroundColor: stockBajo ? Colors.orange.shade50 : Colors.grey.shade100,
        child: Icon(
          stockBajo ? Icons.warning_amber_outlined : Icons.inventory_2_outlined,
          color: stockBajo ? Colors.orange : Colors.grey,
          size: 20,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Stock: ${producto.stock}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: stockBajo ? Colors.orange : null,
                ),
              ),
              Text('Mín: ${producto.stockMinimo}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onRestock,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Restock'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile movimiento (tab Historial) ─────────────────────────

class _MovimientoTile extends StatelessWidget {
  final Movimiento movimiento;
  final DateFormat fmtFecha;

  const _MovimientoTile({required this.movimiento, required this.fmtFecha});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade50,
        child: Text(
          '+${movimiento.cantidad}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(movimiento.nombreProducto,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${movimiento.stockAntes} → ${movimiento.stockDespues} unidades  ·  ${movimiento.userName}',
            style: const TextStyle(fontSize: 12),
          ),
          if (movimiento.notas != null && movimiento.notas!.isNotEmpty)
            Text(movimiento.notas!,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      trailing: Text(
        fmtFecha.format(movimiento.createdAt),
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      isThreeLine: movimiento.notas != null && movimiento.notas!.isNotEmpty,
    );
  }
}

// ── Dialog restock ───────────────────────────────────────────

class _RestockDialog extends StatefulWidget {
  final Producto producto;
  final InventarioService service;

  const _RestockDialog({required this.producto, required this.service});

  @override
  State<_RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<_RestockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final mov = await widget.service.restock(
        productoId: widget.producto.id,
        cantidad: int.parse(_cantidadCtrl.text),
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, mov);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Restock — ${widget.producto.nombre}'),
      content: SizedBox(
        width: 340,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock actual: ${widget.producto.stock}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cantidadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cantidad a agregar',
                  prefixText: '+',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Ingresa un número mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Ej: Proveedor X, factura 123',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar'),
        ),
      ],
    );
  }
}
