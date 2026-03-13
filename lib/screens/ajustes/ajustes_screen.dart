import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/store_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/store_service.dart';

// ── Paleta de colores primarios ───────────────────────────────
const _coloresPrimarios = [
  Color(0xFF3F51B5), // Indigo
  Color(0xFF673AB7), // Deep Purple
  Color(0xFF9C27B0), // Purple
  Color(0xFFE91E63), // Pink
  Color(0xFFF44336), // Red
  Color(0xFFFF5722), // Deep Orange
  Color(0xFFFF9800), // Orange
  Color(0xFF4CAF50), // Green
  Color(0xFF009688), // Teal
  Color(0xFF00BCD4), // Cyan
  Color(0xFF2196F3), // Blue
  Color(0xFF607D8B), // Blue Grey
];

// ── Paleta de fondos ─────────────────────────────────────────
const _coloresFondo = [
  Color(0xFFFFFFFF), // Blanco
  Color(0xFFF5F5F5), // Gris claro
  Color(0xFFEEEEEE), // Gris
  Color(0xFFFFF8F0), // Blanco cálido
  Color(0xFFE8F5FF), // Azul claro
  Color(0xFFF0FFF4), // Verde claro
  Color(0xFFF3E5F5), // Lila claro
  Color(0xFF1C1B1F), // Oscuro
];

// ── Fuentes disponibles ───────────────────────────────────────
const _fuentes = [
  'Roboto',
  'Poppins',
  'Inter',
  'Montserrat',
  'Lato',
  'Nunito',
  'Outfit',
  'DM Sans',
];

class AjustesScreen extends ConsumerStatefulWidget {
  const AjustesScreen({super.key});

  @override
  ConsumerState<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends ConsumerState<AjustesScreen> {
  late StoreConfig _config;
  late TextEditingController _monedaCtrl;
  late TextEditingController _nombreTicketCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _config = ref.read(storeConfigProvider);
    _monedaCtrl = TextEditingController(text: _config.moneda);
    _nombreTicketCtrl = TextEditingController(text: _config.nombreTicket);
  }

  @override
  void dispose() {
    _monedaCtrl.dispose();
    _nombreTicketCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final finalConfig = _config.copyWith(
        moneda: _monedaCtrl.text.trim().isEmpty ? '\$' : _monedaCtrl.text.trim(),
        nombreTicket: _nombreTicketCtrl.text.trim(),
      );
      final service = StoreService(ref.read(apiClientProvider));
      final store = await service.updateConfig(finalConfig);
      ref.read(authProvider.notifier).updateStore(store);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajustes guardados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de la tienda'),
        actions: [
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Guardar'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Color primario ──────────────────────────────
            _SectionTitle(icon: Icons.palette_outlined, label: 'Color primario'),
            const SizedBox(height: 12),
            _ColorPalette(
              colors: _coloresPrimarios,
              selected: _config.colorPrimario,
              onSelected: (c) => setState(() => _config = _config.copyWith(colorPrimario: c)),
            ),
            const SizedBox(height: 28),

            // ── Color de fondo ──────────────────────────────
            _SectionTitle(icon: Icons.format_color_fill_outlined, label: 'Color de fondo'),
            const SizedBox(height: 12),
            _ColorPalette(
              colors: _coloresFondo,
              selected: _config.colorFondo,
              onSelected: (c) => setState(() => _config = _config.copyWith(colorFondo: c)),
              size: 48,
            ),
            const SizedBox(height: 28),

            // ── Tipografía ──────────────────────────────────
            _SectionTitle(icon: Icons.text_fields_outlined, label: 'Tipografía'),
            const SizedBox(height: 12),
            _FontSelector(
              fonts: _fuentes,
              selected: _config.fuente,
              onSelected: (f) => setState(() => _config = _config.copyWith(fuente: f)),
            ),
            const SizedBox(height: 28),

            // ── Moneda y nombre ─────────────────────────────
            _SectionTitle(icon: Icons.settings_outlined, label: 'General'),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _monedaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Moneda',
                      hintText: '\$, €, Q',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 3,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _nombreTicketCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre en ticket',
                      hintText: 'Ej: Panadería Luna',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // ── Preview ─────────────────────────────────────
            _SectionTitle(icon: Icons.preview_outlined, label: 'Vista previa'),
            const SizedBox(height: 12),
            _ThemePreview(config: _config),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              )),
        ],
      );
}

class _ColorPalette extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;
  final double size;

  const _ColorPalette({
    required this.colors,
    required this.selected,
    required this.onSelected,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((c) {
        final isSelected = c.value == selected.value;
        return GestureDetector(
          onTap: () => onSelected(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: c.withOpacity(isSelected ? 0.6 : 0.25),
                  blurRadius: isSelected ? 8 : 3,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: isSelected
                ? Icon(Icons.check,
                    color: _contrastColor(c), size: size * 0.5)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.4 ? Colors.black87 : Colors.white;
  }
}

class _FontSelector extends StatelessWidget {
  final List<String> fonts;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FontSelector({
    required this.fonts,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: fonts.map((f) {
        final isSelected = f == selected;
        return ChoiceChip(
          label: Text(f),
          selected: isSelected,
          onSelected: (_) => onSelected(f),
        );
      }).toList(),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final StoreConfig config;
  const _ThemePreview({required this.config});

  @override
  Widget build(BuildContext context) {
    final cs = ColorScheme.fromSeed(seedColor: config.colorPrimario);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: config.colorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simula AppBar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.store, color: cs.onPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  config.nombreTicket.isEmpty ? 'Mi Tienda' : config.nombreTicket,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Simula contenido
          Text('Producto ejemplo',
              style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 4),
          Text('${config.moneda}150.00',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          // Simula botón
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              child: const Text('Agregar al ticket'),
            ),
          ),
        ],
      ),
    );
  }
}
