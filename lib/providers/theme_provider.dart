import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/store_config.dart';
import 'auth_provider.dart';

/// Deriva StoreConfig del estado de auth (store.config JSON)
final storeConfigProvider = Provider<StoreConfig>((ref) {
  final store = ref.watch(authProvider).valueOrNull?.store;
  if (store == null) return StoreConfig.defaults;
  return StoreConfig.fromMap(store.config);
});

/// Símbolo de moneda para usar en toda la app
final monedaProvider = Provider<String>((ref) {
  return ref.watch(storeConfigProvider).moneda;
});

/// ThemeData completo derivado del config de la tienda
final themeProvider = Provider<ThemeData>((ref) {
  final config = ref.watch(storeConfigProvider);
  return _buildTheme(config);
});

ThemeData _buildTheme(StoreConfig config) {
  final colorScheme = ColorScheme.fromSeed(seedColor: config.colorPrimario);
  final base = ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: config.colorFondo,
    useMaterial3: true,
  );
  return _applyFont(config.fuente, base);
}

ThemeData _applyFont(String fuente, ThemeData base) {
  TextTheme applyTo(TextTheme t) {
    switch (fuente) {
      case 'Poppins':
        return GoogleFonts.poppinsTextTheme(t);
      case 'Inter':
        return GoogleFonts.interTextTheme(t);
      case 'Montserrat':
        return GoogleFonts.montserratTextTheme(t);
      case 'Lato':
        return GoogleFonts.latoTextTheme(t);
      case 'Nunito':
        return GoogleFonts.nunitoTextTheme(t);
      case 'Outfit':
        return GoogleFonts.outfitTextTheme(t);
      case 'DM Sans':
        return GoogleFonts.dmSansTextTheme(t);
      default:
        return t; // Roboto (default Material)
    }
  }

  return base.copyWith(textTheme: applyTo(base.textTheme));
}
