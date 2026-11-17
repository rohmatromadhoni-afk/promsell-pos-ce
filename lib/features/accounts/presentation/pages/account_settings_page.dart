import 'package:flutter/material.dart';
import 'package:promsell_pos_ce/core/di/injection_container.dart';
import 'package:promsell_pos_ce/features/accounts/data/account_service.dart';
import 'package:promsell_pos_ce/features/accounts/domain/app_user.dart';
import 'package:promsell_pos_ce/features/accounts/presentation/account_text.dart';

/// Settings entry point for account information, staff management and logout.
class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AccountText.of(context);
    final accounts = sl<AccountService>();

    return ValueListenableBuilder<AppUser?>(
      valueListenable: accounts.currentUser,
      builder: (context, user, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(t.t('Account & staff', 'Akun & Pegawai')),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (user != null)
                ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.name.isEmpty
                          ? '?'
                          : user.name.substring(0, 1).toUpperCase(),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Text(
                    user.isOwner
                        ? t.t('Owner - full access', 'Owner - akses penuh')
                        : t.t('Staff', 'Pegawai'),
                  ),
                ),
              if (user?.isOwner ?? false)
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: Text(t.t('Manage staff', 'Kelola pegawai')),
                  subtitle: Text(
                    t.t(
                      'Add, edit access, or remove staff',
                      'Tambah, ubah akses, atau hapus pegawai',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmployeesPage(),
                    ),
                  ),
                ),
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.password),
                  title: Text(t.t('Change my PIN', 'Ubah PIN saya')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _changeOwnPin(context, t, user),
                ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  t.t('Sign out', 'Keluar'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () => _logout(context, t),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Text(
                  t.t(
                    'PIN is asked only once when the app starts. Staff see only the menus allowed by the owner.',
                    'PIN hanya diminta sekali saat aplikasi dibuka. Pegawai hanya melihat menu yang diizinkan owner.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeOwnPin(
    BuildContext context,
    AccountText t,
    AppUser user,
  ) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePinDialog(user: user),
    );
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.t('PIN updated', 'PIN berhasil diubah'))),
      );
    }
  }

  Future<void> _logout(BuildContext context, AccountText t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.t('Sign out?', 'Keluar?')),
        content: Text(
          t.t(
            'The next user must enter a PIN to open the app.',
            'Pengguna berikutnya harus memasukkan PIN untuk membuka aplikasi.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.t('Cancel', 'Batal')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.t('Sign out', 'Keluar')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    sl<AccountService>().logout();
  }
}

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  List<AppUser> _users = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final users = await sl<AccountService>().loadUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _openEditor([AppUser? existing]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EmployeeEditor(existing: existing),
    );
    if (saved == true) await _reload();
  }

  Future<void> _delete(AppUser user) async {
    final t = AccountText.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.t('Remove staff?', 'Hapus pegawai?')),
        content: Text(
          t.t(
            '${user.name} will no longer be able to sign in.',
            '${user.name} tidak bisa masuk lagi.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.t('Cancel', 'Batal')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.t('Remove', 'Hapus')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await sl<AccountService>().deleteUser(user.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = AccountText.of(context);
    final isOwner = sl<AccountService>().isOwner;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('Staff', 'Pegawai'))),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: _openEditor,
              icon: const Icon(Icons.person_add_alt),
              label: Text(t.t('Add staff', 'Tambah pegawai')),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.name.isEmpty
                          ? '?'
                          : user.name.substring(0, 1).toUpperCase(),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Text(_summary(t, user)),
                  trailing: user.isOwner
                      ? Chip(
                          label: Text(t.t('Owner', 'Owner')),
                          visualDensity: VisualDensity.compact,
                        )
                      : IconButton(
                          tooltip: t.t('Remove', 'Hapus'),
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(user),
                        ),
                  onTap: user.isOwner ? null : () => _openEditor(user),
                );
              },
            ),
    );
  }

  String _summary(AccountText t, AppUser user) {
    if (user.isOwner) {
      return t.t('Full access', 'Akses penuh');
    }
    if (user.permissions.isEmpty) {
      return t.t('Sell only', 'Hanya jual');
    }
    final labels = user.permissions.map((p) => _permissionLabel(t, p)).toList()
      ..sort();
    return labels.join(', ');
  }
}

