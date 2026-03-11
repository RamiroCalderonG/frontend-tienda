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
      await ref.read(productosProvider.notifier).refresh();
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

  Future<void> _doAjuste(Producto producto) async {
    final result = await showDialog<Movimiento>(
      context: context,
      builder: (_) => _AjusteDialog(producto: producto, service: _service),
    );
    if (result != null) {
      await ref.read(productosProvider.notifier).refresh();
      if (_movimientos.isNotEmpty) {
        setState(() => _movimientos = [result, ..._movimientos]);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ajuste de ${producto.nombre}: ${result.cantidad} unidades'),
            backgroundColor: Colors.orange,
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
            Tab(text: 'Ajustes'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tab Ajustes ──────────────────────────────────────
          productosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (productos) {
              final activos = productos.where((p) => p.activo).toList()
                ..sort((a, b) => a.nombre.compareTo(b.nombre));
              if (activos.isEmpty) {
                return const Center(child: Text('No hay productos'));
              }
              return Column(
                children: [
                  _ValorInventarioHeader(productos: activos),
                  const Divider(height: 1),
                  Expanded(child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: activos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _ProductoRestockTile(
                      producto: activos[i],
                      onRestock: () => _doRestock(activos[i]),
                      onAjuste: () => _doAjuste(activos[i]),
                    ),
                  )),
                ],
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

// ── Header valor de inventario ───────────────────────────────

class _ValorInventarioHeader extends StatelessWidget {
  final List<Producto> productos;
  const _ValorInventarioHeader({required this.productos});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
    final valorCosto = productos.fold(0.0, (s, p) => s + p.stock * p.costo);
    final valorVenta = productos.fold(0.0, (s, p) => s + p.stock * p.precio);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _MiniValorCard(
              label: 'Invertido en stock',
              value: fmt.format(valorCosto),
              icon: Icons.price_change_outlined,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniValorCard(
              label: 'Valor a precio venta',
              value: fmt.format(valorVenta),
              icon: Icons.sell_outlined,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniValorCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniValorCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: color)),
                Text(value,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile producto (tab Ajustes) ──────────────────────────────

class _ProductoRestockTile extends StatelessWidget {
  final Producto producto;
  final VoidCallback onRestock;
  final VoidCallback onAjuste;

  const _ProductoRestockTile({
    required this.producto,
    required this.onRestock,
    required this.onAjuste,
  });

  @override
  Widget build(BuildContext context) {
    final stockBajo = producto.stock <= producto.stockMinimo;
    return ListTile(
      title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: producto.categoria != null ? Text(producto.categoria!.nombre) : null,
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
          IconButton(
            onPressed: onAjuste,
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.orange.shade700,
            tooltip: 'Merma / Muestra',
          ),
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

const _tipoLabel = {
  'restock': 'Restock',
  'merma': 'Merma',
  'muestra': 'Muestra',
  'otro': 'Ajuste',
};

class _MovimientoTile extends StatelessWidget {
  final Movimiento movimiento;
  final DateFormat fmtFecha;

  const _MovimientoTile({required this.movimiento, required this.fmtFecha});

  @override
  Widget build(BuildContext context) {
    final esPositivo = movimiento.cantidad >= 0;
    final color = esPositivo ? Colors.green : Colors.orange;
    final signo = esPositivo ? '+' : '';
    final tipoTexto = _tipoLabel[movimiento.tipo] ?? movimiento.tipo ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.shade50,
        child: Text(
          '$signo${movimiento.cantidad}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color.shade700,
            fontSize: 12,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(movimiento.nombreProducto,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (tipoTexto.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: esPositivo ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tipoTexto,
                style: TextStyle(
                  fontSize: 11,
                  color: esPositivo ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${movimiento.stockAntes} → ${movimiento.stockDespues} uds  ·  ${movimiento.userName}',
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

// ── Dialog ajuste (merma / muestra / otro) ───────────────────

class _AjusteDialog extends StatefulWidget {
  final Producto producto;
  final InventarioService service;

  const _AjusteDialog({required this.producto, required this.service});

  @override
  State<_AjusteDialog> createState() => _AjusteDialogState();
}

class _AjusteDialogState extends State<_AjusteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  String _tipo = 'merma';
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
      final mov = await widget.service.ajuste(
        productoId: widget.producto.id,
        cantidad: int.parse(_cantidadCtrl.text),
        tipo: _tipo,
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
      title: Text('Ajuste — ${widget.producto.nombre}'),
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
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Motivo'),
                items: const [
                  DropdownMenuItem(value: 'merma', child: Text('Merma')),
                  DropdownMenuItem(value: 'muestra', child: Text('Muestra gratis')),
                  DropdownMenuItem(value: 'otro', child: Text('Otro')),
                ],
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cantidadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cantidad a descontar',
                  prefixText: '-',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Ingresa un número mayor a 0';
                  if (n > widget.producto.stock) return 'No puede superar el stock actual';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Ej: 3 panes quemados, muestra para cliente',
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
          style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700),
          child: _guardando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmar'),
        ),
      ],
    );
  }
}
