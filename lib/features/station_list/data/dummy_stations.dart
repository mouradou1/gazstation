
import '../domain/entities/gas_station.dart';

final dummyStations = <GasStation>[
  GasStation(
    id: 'station-1',
    name: 'Gas Station 1',
    address: '31 Avenue de la République, Paris',
    alerts: const StationAlerts(information: 3, warnings: 1, critical: 0),
    tanks: [
      FuelTank(
        id: 'diesel',
        label: 'Diesel',
        capacityLiters: 50000,
        currentVolumeLiters: 2200,
        currentHeightCm: 1467,
        lastSync: DateTime(2024, 5, 23, 15, 41),
        warningThresholdPercent: 0.1,
        logs: [
          TankLogEntry(
            dateTime: DateTime(2024, 5, 25, 7, 0),
            volumeLiters: 2500,
            heightCm: 1080,
            variationPercent: 0.4,
          ),
          TankLogEntry(
            dateTime: DateTime(2024, 5, 24, 19, 30),
            volumeLiters: 2500,
            heightCm: 1080,
            variationPercent: -0.4,
          ),
          TankLogEntry(
            dateTime: DateTime(2024, 5, 24, 13, 20),
            volumeLiters: 2500,
            heightCm: 1080,
            variationPercent: 0.4,
          ),
          TankLogEntry(
            dateTime: DateTime(2024, 5, 24, 8, 5),
            volumeLiters: 2500,
            heightCm: 1080,
            variationPercent: -0.4,
          ),
        ],
        summary: const TankSummary(
          minVolume: 15000,
          maxVolume: 70000,
          startVolume: 15000,
          endVolume: 70000,
          totalDifference: 14834,
          totalPurchase: 0,
          totalSale: 67,
        ),
      ),
    ],
  ),
  GasStation(
    id: 'station-2',
    name: 'Gaz Station Marseille',
    address: '8 Rue du Port, Marseille',
    alerts: const StationAlerts(information: 2, warnings: 0, critical: 1),
    tanks: [
      FuelTank(
        id: 'essence',
        label: 'Essence 95',
        capacityLiters: 40000,
        currentVolumeLiters: 12500,
        currentHeightCm: 890,
        lastSync: DateTime(2024, 5, 23, 11, 15),
        warningThresholdPercent: 0.2,
        logs: [
          TankLogEntry(
            dateTime: DateTime(2024, 5, 25, 8, 0),
            volumeLiters: 2100,
            heightCm: 820,
            variationPercent: 0.3,
          ),
          TankLogEntry(
            dateTime: DateTime(2024, 5, 24, 18, 0),
            volumeLiters: 1800,
            heightCm: 740,
            variationPercent: -0.2,
          ),
        ],
        summary: const TankSummary(
          minVolume: 10000,
          maxVolume: 40000,
          startVolume: 12500,
          endVolume: 31000,
          totalDifference: 9500,
          totalPurchase: 1200,
          totalSale: 300,
        ),
      ),
    ],
  ),
  GasStation(
    id: 'station-3',
    name: 'Station Lyon Sud',
    address: '245 Boulevard Yves Farges, Lyon',
    alerts: const StationAlerts(information: 1, warnings: 2, critical: 1),
    tanks: [
      FuelTank(
        id: 'gpl',
        label: 'GPL',
        capacityLiters: 35000,
        currentVolumeLiters: 31000,
        currentHeightCm: 1560,
        lastSync: DateTime(2024, 5, 23, 9, 30),
        warningThresholdPercent: 0.15,
        logs: [
          TankLogEntry(
            dateTime: DateTime(2024, 5, 25, 10, 0),
            volumeLiters: 2800,
            heightCm: 1450,
            variationPercent: 0.1,
          ),
          TankLogEntry(
            dateTime: DateTime(2024, 5, 24, 17, 30),
            volumeLiters: 2600,
            heightCm: 1400,
            variationPercent: -0.3,
          ),
        ],
        summary: const TankSummary(
          minVolume: 12000,
          maxVolume: 35000,
          startVolume: 22000,
          endVolume: 32500,
          totalDifference: 10500,
          totalPurchase: 2300,
          totalSale: 180,
        ),
      ),
    ],
  ),
];
