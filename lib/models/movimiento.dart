class Movimiento {
  final String id;
  final String? productoId;
  final String nombreProducto;
  final int cantidad;
  final int stockAntes;
  final int stockDespues;
  final double? costoUnitario;
  final String? tipo;
  final String? notas;
  final String userName;
  final DateTime createdAt;

  const Movimiento({
    required this.id,
    this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.stockAntes,
    required this.stockDespues,
    this.costoUnitario,
    this.tipo,
    this.notas,
    required this.userName,
    required this.createdAt,
  });

  factory Movimiento.fromJson(Map<String, dynamic> j) => Movimiento(
        id: j['id'],
        productoId: j['producto_id'],
        nombreProducto: j['nombre_producto'],
        cantidad: j['cantidad'],
        stockAntes: j['stock_antes'],
        stockDespues: j['stock_despues'],
        costoUnitario: (j['costo_unitario'] as num?)?.toDouble(),
        tipo: j['tipo'],
        notas: j['notas'],
        userName: j['user_name'],
        createdAt: DateTime.parse(j['created_at']),
      );
}
