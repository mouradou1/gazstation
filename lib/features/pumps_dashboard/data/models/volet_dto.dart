class VoletDto {
  VoletDto({
    required this.id,
    required this.pumpId,
    required this.type,
    required this.label,
    required this.initialIndex,
    required this.currentIndex,
    this.nozzleNumber,
  });

  factory VoletDto.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return VoletDto(
      id: json['id'] as int,
      pumpId: json['IDPump2'] as int,
      type: json['Type'] as int,
      label: (json['Libelle'] as String?)?.trim() ?? '',
      initialIndex: parseDouble(json['IndexInitial']) ?? 0.0,
      currentIndex: parseDouble(json['indexActuel']) ?? 0.0,
      // num_nazel est l'identifiant métier attendu côté transactions (champ Nozzle).
      // Fallback sur IDLocal si num_nazel n'est pas présent, puis sur id.
      nozzleNumber:
          parseInt(json['num_nazel']) ??
          parseInt(json['Num_Nazel']) ??
          parseInt(json['IDLocal']) ??
          parseInt(json['id']),
    );
  }

  final int id;
  final int pumpId;
  final int type;
  final String label;
  final int? nozzleNumber;
  final double initialIndex;
  final double currentIndex;

  double get volume => (currentIndex - initialIndex).clamp(0, double.infinity);
}
