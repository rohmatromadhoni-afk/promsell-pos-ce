import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:promsell_pos_ce/core/services/pin_hasher.dart';
import 'package:promsell_pos_ce/features/accounts/domain/app_user.dart';
import 'package:promsell_pos_ce/features/settings/data/datasources/settings_local_datasource.dart';

/// Stores staff/owner accounts and keeps the logged-in user in memory.
///
/// Users live in `app_settings` as a JSON list (key `appUsers`), which keeps
/// the database schema untouched and makes accounts part of settings backups.
/// Only PIN hashes (PBKDF2, see [PinHasher]) are persisted.
@lazySingleton
class AccountService {
  AccountService(this._settings);

  final SettingsLocalDatasource _settings;
  static const _storageKey = 'appUsers';
  static const minPinLength = 4;
  static const maxPinLength = 6;

  final PinHasher _hasher = const PinHasher();

  /// Currently logged-in user. `null` means the login screen is shown.
  final ValueNotifier<AppUser?> currentUser = ValueNotifier<AppUser?>(null);

  AppUser? get user => currentUser.value;

  bool get hasSession => currentUser.value != null;

  bool get isOwner => currentUser.value?.isOwner ?? false;

  bool can(UserPermission permission) =>
      currentUser.value?.can(permission) ?? false;

  void logout() {
    currentUser.value = null;
  }

  Future<List<AppUser>> loadUsers() async {
    final raw = await _settings.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    final users = <AppUser>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['users'] is List) {
        for (final entry in decoded['users'] as List) {
          final user = AppUser.fromJson(entry);
          if (user != null) users.add(user);
        }
      }
    } catch (error) {
      debugPrint('AccountService: cannot read users ($error)');
      return const [];
    }

    users.sort((a, b) {
      if (a.isOwner != b.isOwner) return a.isOwner ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return users;
  }

  Future<bool> hasAnyUser() async => (await loadUsers()).isNotEmpty;

  Future<AppUser> createOwner({
    required String name,
    required String pin,
  }) async {
    final users = await loadUsers();
    if (users.any((u) => u.isOwner)) {
      throw StateError('An owner account already exists');
    }
    final owner = _buildUser(
      name: name,
      pin: pin,
      role: UserRole.owner,
      permissions: UserPermission.values.toSet(),
    );
    await _write([...users, owner]);
    return owner;
  }

  Future<AppUser> addStaff({
    required String name,
    required String pin,
    required Set<UserPermission> permissions,
  }) async {
    final users = await loadUsers();
    final staff = _buildUser(
      name: name,
      pin: pin,
      role: UserRole.staff,
      permissions: permissions,
    );
    await _write([...users, staff]);
    return staff;
  }

  Future<void> updateStaff(
    String userId, {
    String? name,
    Set<UserPermission>? permissions,
  }) async {
    final users = await loadUsers();
    final next = <AppUser>[];
    for (final user in users) {
      if (user.id != userId) {
        next.add(user);
        continue;
      }
      next.add(
        user.copyWith(
          name: _cleanName(name) ?? user.name,
          permissions: permissions ?? user.permissions,
        ),
      );
    }
    await _write(next);
  }

  Future<void> changePin(String userId, String newPin) async {
    _validatePin(newPin);
    final users = await loadUsers();
    final salt = _hasher.randomSalt();
    final hash = _hasher.hashV2(newPin, salt);
    final next = <AppUser>[];
    for (final user in users) {
      next.add(
        user.id == userId
            ? user.copyWith(salt: salt, pinHash: hash, scheme: PinHasher.schemeV2)
            : user,
      );
    }
    await _write(next);
  }

  /// Removes a staff account. The owner account can never be deleted and at
  /// least one owner always remains.
  Future<void> deleteUser(String userId) async {
    final users = await loadUsers();
    final target = users.where((u) => u.id == userId).toList();
    if (target.isEmpty || target.first.isOwner) return;
    final next = users.where((u) => u.id != userId).toList();
    if (!next.any((u) => u.isOwner)) return;
    await _write(next);
  }

  Future<bool> login(String userId, String pin) async {
    final users = await loadUsers();
    AppUser? match;
    for (final user in users) {
      if (user.id == userId) {
        match = user;
        break;
      }
    }
    if (match == null) return false;
    final ok = _hasher.verify(
      pin: pin.trim(),
      expectedHash: match.pinHash,
      salt: match.salt,
      scheme: match.scheme,
    );
    if (ok) currentUser.value = match;
    return ok;
  }

  /// Re-reads the current user after an edit so the session reflects changes.
  Future<void> refreshSession() async {
    final current = currentUser.value;
    if (current == null) return;
    final users = await loadUsers();
    for (final user in users) {
      if (user.id == current.id) {
        currentUser.value = user;
        return;
      }
    }
    currentUser.value = null;
  }

  static void _validatePin(String pin) {
    final trimmed = pin.trim();
    if (trimmed.length < minPinLength || trimmed.length > maxPinLength) {
      throw ArgumentError('PIN must be $minPinLength-$maxPinLength digits');
    }
    if (int.tryParse(trimmed) == null) {
      throw ArgumentError('PIN must contain digits only');
    }
  }

  static String? _cleanName(String? name) {
    final trimmed = name?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  AppUser _buildUser({
    required String name,
    required String pin,
    required UserRole role,
    required Set<UserPermission> permissions,
  }) {
    final cleanName = _cleanName(name);
    if (cleanName == null) throw ArgumentError('Name is required');
    _validatePin(pin);
    final salt = _hasher.randomSalt();
    final trimmedPin = pin.trim();
    return AppUser(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      name: cleanName,
      role: role,
      salt: salt,
      pinHash: _hasher.hashV2(trimmedPin, salt),
      scheme: PinHasher.schemeV2,
      permissions: permissions,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _write(List<AppUser> users) async {
    final payload = jsonEncode({
      'version': 1,
      'users': users.map((u) => u.toJson()).toList(),
    });
    await _settings.setString(_storageKey, payload);
    await refreshSession();
  }
}
