class VoletDto {
  VoletDto({
    required this.id,
    required this.pumpId,
    required this.type,
    required this.label,
    required this.initialIndex,
    required this.currentIndex,
  });

  factory VoletDto.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return VoletDto(
      id: json['id'] as int,
      pumpId: json['IDPump2'] as int,
      type: json['Type'] as int,
      label: (json['Libelle'] as String?)?.trim() ?? '',
      initialIndex: parseDouble(json['IndexInitial']) ?? 0.0,
      currentIndex: parseDouble(json['indexActuel']) ?? 0.0,
    );
  }

  final int id;
  final int pumpId;
  final int type;
  final String label;
  final double initialIndex;
  final double currentIndex;

  double get volume => (currentIndex - initialIndex).clamp(0, double.infinity);
}