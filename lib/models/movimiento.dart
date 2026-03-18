class Movimiento {
  final String id;
  final String? productoId;
  final String nombreProducto;
  final int cantidad;
  final int stockAntes;
  final int stockDespues;
  final double? costoUnitario;
  final String? tipo;
  final String? fechaCaducidad;
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
    this.fechaCaducidad,
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
        fechaCaducidad: j['fecha_caducidad'],
        notas: j['notas'],
        userName: j['user_name'],
        createdAt: DateTime.parse(j['created_at']),
      );
}

class LoteVencimiento {
  final String movimientoId;
  final String? productoId;
  final String nombreProducto;
  final int cantidad;
  final String fechaCaducidad;
  final int diasRestantes;

  const LoteVencimiento({
    required this.movimientoId,
    this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.fechaCaducidad,
    required this.diasRestantes,
  });

  factory LoteVencimiento.fromJson(Map<String, dynamic> j) => LoteVencimiento(
        movimientoId: j['movimiento_id'],
        productoId: j['producto_id'],
        nombreProducto: j['nombre_producto'],
        cantidad: j['cantidad'],
        fechaCaducidad: j['fecha_caducidad'],
        diasRestantes: j['dias_restantes'],
      );
}
