class PumpDto {
  PumpDto({
    required this.id,
    required this.localId,
    required this.label,
    required this.stationId,
  });

  factory PumpDto.fromJson(Map<String, dynamic> json) {
    return PumpDto(
      id: json['id'] as int,
      localId: json['IDLocal'] as int?,
      label: (json['Libelle'] as String?)?.trim() ?? '',
      stationId: json['StationID'] as int,
    );
  }

  final int id;
  final int? localId;
  final String label;
  final int stationId;
}