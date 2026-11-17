import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:promsell_pos_ce/core/di/injection_container.dart';
import 'package:promsell_pos_ce/core/services/app_lock_service.dart';
import 'package:promsell_pos_ce/features/accounts/data/account_service.dart';
import 'package:promsell_pos_ce/features/accounts/domain/app_user.dart';
import 'package:promsell_pos_ce/features/accounts/presentation/account_text.dart';

/// First-run screen: creates the single owner account.
class OwnerSetupPage extends StatefulWidget {
  const OwnerSetupPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OwnerSetupPage> createState() => _OwnerSetupPageState();
}

class _OwnerSetupPageState extends State<OwnerSetupPage> {
  final _nameController = TextEditingController(text: 'Owner');
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AccountText.of(context);
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = t.t('Name is required', 'Nama wajib diisi'));
      return;
    }
    if (pin.length < AccountService.minPinLength ||
        pin.length > AccountService.maxPinLength ||
        int.tryParse(pin) == null) {
      setState(
        () => _error = t.t(
          'PIN must be 4-6 digits',
          'PIN harus 4-6 angka',
        ),
      );
      return;
    }
    if (pin != confirm) {
      setState(
        () => _error = t.t('PIN does not match', 'PIN tidak sama'),
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final accounts = sl<AccountService>();
    try {
      final owner = await accounts.createOwner(name: name, pin: pin);
      await accounts.login(owner.id, pin);
      await _disableLegacyAppLock();
      widget.onDone();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = t.t(
          'Could not create the account. Try again.',
          'Gagal membuat akun. Coba lagi.',
        );
      });
      debugPrint('OwnerSetupPage: $error');
    }
  }

  /// The old per-access PIN becomes redundant once accounts exist.
  Future<void> _disableLegacyAppLock() async {
    try {
      if (sl.isRegistered<AppLockService>()) {
        await sl<AppLockService>().disable();
      }
    } catch (error) {
      debugPrint('OwnerSetupPage: disable app lock failed ($error)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AccountText.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.storefront,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.t('Create owner account', 'Buat akun owner'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.t(
                      'This account has full access, including settings and staff management.',
                      'Akun ini punya akses penuh, termasuk pengaturan dan kelola pegawai.',
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: t.t('Owner name', 'Nama owner'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PinField(
                    controller: _pinController,
                    label: t.t('PIN (4-6 digits)', 'PIN (4-6 angka)'),
                  ),
                  const SizedBox(height: 12),
                  _PinField(
                    controller: _confirmController,
                    label: t.t('Repeat PIN', 'Ulangi PIN'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.t('Create account', 'Buat akun')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// PIN entry screen shown at app start.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.users});

  final List<AppUser> users;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late String _selectedId;
  final _pinController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.users.isEmpty ? '' : widget.users.first.id;
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AccountText.of(context);
    final pin = _pinController.text.trim();
    if (pin.length < AccountService.minPinLength) {
      setState(() => _error = t.t('Enter your PIN', 'Masukkan PIN Anda'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await sl<AccountService>().login(_selectedId, pin);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = t.t('Wrong PIN', 'PIN salah');
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AccountText.of(context);
    final theme = Theme.of(context);
    final users = widget.users;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.point_of_sale,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.t('Sign in', 'Masuk'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.t(
                      'Choose an account, then enter its PIN.',
                      'Pilih akun, lalu masukkan PIN-nya.',
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (users.length > 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final user in users)
                          ChoiceChip(
                            label: Text(
                              user.isOwner
                                  ? '${user.name} (${t.t('owner', 'owner')})'
                                  : user.name,
                            ),
                            selected: _selectedId == user.id,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedId = user.id;
                                _error = null;
                                _pinController.clear();
                              });
                            },
                          ),
                      ],
                    )
                  else if (users.isNotEmpty)
                    Text(
                      users.first.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 16),
                  _PinField(
                    controller: _pinController,
                    label: t.t('PIN', 'PIN'),
                    autofocus: true,
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.t('Sign in', 'Masuk')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: AccountService.maxPinLength,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
    );
  }
}
