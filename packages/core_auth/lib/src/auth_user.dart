class AuthUser {
  final String id;
  final String phone;
  final String? name;
  final String? surname;
  final String? role;

  // Merchant-specific fields
  final String? email;
  final String? businessName;
  final String? status;         // PENDING, ACTIVE, REVISION, REJECTED, ON_HOLD
  final String? revisionMessage;
  final String? businessId;

  const AuthUser({
    required this.id,
    required this.phone,
    this.name,
    this.surname,
    this.role,
    this.email,
    this.businessName,
    this.status,
    this.revisionMessage,
    this.businessId,
  });

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['id']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      name: map['name']?.toString(),
      surname: map['surname']?.toString(),
      role: map['role']?.toString(),
      email: map['email']?.toString(),
      businessName: map['businessName']?.toString(),
      status: map['status']?.toString(),
      revisionMessage: map['revisionMessage']?.toString(),
      businessId: map['businessId']?.toString(),
    );
  }

  /// Merchant'tan gelen yanıt için factory (consumer'dan farklı alan adları)
  factory AuthUser.fromMerchantMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['id']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      name: map['businessName']?.toString(),  // Merchant için displayName = businessName
      surname: null,
      role: map['role']?.toString() ?? 'merchant',
      email: map['email']?.toString(),
      businessName: map['businessName']?.toString(),
      status: map['status']?.toString(),
      revisionMessage: map['revisionMessage']?.toString(),
      businessId: map['businessId']?.toString(),
    );
  }

  bool get isMerchant => role == 'merchant' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isActive => status == 'ACTIVE' || role == 'super_admin';
  bool get isPending => status == 'PENDING';
  bool get isRevision => status == 'REVISION';
  bool get isRejected => status == 'REJECTED';
  bool get isOnHold => status == 'ON_HOLD';

  String get displayName {
    if (businessName != null && businessName!.isNotEmpty) return businessName!;
    final n = name ?? '';
    final s = surname ?? '';
    final full = '$n $s'.trim();
    return full.isNotEmpty ? full : (email ?? phone);
  }

  AuthUser copyWith({
    String? status,
    String? revisionMessage,
    String? businessId,
  }) {
    return AuthUser(
      id: id,
      phone: phone,
      name: name,
      surname: surname,
      role: role,
      email: email,
      businessName: businessName,
      status: status ?? this.status,
      revisionMessage: revisionMessage ?? this.revisionMessage,
      businessId: businessId ?? this.businessId,
    );
  }
}
