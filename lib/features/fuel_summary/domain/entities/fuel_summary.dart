import 'dart:math';

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
  double get remainingToFillLiters =>
      max(totalCapacityLiters - realVolumeLiters, 0);

  // Propriété calculée pour le "Manque"
  double get shortfallLiters =>
      max(theoreticalVolumeLiters - realVolumeLiters, 0);
}
