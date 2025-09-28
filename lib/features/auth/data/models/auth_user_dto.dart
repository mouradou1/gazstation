import 'package:gazstation/features/auth/domain/entities/auth_user.dart';

class AuthUserDto {
  AuthUserDto({
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

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is DateTime) {
        return value;
      }
      final raw = value.toString();
      if (raw.isEmpty) {
        return null;
      }
      return DateTime.tryParse(raw);
    }

    int? parseInt(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse(value.toString());
    }

    String? parseString(dynamic value) {
      if (value == null) {
        return null;
      }
      final result = value.toString().trim();
      return result.isEmpty ? null : result;
    }

    return AuthUserDto(
      id: parseInt(json['id']) ?? 0,
      localId: parseInt(json['IDLocal']),
      username: parseString(json['NomUtilisateur']) ?? '',
      firstName: parseString(json['Prenom']) ?? '',
      lastName: parseString(json['Nom']) ?? '',
      accessRight: parseString(json['DroitAcces']),
      status: parseInt(json['statut']),
      supervisorId: parseInt(json['superviseur']),
      addedBy:
          parseString(json['AjouterPar']) ?? parseString(json['AjoutePar']),
      addedAt: parseDate(json['AjouterLe']),
      updatedBy:
          parseString(json['ModifiePar']) ?? parseString(json['ModifierPar']),
      updatedAt: parseDate(json['ModifieLe']),
      stationId: parseInt(json['StationID']) ?? parseInt(json['stationID']),
    );
  }

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

  AuthUser toDomain() {
    return AuthUser(
      id: id,
      username: username,
      firstName: firstName,
      lastName: lastName,
      localId: localId,
      accessRight: accessRight,
      status: status,
      supervisorId: supervisorId,
      addedBy: addedBy,
      addedAt: addedAt,
      updatedBy: updatedBy,
      updatedAt: updatedAt,
      stationId: stationId,
    );
  }
}