String _permissionLabel(AccountText t, UserPermission permission) {
  switch (permission) {
    case UserPermission.settings:
      return t.t('Settings', 'Pengaturan');
    case UserPermission.voidSale:
      return t.t('Void', 'Void');
    case UserPermission.editProducts:
      return t.t('Products', 'Produk');
    case UserPermission.editStock:
      return t.t('Stock', 'Stok');
    case UserPermission.editPrice:
      return t.t('Price', 'Harga');
    case UserPermission.viewReports:
      return t.t('Reports', 'Laporan');
    case UserPermission.dailyClose:
      return t.t('Cash session', 'Kas');
    case UserPermission.customers:
      return t.t('Customers', 'Pelanggan');
  }
}

const _staffPermissions = <UserPermission>[
  UserPermission.voidSale,
  UserPermission.editProducts,
  UserPermission.editStock,
  UserPermission.editPrice,
  UserPermission.viewReports,
  UserPermission.dailyClose,
  UserPermission.customers,
];

class _EmployeeEditor extends StatefulWidget {
  const _EmployeeEditor({this.existing});

  final AppUser? existing;

  @override
  State<_EmployeeEditor> createState() => _EmployeeEditorState();
}

class _EmployeeEditorState extends State<_EmployeeEditor> {
  late final TextEditingController _nameController;
  final _pinController = TextEditingController();
  late Set<UserPermission> _permissions;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _permissions = {...?widget.existing?.permissions};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AccountText.of(context);
    final accounts = sl<AccountService>();
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final isNew = widget.existing == null;

    if (name.isEmpty) {
      setState(() => _error = t.t('Name is required', 'Nama wajib diisi'));
      return;
    }
    if (isNew || pin.isNotEmpty) {
      if (pin.length < AccountService.minPinLength ||
          pin.length > AccountService.maxPinLength ||
          int.tryParse(pin) == null) {
        setState(
          () => _error = t.t('PIN must be 4-6 digits', 'PIN harus 4-6 angka'),
        );
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (isNew) {
        await accounts.addStaff(
          name: name,
          pin: pin,
          permissions: _permissions,
        );
      } else {
        await accounts.updateStaff(
          widget.existing!.id,
          name: name,
          permissions: _permissions,
        );
        if (pin.isNotEmpty) {
          await accounts.changePin(widget.existing!.id, pin);
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('EmployeeEditor: $error');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = t.t('Could not save', 'Gagal menyimpan');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AccountText.of(context);
    final theme = Theme.of(context);
    final isNew = widget.existing == null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isNew
                  ? t.t('Add staff', 'Tambah pegawai')
                  : t.t('Edit staff', 'Ubah pegawai'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: t.t('Name', 'Nama'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: AccountService.maxPinLength,
              decoration: InputDecoration(
                labelText: isNew
                    ? t.t('PIN (4-6 digits)', 'PIN (4-6 angka)')
                    : t.t('New PIN (blank = keep)', 'PIN baru (kosong = tetap)'),
                border: const OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.t('Allowed access', 'Akses yang diizinkan'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.t(
                'Selling is always allowed. Settings stay owner-only.',
                'Menjual selalu boleh. Pengaturan hanya untuk owner.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final permission in _staffPermissions)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(_permissionLabel(t, permission)),
                value: _permissions.contains(permission),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _permissions.add(permission);
                    } else {
                      _permissions.remove(permission);
                    }
                  });
                },
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.t('Save', 'Simpan')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePinDialog extends StatefulWidget {
  const _ChangePinDialog({required this.user});

  final AppUser user;

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AccountText.of(context);
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();
    if (pin.length < AccountService.minPinLength ||
        pin.length > AccountService.maxPinLength ||
        int.tryParse(pin) == null) {
      setState(() => _error = t.t('PIN must be 4-6 digits', 'PIN harus 4-6 angka'));
      return;
    }
    if (pin != confirm) {
      setState(() => _error = t.t('PIN does not match', 'PIN tidak sama'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await sl<AccountService>().changePin(widget.user.id, pin);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('ChangePinDialog: $error');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = t.t('Could not save', 'Gagal menyimpan');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AccountText.of(context);
    return AlertDialog(
      title: Text(t.t('Change PIN', 'Ubah PIN')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: AccountService.maxPinLength,
            decoration: InputDecoration(
              labelText: t.t('New PIN', 'PIN baru'),
              counterText: '',
            ),
          ),
          TextField(
            controller: _confirmController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: AccountService.maxPinLength,
            decoration: InputDecoration(
              labelText: t.t('Repeat new PIN', 'Ulangi PIN baru'),
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(t.t('Cancel', 'Batal')),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(t.t('Save', 'Simpan')),
        ),
      ],
    );
  }
}
