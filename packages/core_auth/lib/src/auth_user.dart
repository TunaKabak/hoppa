class AuthUser {
  final String id;
  final String phone;
  final String? name;
  final String? surname;
  final String? role;

  const AuthUser({
    required this.id,
    required this.phone,
    this.name,
    this.surname,
    this.role,
  });

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['id']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      name: map['name']?.toString(),
      surname: map['surname']?.toString(),
      role: map['role']?.toString(),
    );
  }

  String get displayName {
    final n = name ?? '';
    final s = surname ?? '';
    final full = '$n $s'.trim();
    return full.isNotEmpty ? full : phone;
  }
}
