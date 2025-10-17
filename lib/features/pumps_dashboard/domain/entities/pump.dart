class Pump {
  const Pump({
    required this.id,
    required this.label,
    required this.nozzles,
  });

  final int id;
  final String label;
  final List<Nozzle> nozzles;
}

class Nozzle {
  const Nozzle({
    required this.id,
    required this.label,
    required this.fuelType,
    required this.volume,
  });

  final int id;
  final String label;
  final int fuelType;
  final double volume;
}