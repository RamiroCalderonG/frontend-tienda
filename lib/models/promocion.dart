class Promocion {
  final int id;
  final String productoId;
  final int cantidadRequerida;
  final double precioPromocion;

  const Promocion({
    required this.id,
    required this.productoId,
    required this.cantidadRequerida,
    required this.precioPromocion,
  });

  factory Promocion.fromJson(Map<String, dynamic> json) => Promocion(
        id: json['id'],
        productoId: json['producto_id'],
        cantidadRequerida: json['cantidad_requerida'],
        precioPromocion: (json['precio_promocion'] as num).toDouble(),
      );
}
