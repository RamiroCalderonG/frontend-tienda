import 'categoria.dart';

class Producto {
  final String id;
  final String storeId;
  final String? categoriaId;
  final String nombre;
  final String? descripcion;
  final double costo;
  final double precio;
  final int stock;
  final int stockMinimo;
  final bool activo;
  final Categoria? categoria;

  const Producto({
    required this.id,
    required this.storeId,
    this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.costo,
    required this.precio,
    required this.stock,
    required this.stockMinimo,
    required this.activo,
    this.categoria,
  });

  bool get stockBajo => stock <= stockMinimo;

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        id: json['id'],
        storeId: json['store_id'],
        categoriaId: json['categoria_id'],
        nombre: json['nombre'],
        descripcion: json['descripcion'],
        costo: (json['costo'] as num).toDouble(),
        precio: (json['precio'] as num).toDouble(),
        stock: json['stock'],
        stockMinimo: json['stock_minimo'],
        activo: json['activo'],
        categoria: json['categoria'] != null
            ? Categoria.fromJson(json['categoria'])
            : null,
      );
}
