import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tienda.dart';
import '../../providers/tiendas_provider.dart';

class TiendasScreen extends ConsumerWidget {
  const TiendasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiendasAsync = ref.watch(tiendasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tiendas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCrearDialog(context, ref),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nueva tienda'),
      ),
      body: tiendasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tiendas) => tiendas.isEmpty
            ? const Center(child: Text('No hay tiendas registradas'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: tiendas.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _TiendaTile(
                  tienda: tiendas[i],
                  onDelete: () => _confirmDelete(context, ref, tiendas[i]),
                ),
              ),
      ),
    );
  }

  void _showCrearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _CrearTiendaDialog(ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Tienda tienda) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tienda'),
        content: Text(
            '¿Eliminar "${tienda.name}"? Se eliminarán todos sus datos. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(tiendasProvider.notifier).eliminar(tienda.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── Tile de tienda ────────────────────────────────────────────

class _TiendaTile extends StatelessWidget {
  final Tienda tienda;
  final VoidCallback onDelete;

  const _TiendaTile({required this.tienda, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final initials = tienda.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          initials,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(tienda.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        tienda.address?.isNotEmpty == true ? tienda.address! : 'Sin dirección',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chip de usuarios
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline,
                    size: 13,
                    color: Theme.of(context).colorScheme.onSecondaryContainer),
                const SizedBox(width: 4),
                Text(
                  '${tienda.userCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon:
                const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: onDelete,
            tooltip: 'Eliminar tienda',
          ),
        ],
      ),
    );
  }
}

// ── Dialog crear tienda ───────────────────────────────────────

class _CrearTiendaDialog extends StatefulWidget {
  final WidgetRef ref;
  const _CrearTiendaDialog({required this.ref});

  @override
  State<_CrearTiendaDialog> createState() => _CrearTiendaDialogState();
}

class _CrearTiendaDialogState extends State<_CrearTiendaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _storeName = TextEditingController();
  final _storeAddress = TextEditingController();
  final _adminName = TextEditingController();
  final _adminEmail = TextEditingController();
  final _adminPassword = TextEditingController();
  bool _guardando = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _storeName.dispose();
    _storeAddress.dispose();
    _adminName.dispose();
    _adminEmail.dispose();
    _adminPassword.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await widget.ref.read(tiendasProvider.notifier).crear(
            storeName: _storeName.text.trim(),
            storeAddress: _storeAddress.text.trim(),
            adminName: _adminName.text.trim(),
            adminEmail: _adminEmail.text.trim(),
            adminPassword: _adminPassword.text,
          );
      if (mounted) Navigator.pop(context);
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
    return AlertDialog(
      title: const Text('Nueva tienda'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Datos de la tienda ──
                Text('Tienda',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _storeName,
                  decoration:
                      const InputDecoration(labelText: 'Nombre de la tienda'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _storeAddress,
                  decoration: const InputDecoration(
                      labelText: 'Dirección (opcional)'),
                ),
                const SizedBox(height: 20),
                // ── Datos del admin ──
                Text('Administrador inicial',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _adminName,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _adminEmail,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _adminPassword,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (v.length < 4) return 'Mínimo 4 caracteres';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Crear tienda'),
        ),
      ],
    );
  }
}
