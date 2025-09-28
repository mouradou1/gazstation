class StationDto {
  StationDto({
    required this.id,
    required this.name,
    this.status,
    this.address,
  });

  factory StationDto.fromJson(Map<String, dynamic> json) {
    return StationDto(
      id: json['id'] as int,
      name: (json['Libelle'] as String?)?.trim().isNotEmpty == true
          ? (json['Libelle'] as String).trim()
          : 'Station ${json['id']}',
      status: json['statut'] as int?,
      address: (json['Adress'] as String?)?.trim().isNotEmpty == true
          ? (json['Adress'] as String).trim()
          : null,
    );
  }

  final int id;
  final String name;
  final int? status;
  final String? address;
}

class StationDetailsDto {
  StationDetailsDto({required this.stationId, this.address, this.company});

  factory StationDetailsDto.fromJson(Map<String, dynamic> json) {
    return StationDetailsDto(
      stationId: json['StationID'] as int,
      address: json['Adresse'] as String?,
      company: json['Societe'] as String?,
    );
  }

  final int stationId;
  final String? address;
  final String? company;
}

class TankDto {
  TankDto({
    required this.id,
    required this.stationId,
    required this.label,
    this.capacityLiters,
    this.currentVolume,
    this.currentHeight,
    this.warningThresholdPercent,
    this.lastSync,
    this.localId,
  });

  factory TankDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return DateTime.tryParse(raw);
    }

    double? parseDouble(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value.toString());
    }

    return TankDto(
      id: json['id'] as int,
      stationId: json['StationID'] as int,
      localId: json['IDLocal'] as int?,
      label: (json['Libelle'] as String?)?.trim().isNotEmpty == true
          ? (json['Libelle'] as String).trim()
          : 'Cuve ${json['id']}',
      capacityLiters:
          parseDouble(json['Volume']) ??
          parseDouble(json['VolumeLitreCalculer']),
      currentVolume:
          parseDouble(json['NiveauLitre']) ??
          parseDouble(json['VolumeLitreCalculer']),
      currentHeight: parseDouble(json['Niveau']) ?? parseDouble(json['calibr']),
      warningThresholdPercent: json['Token'] is num
          ? (json['Token'] as num).toDouble() / 100
          : null,
      lastSync:
          parseDate(json['ModifieLe'] as String?) ??
          parseDate(json['AjouterLe'] as String?),
    );
  }

  final int id;
  final int stationId;
  final int? localId;
  final String label;
  final double? capacityLiters;
  final double? currentVolume;
  final double? currentHeight;
  final double? warningThresholdPercent;
  final DateTime? lastSync;
}

class PumpTransactionDto {
  PumpTransactionDto({
    required this.id,
    required this.stationId,
    this.tankId,
    this.volume,
    this.totalVolume,
    this.amount,
    this.dateTime,
  });

  factory PumpTransactionDto.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value.toString());
    }

    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return DateTime.tryParse(raw);
    }

    return PumpTransactionDto(
      id: json['id'] as int,
      stationId: json['StationID'] as int,
      tankId: json['Tank'] as int?,
      volume: parseDouble(json['Volume']),
      totalVolume: parseDouble(json['TotalVolume']),
      amount: parseDouble(json['Amount']),
      dateTime:
          parseDate(json['DateTime'] as String?) ??
          parseDate(json['DateTimeStart'] as String?),
    );
  }

  final int id;
  final int stationId;
  final int? tankId;
  final double? volume;
  final double? totalVolume;
  final double? amount;
  final DateTime? dateTime;
}

class TankMovementDto {
  TankMovementDto({
    required this.id,
    this.localId,
    this.tankLocalId,
    this.value,
    this.valueLiters,
    this.modifiedAt,
    this.stationId,
  });

  factory TankMovementDto.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value.toString());
    }

    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return DateTime.tryParse(raw);
    }

    return TankMovementDto(
      id: json['id'] as int,
      localId: json['IDLocal'] is num ? (json['IDLocal'] as num).toInt() : null,
      tankLocalId: json['IDCuve'] is num
          ? (json['IDCuve'] as num).toInt()
          : null,
      value: parseDouble(json['Valeur']),
      valueLiters: parseDouble(json['ValeurLitre']),
      modifiedAt: parseDate(json['ModifieLe'] as String?),
      stationId: json['StationID'] is num
          ? (json['StationID'] as num).toInt()
          : null,
    );
  }

  final int id;
  final int? localId;
  final int? tankLocalId;
  final double? value;
  final double? valueLiters;
  final DateTime? modifiedAt;
  final int? stationId;
}
