import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/reporte.dart';
import '../../providers/auth_provider.dart';
import '../../services/reporte_service.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late DateTime _inicio;
  late DateTime _fin;

  ResumenPeriodo? _resumen;
  List<VentaDia> _ventasPorDia = [];
  List<ProductoTop> _productosTop = [];
  List<ProductoStockBajo> _stockBajo = [];
  MapaVentas? _mapa;
  bool _cargando = false;

  final _fmt = DateFormat('dd/MM/yyyy');
  final _fmtMoney = NumberFormat('\$#,##0.00');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    final hoy = DateTime.now();
    _inicio = DateTime(hoy.year, hoy.month, 1);
    _fin = hoy;
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  ReporteService get _service => ReporteService(ref.read(apiClientProvider));

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        _service.getResumen(_inicio, _fin),
        _service.getVentasPorDia(_inicio, _fin),
        _service.getProductosTop(_inicio, _fin),
        _service.getStockBajo(),
        _service.getMapaVentas(_inicio, _fin),
      ]);
      if (mounted) {
        setState(() {
          _resumen = results[0] as ResumenPeriodo;
          _ventasPorDia = results[1] as List<VentaDia>;
          _productosTop = results[2] as List<ProductoTop>;
          _stockBajo = results[3] as List<ProductoStockBajo>;
          _mapa = results[4] as MapaVentas;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _pickFecha(bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: esInicio ? _inicio : _fin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (esInicio) {
        _inicio = picked;
        if (_inicio.isAfter(_fin)) _fin = _inicio;
      } else {
        _fin = picked;
        if (_fin.isBefore(_inicio)) _inicio = _fin;
      }
    });
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Por Día'),
            Tab(text: 'Productos'),
            Tab(text: 'Stock Bajo'),
            Tab(text: 'Mapa'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Selector de fechas ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text('Del ', style: TextStyle(fontWeight: FontWeight.w500)),
                _FechaBtn(label: _fmt.format(_inicio), onTap: () => _pickFecha(true)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('al'),
                ),
                _FechaBtn(label: _fmt.format(_fin), onTap: () => _pickFecha(false)),
                const Spacer(),
                if (_cargando)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _TabResumen(resumen: _resumen, fmtMoney: _fmtMoney),
                _TabPorDia(ventas: _ventasPorDia, fmtMoney: _fmtMoney, fmt: _fmt),
                _TabProductos(productos: _productosTop, fmtMoney: _fmtMoney),
                _TabStockBajo(items: _stockBajo),
                _TabMapa(mapa: _mapa, fmtMoney: _fmtMoney),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab Resumen ──────────────────────────────────────────────

class _TabResumen extends StatelessWidget {
  final ResumenPeriodo? resumen;
  final NumberFormat fmtMoney;
  const _TabResumen({required this.resumen, required this.fmtMoney});

  @override
  Widget build(BuildContext context) {
    if (resumen == null) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _StatCard(label: 'Ventas totales', value: '${resumen!.numVentas}',
              icon: Icons.receipt_long_outlined, color: Colors.blue),
          _StatCard(label: 'Total recaudado', value: fmtMoney.format(resumen!.total),
              icon: Icons.attach_money, color: Colors.green),
          _StatCard(label: 'Efectivo', value: fmtMoney.format(resumen!.efectivo),
              icon: Icons.payments_outlined, color: Colors.teal),
          _StatCard(label: 'Transferencia', value: fmtMoney.format(resumen!.transferencia),
              icon: Icons.phone_android_outlined, color: Colors.indigo),
          _StatCard(label: 'Inversión (restocks)', value: fmtMoney.format(resumen!.inversion),
              icon: Icons.shopping_cart_outlined, color: Colors.orange),
          _StatCard(label: 'Merma declarada', value: fmtMoney.format(resumen!.merma),
              icon: Icons.delete_outline, color: Colors.red.shade400),
          _StatCard(label: 'Ganancia neta', value: fmtMoney.format(resumen!.ganancia),
              icon: Icons.trending_up, color: resumen!.ganancia >= 0 ? Colors.green.shade700 : Colors.red),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Tab Por Día ──────────────────────────────────────────────

class _TabPorDia extends StatelessWidget {
  final List<VentaDia> ventas;
  final NumberFormat fmtMoney;
  final DateFormat fmt;
  const _TabPorDia({required this.ventas, required this.fmtMoney, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (ventas.isEmpty) return const Center(child: Text('Sin ventas en el período'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ventas.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final v = ventas[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: Text('${v.numVentas}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700, fontSize: 13)),
          ),
          title: Text(fmt.format(v.fecha), style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            'Efectivo ${fmtMoney.format(v.efectivo)}  ·  Transferencia ${fmtMoney.format(v.transferencia)}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(fmtMoney.format(v.total),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        );
      },
    );
  }
}

// ── Tab Productos ────────────────────────────────────────────

class _TabProductos extends StatelessWidget {
  final List<ProductoTop> productos;
  final NumberFormat fmtMoney;
  const _TabProductos({required this.productos, required this.fmtMoney});

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) return const Center(child: Text('Sin ventas en el período'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: productos.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = productos[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.shade50,
            child: Text('${i + 1}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
          ),
          title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${p.totalCantidad} unidades vendidas'),
          trailing: Text(fmtMoney.format(p.totalIngreso),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade700)),
        );
      },
    );
  }
}

// ── Tab Stock Bajo ───────────────────────────────────────────

class _TabStockBajo extends StatelessWidget {
  final List<ProductoStockBajo> items;
  const _TabStockBajo({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
            SizedBox(height: 12),
            Text('Todo el stock está bien'),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = items[i];
        final critico = p.stock == 0;
        return ListTile(
          leading: Icon(
            critico ? Icons.error_outline : Icons.warning_amber_outlined,
            color: critico ? Colors.red : Colors.orange,
          ),
          title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: p.categoria != null ? Text(p.categoria!) : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Stock: ${p.stock}',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: critico ? Colors.red : Colors.orange)),
              Text('Mínimo: ${p.stockMinimo}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}

// ── Tab Mapa ─────────────────────────────────────────────────

class _TabMapa extends StatelessWidget {
  final MapaVentas? mapa;
  final NumberFormat fmtMoney;

  static const double _colW = 90.0;
  static const double _labelW = 110.0;
  static const double _rowH = 52.0;
  static const double _headerH = 44.0;

  const _TabMapa({required this.mapa, required this.fmtMoney});

  Color _cellColor(double valor, double maxVal) {
    if (valor == 0 || maxVal == 0) return Colors.grey.shade100;
    final intensity = (valor / maxVal).clamp(0.0, 1.0);
    return Color.lerp(Colors.indigo.shade50, Colors.indigo.shade700, intensity)!;
  }

  Color _textColor(double valor, double maxVal) {
    if (valor == 0 || maxVal == 0) return Colors.grey.shade400;
    final intensity = (valor / maxVal).clamp(0.0, 1.0);
    return intensity > 0.5 ? Colors.white : Colors.indigo.shade900;
  }

  String _shortDate(String fechaStr) {
    final d = DateTime.parse(fechaStr);
    const dias = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'];
    return '${dias[d.weekday - 1]}\n${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    if (mapa == null) return const Center(child: CircularProgressIndicator());
    if (mapa!.fechas.isEmpty) return const Center(child: Text('Sin datos en el período'));

    final maxVal = mapa!.maxTotal;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Columna fija: etiquetas de franja horaria ─────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Celda vacía esquina
              SizedBox(height: _headerH),
              ...mapa!.slots.map((slot) => Container(
                    width: _labelW,
                    height: _rowH,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      slot.label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  )),
            ],
          ),
          // ── Columnas de datos: scroll horizontal ──────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: fechas
                  Row(
                    children: mapa!.fechas.map((f) => Container(
                          width: _colW,
                          height: _headerH,
                          alignment: Alignment.center,
                          child: Text(
                            _shortDate(f),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        )).toList(),
                  ),
                  // Filas de slots
                  ...mapa!.slots.map((slot) => Row(
                        children: List.generate(mapa!.fechas.length, (ci) {
                          final val = slot.totales[ci];
                          final bg = _cellColor(val, maxVal);
                          final fg = _textColor(val, maxVal);
                          return Container(
                            width: _colW,
                            height: _rowH,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: val == 0
                                ? const SizedBox()
                                : Text(
                                    fmtMoney.format(val),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: fg,
                                    ),
                                  ),
                          );
                        }),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón fecha ──────────────────────────────────────────────

class _FechaBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FechaBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
