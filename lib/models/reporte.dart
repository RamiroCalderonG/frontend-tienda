class ResumenPeriodo {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int numVentas;
  final double total;
  final double efectivo;
  final double transferencia;
  final double costoVentas;
  final double ganancia;
  final double inversion;

  const ResumenPeriodo({
    required this.fechaInicio,
    required this.fechaFin,
    required this.numVentas,
    required this.total,
    required this.efectivo,
    required this.transferencia,
    required this.costoVentas,
    required this.ganancia,
    required this.inversion,
  });

  factory ResumenPeriodo.fromJson(Map<String, dynamic> j) => ResumenPeriodo(
        fechaInicio: DateTime.parse(j['fecha_inicio']),
        fechaFin: DateTime.parse(j['fecha_fin']),
        numVentas: j['num_ventas'],
        total: (j['total'] as num).toDouble(),
        efectivo: (j['efectivo'] as num).toDouble(),
        transferencia: (j['transferencia'] as num).toDouble(),
        costoVentas: (j['costo_ventas'] as num).toDouble(),
        ganancia: (j['ganancia'] as num).toDouble(),
        inversion: (j['inversion'] as num).toDouble(),
      );
}

class VentaDia {
  final DateTime fecha;
  final int numVentas;
  final double total;
  final double efectivo;
  final double transferencia;

  const VentaDia({
    required this.fecha,
    required this.numVentas,
    required this.total,
    required this.efectivo,
    required this.transferencia,
  });

  factory VentaDia.fromJson(Map<String, dynamic> j) => VentaDia(
        fecha: DateTime.parse(j['fecha']),
        numVentas: j['num_ventas'],
        total: (j['total'] as num).toDouble(),
        efectivo: (j['efectivo'] as num).toDouble(),
        transferencia: (j['transferencia'] as num).toDouble(),
      );
}

class ProductoTop {
  final String nombre;
  final int totalCantidad;
  final double totalIngreso;

  const ProductoTop({
    required this.nombre,
    required this.totalCantidad,
    required this.totalIngreso,
  });

  factory ProductoTop.fromJson(Map<String, dynamic> j) => ProductoTop(
        nombre: j['nombre'],
        totalCantidad: j['total_cantidad'],
        totalIngreso: (j['total_ingreso'] as num).toDouble(),
      );
}

class ProductoStockBajo {
  final String id;
  final String nombre;
  final int stock;
  final int stockMinimo;
  final String? categoria;

  const ProductoStockBajo({
    required this.id,
    required this.nombre,
    required this.stock,
    required this.stockMinimo,
    this.categoria,
  });

  factory ProductoStockBajo.fromJson(Map<String, dynamic> j) => ProductoStockBajo(
        id: j['id'],
        nombre: j['nombre'],
        stock: j['stock'],
        stockMinimo: j['stock_minimo'],
        categoria: j['categoria'],
      );
}

class SlotVenta {
  final String label;
  final List<double> totales;

  const SlotVenta({required this.label, required this.totales});

  factory SlotVenta.fromJson(Map<String, dynamic> j) => SlotVenta(
        label: j['label'],
        totales: (j['totales'] as List).map((e) => (e as num).toDouble()).toList(),
      );
}

class MapaVentas {
  final List<String> fechas;
  final List<SlotVenta> slots;

  const MapaVentas({required this.fechas, required this.slots});

  double get maxTotal => slots
      .expand((s) => s.totales)
      .fold(0.0, (m, v) => v > m ? v : m);

  factory MapaVentas.fromJson(Map<String, dynamic> j) => MapaVentas(
        fechas: List<String>.from(j['fechas']),
        slots: (j['slots'] as List).map((e) => SlotVenta.fromJson(e)).toList(),
      );
}
