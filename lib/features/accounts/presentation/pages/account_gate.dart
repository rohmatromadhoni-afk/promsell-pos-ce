import 'package:flutter/material.dart';
import 'package:promsell_pos_ce/core/di/injection_container.dart';
import 'package:promsell_pos_ce/features/accounts/data/account_service.dart';
import 'package:promsell_pos_ce/features/accounts/domain/app_user.dart';
import 'package:promsell_pos_ce/features/accounts/presentation/pages/auth_pages.dart';

/// Shows the owner setup, login screen or the POS shell depending on accounts.
///
/// Flow: no accounts -> create owner -> signed in; accounts exist but nobody
/// signed in -> login; signed in -> [child].
class AccountGate extends StatefulWidget {
  const AccountGate({super.key, required this.child});

  final Widget child;

  @override
  State<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<AccountGate> {
  final AccountService? _accounts = sl.isRegistered<AccountService>()
      ? sl<AccountService>()
      : null;
  List<AppUser> _users = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final accounts = _accounts;
    if (accounts == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    List<AppUser> users = const [];
    try {
      users = await accounts.loadUsers();
    } catch (error) {
      debugPrint('AccountGate: cannot load users ($error)');
    }
    if (!mounted) return;
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _accounts;
    if (accounts == null) return widget.child;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ValueListenableBuilder<AppUser?>(
      valueListenable: accounts.currentUser,
      builder: (context, user, _) {
        if (_users.isEmpty) {
          return OwnerSetupPage(onDone: _reload);
        }
        if (user == null) {
          return LoginPage(users: _users);
        }
        return widget.child;
      },
    );
  }
}
