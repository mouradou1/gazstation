class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.localId,
    this.accessRight,
    this.status,
    this.supervisorId,
    this.addedBy,
    this.addedAt,
    this.updatedBy,
    this.updatedAt,
    this.stationId,
  });

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final int? localId;
  final String? accessRight;
  final int? status;
  final int? supervisorId;
  final String? addedBy;
  final DateTime? addedAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final int? stationId;

  String get displayName => '$firstName $lastName'.trim();
}
