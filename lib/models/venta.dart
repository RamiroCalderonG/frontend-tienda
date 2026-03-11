class VentaItem {
  final String id;
  final String? productoId;
  final String nombre;
  final double precio;
  final int cantidad;
  final double subtotal;

  const VentaItem({
    required this.id,
    this.productoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.subtotal,
  });

  factory VentaItem.fromJson(Map<String, dynamic> json) => VentaItem(
        id: json['id'],
        productoId: json['producto_id'],
        nombre: json['nombre'],
        precio: (json['precio'] as num).toDouble(),
        cantidad: json['cantidad'],
        subtotal: (json['subtotal'] as num).toDouble(),
      );
}

class Venta {
  final String id;
  final String storeId;
  final String userId;
  final double total;
  final String metodoPago;
  final DateTime createdAt;
  final List<VentaItem> items;

  const Venta({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.total,
    required this.metodoPago,
    required this.createdAt,
    required this.items,
  });

  factory Venta.fromJson(Map<String, dynamic> json) => Venta(
        id: json['id'],
        storeId: json['store_id'],
        userId: json['user_id'],
        total: (json['total'] as num).toDouble(),
        metodoPago: json['metodo_pago'],
        createdAt: DateTime.parse(json['created_at']),
        items: (json['items'] as List)
            .map((e) => VentaItem.fromJson(e))
            .toList(),
      );
}

// Representa un item en el ticket local (antes de confirmar venta)
class TicketItem {
  final String productoId;
  final String nombre;
  final double precio;
  int cantidad;

  TicketItem({
    required this.productoId,
    required this.nombre,
    required this.precio,
    this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;
}
