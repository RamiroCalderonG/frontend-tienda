import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/producto.dart';
import '../../providers/categorias_provider.dart';
import '../../providers/productos_provider.dart';

class ProductoDialog extends ConsumerStatefulWidget {
  final Producto? producto; // null = crear, not null = editar

  const ProductoDialog({super.key, this.producto});

  @override
  ConsumerState<ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends ConsumerState<ProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _costo;
  late final TextEditingController _precio;
  late final TextEditingController _stock;
  late final TextEditingController _stockMinimo;
  String? _categoriaId;
  bool _activo = true;
  bool _loading = false;

  bool get esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _descripcion = TextEditingController(text: p?.descripcion ?? '');
    _costo = TextEditingController(text: p?.costo.toString() ?? '0');
    _precio = TextEditingController(text: p?.precio.toString() ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '0');
    _stockMinimo = TextEditingController(text: p?.stockMinimo.toString() ?? '5');
    _categoriaId = p?.categoriaId;
    _activo = p?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _costo.dispose();
    _precio.dispose();
    _stock.dispose();
    _stockMinimo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = {
      'nombre': _nombre.text.trim(),
      'descripcion': _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
      'costo': double.parse(_costo.text),
      'precio': double.parse(_precio.text),
      'stock': int.parse(_stock.text),
      'stock_minimo': int.parse(_stockMinimo.text),
      'categoria_id': _categoriaId,
      if (esEdicion) 'activo': _activo,
    };

    try {
      if (esEdicion) {
        await ref.read(productosProvider.notifier).actualizar(widget.producto!.id, body);
      } else {
        await ref.read(productosProvider.notifier).crear(body);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasProvider);

    return AlertDialog(
      title: Text(esEdicion ? 'Editar producto' : 'Nuevo producto'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcion,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                // Categoría
                categoriasAsync.when(
                  data: (cats) => DropdownButtonFormField<String>(
                    value: _categoriaId,
                    decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                      ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))),
                    ],
                    onChanged: (v) => setState(() => _categoriaId = v),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error al cargar categorías'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costo,
                        decoration: const InputDecoration(labelText: 'Costo', border: OutlineInputBorder(), prefixText: '\$'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _precio,
                        decoration: const InputDecoration(labelText: 'Precio *', border: OutlineInputBorder(), prefixText: '\$'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        decoration: const InputDecoration(labelText: 'Stock inicial', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockMinimo,
                        decoration: const InputDecoration(labelText: 'Stock mínimo', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                if (esEdicion) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                    title: const Text('Activo'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _loading ? null : _guardar,
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
