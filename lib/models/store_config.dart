import 'package:flutter/material.dart';

class StoreConfig {
  final Color colorPrimario;
  final Color colorFondo;
  final String fuente;
  final String moneda;
  final String nombreTicket;

  const StoreConfig({
    required this.colorPrimario,
    required this.colorFondo,
    required this.fuente,
    required this.moneda,
    required this.nombreTicket,
  });

  static const StoreConfig defaults = StoreConfig(
    colorPrimario: Color(0xFF3F51B5), // Indigo
    colorFondo: Color(0xFFF5F5F5),
    fuente: 'Roboto',
    moneda: '\$',
    nombreTicket: '',
  );

  static Color _hexToColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final h = hex.replaceAll('#', '').padLeft(6, '0');
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  factory StoreConfig.fromMap(Map<String, dynamic> map) => StoreConfig(
        colorPrimario: _hexToColor(
          map['color_primario'] as String?,
          StoreConfig.defaults.colorPrimario,
        ),
        colorFondo: _hexToColor(
          map['color_fondo'] as String?,
          StoreConfig.defaults.colorFondo,
        ),
        fuente: (map['fuente'] as String?) ?? 'Roboto',
        moneda: (map['moneda'] as String?) ?? '\$',
        nombreTicket: (map['nombre_ticket'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
        'color_primario': _colorToHex(colorPrimario),
        'color_fondo': _colorToHex(colorFondo),
        'fuente': fuente,
        'moneda': moneda,
        'nombre_ticket': nombreTicket,
      };

  static String _colorToHex(Color c) =>
      c.value.toRadixString(16).substring(2).toUpperCase();

  StoreConfig copyWith({
    Color? colorPrimario,
    Color? colorFondo,
    String? fuente,
    String? moneda,
    String? nombreTicket,
  }) =>
      StoreConfig(
        colorPrimario: colorPrimario ?? this.colorPrimario,
        colorFondo: colorFondo ?? this.colorFondo,
        fuente: fuente ?? this.fuente,
        moneda: moneda ?? this.moneda,
        nombreTicket: nombreTicket ?? this.nombreTicket,
      );
}
