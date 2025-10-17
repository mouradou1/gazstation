class FuelSummary {
  const FuelSummary({
    required this.fuelTypeName,
    required this.totalCapacityLiters,
    required this.realVolumeLiters,
    required this.theoreticalVolumeLiters,
  });

  final String fuelTypeName;
  final double totalCapacityLiters;
  final double realVolumeLiters;
  final double theoreticalVolumeLiters;

  // Propriété calculée pour le "Reste à remplir"
  double get remainingToFillLiters => totalCapacityLiters - realVolumeLiters;

  // Propriété calculée pour le "Manque"
  double get shortfallLiters => theoreticalVolumeLiters - realVolumeLiters;
}