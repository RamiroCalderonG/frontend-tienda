import 'categoria.dart';
import 'promocion.dart';

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
  final String? foto;
  final Categoria? categoria;
  final Promocion? promocion;

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
    this.foto,
    this.categoria,
    this.promocion,
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
        foto: json['foto'],
        categoria: json['categoria'] != null
            ? Categoria.fromJson(json['categoria'])
            : null,
        promocion: json['promocion'] != null
            ? Promocion.fromJson(json['promocion'])
            : null,
      );
}
