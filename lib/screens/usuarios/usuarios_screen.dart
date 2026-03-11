import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/users_provider.dart';

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final me = ref.watch(authProvider).valueOrNull?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, ref, me: me),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nuevo usuario'),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) => users.isEmpty
            ? const Center(child: Text('No hay usuarios'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _UserTile(
                  user: users[i],
                  isMe: users[i].id == me?.id,
                  onEdit: () => _showDialog(context, ref, user: users[i], me: me),
                  onDelete: () => _confirmDelete(context, ref, users[i], me),
                ),
              ),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, {User? user, User? me}) {
    showDialog(
      context: context,
      builder: (_) => _UserDialog(user: user, me: me, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, User user, User? me) {
    if (user.id == me?.id) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar a ${user.name}? Esta acción no se puede deshacer.'),
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
                await ref.read(usersProvider.notifier).eliminar(user.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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

// ── Tile de usuario ──────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final User user;
  final bool isMe;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserTile({
    required this.user,
    required this.isMe,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    final isAdmin = user.isAdmin;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isAdmin
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary,
        child: Text(
          initials,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Row(
        children: [
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (isMe) ...[
            const SizedBox(width: 6),
            const Text('(tú)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ],
      ),
      subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chip rol
          _RolChip(role: user.role),
          const SizedBox(width: 4),
          // Chip activo/inactivo
          if (!user.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text('Inactivo',
                  style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            tooltip: 'Editar',
          ),
          if (!isMe)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Eliminar',
            ),
        ],
      ),
    );
  }
}

class _RolChip extends StatelessWidget {
  final String role;
  const _RolChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Cajero',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isAdmin
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade700,
        ),
      ),
    );
  }
}

// ── Dialog crear/editar usuario ──────────────────────────────

class _UserDialog extends StatefulWidget {
  final User? user;
  final User? me;
  final WidgetRef ref;

  const _UserDialog({this.user, this.me, required this.ref});

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final TextEditingController _password = TextEditingController();
  late String _role;
  late bool _isActive;
  bool _guardando = false;
  bool _showPassword = false;

  bool get _esEdicion => widget.user != null;
  bool get _esYoMismo => widget.user?.id == widget.me?.id;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user?.name ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
    _role = widget.user?.role ?? 'cashier';
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      if (_esEdicion) {
        final campos = <String, dynamic>{};
        if (_name.text != widget.user!.name) campos['name'] = _name.text;
        if (_email.text != widget.user!.email) campos['email'] = _email.text;
        if (_password.text.isNotEmpty) campos['password'] = _password.text;
        if (!_esYoMismo && _role != widget.user!.role) campos['role'] = _role;
        if (!_esYoMismo && _isActive != widget.user!.isActive) campos['is_active'] = _isActive;

        if (campos.isNotEmpty) {
          await widget.ref.read(usersProvider.notifier).actualizar(widget.user!.id, campos);
        }
      } else {
        await widget.ref.read(usersProvider.notifier).crear(
              name: _name.text,
              email: _email.text,
              password: _password.text,
              role: _role,
            );
      }
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
      title: Text(_esEdicion ? 'Editar usuario' : 'Nuevo usuario'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(
                  labelText: _esEdicion ? 'Nueva contraseña (dejar vacío para no cambiar)' : 'Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                obscureText: !_showPassword,
                validator: (v) {
                  if (!_esEdicion && (v == null || v.isEmpty)) return 'Requerido';
                  if (v != null && v.isNotEmpty && v.length < 4) return 'Mínimo 4 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Rol (no editable si es uno mismo)
              if (!_esYoMismo) ...[
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'cashier', child: Text('Cajero')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const SizedBox(height: 12),
              ],
              // Activo/Inactivo (solo en edición, no si es uno mismo)
              if (_esEdicion && !_esYoMismo)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Usuario activo'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
            ],
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
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
