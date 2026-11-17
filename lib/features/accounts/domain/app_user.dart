/// Local user account for the Barokah Karangsari POS.
///
/// Accounts are stored as JSON inside `app_settings` under the key `appUsers`
/// (see [AccountService]). No database migration is needed and the data is
/// included in the normal settings backup.
library;

enum UserRole { owner, staff }

/// Fine-grained access flags for staff accounts.
///
/// [settings] is intentionally owner-only and never offered to staff.
enum UserPermission {
  settings,
  voidSale,
  editProducts,
  editStock,
  editPrice,
  viewReports,
  dailyClose,
  customers,
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.salt,
    required this.pinHash,
    required this.scheme,
    required this.permissions,
    this.createdAtMs = 0,
  });

  final String id;
  final String name;
  final UserRole role;
  final String salt;
  final String pinHash;
  final String scheme;
  final Set<UserPermission> permissions;
  final int createdAtMs;

  bool get isOwner => role == UserRole.owner;

  bool can(UserPermission permission) =>
      isOwner || permissions.contains(permission);

  AppUser copyWith({
    String? name,
    String? salt,
    String? pinHash,
    String? scheme,
    Set<UserPermission>? permissions,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      role: role,
      salt: salt ?? this.salt,
      pinHash: pinHash ?? this.pinHash,
      scheme: scheme ?? this.scheme,
      permissions: permissions ?? this.permissions,
      createdAtMs: createdAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.name,
    'salt': salt,
    'hash': pinHash,
    'scheme': scheme,
    'permissions': permissions.map((p) => p.name).toList(),
    'createdAt': createdAtMs,
  };

  /// Returns `null` for malformed entries so one bad record cannot wipe the
  /// whole user list.
  static AppUser? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    final salt = raw['salt'];
    final hash = raw['hash'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    if (salt is! String || salt.isEmpty) return null;
    if (hash is! String || hash.isEmpty) return null;

    final role = raw['role'] == UserRole.owner.name
        ? UserRole.owner
        : UserRole.staff;

    final permissions = <UserPermission>{};
    final rawPermissions = raw['permissions'];
    if (rawPermissions is List) {
      for (final entry in rawPermissions) {
        if (entry is! String) continue;
        for (final permission in UserPermission.values) {
          if (permission.name == entry) permissions.add(permission);
        }
      }
    }

    final createdAt = raw['createdAt'];
    return AppUser(
      id: id,
      name: name,
      role: role,
      salt: salt,
      pinHash: hash,
      scheme: raw['scheme'] is String ? raw['scheme'] as String : 'v2',
      permissions: permissions,
      createdAtMs: createdAt is int ? createdAt : 0,
    );
  }
}
