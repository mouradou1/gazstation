class GasStation {
  const GasStation({
    required this.id,
    required this.name,
    required this.address,
    required this.alerts,
    required this.tanks,
  });

  final String id;
  final String name;
  final String address;
  final StationAlerts alerts;
  final List<FuelTank> tanks;
}

class StationAlerts {
  const StationAlerts({
    required this.information,
    required this.warnings,
    required this.critical,
  });

  final int information;
  final int warnings;
  final int critical;

  int get total => information + warnings + critical;
}

class FuelTank {
  const FuelTank({
    required this.id,
    required this.label,
    required this.capacityLiters,
    required this.currentVolumeLiters,
    required this.currentHeightCm,
    required this.lastSync,
    required this.warningThresholdPercent,
    required this.logs,
    required this.summary,
  });

  final String id;
  final String label;
  final double capacityLiters;
  final double currentVolumeLiters;
  final double currentHeightCm;
  final DateTime lastSync;
  final double warningThresholdPercent;
  final List<TankLogEntry> logs;
  final TankSummary summary;

  double get fillPercent => (currentVolumeLiters / capacityLiters).clamp(0, 1);
}

class TankLogEntry {
  const TankLogEntry({
    required this.dateTime,
    required this.volumeLiters,
    required this.heightCm,
    required this.variationPercent,
  });

  final DateTime dateTime;
  final double volumeLiters;
  final double heightCm;
  final double variationPercent;

  bool get isPositive => variationPercent >= 0;
}

class TankSummary {
  const TankSummary({
    required this.minVolume,
    required this.maxVolume,
    required this.startVolume,
    required this.endVolume,
    required this.totalDifference,
    required this.totalPurchase,
    required this.totalSale,
  });

  final double minVolume;
  final double maxVolume;
  final double startVolume;
  final double endVolume;
  final double totalDifference;
  final double totalPurchase;
  final double totalSale;
}
