import 'package:flutter/material.dart';
import 'package:gazstation/core/utils/formatters.dart';
import 'package:gazstation/features/pumps_dashboard/domain/entities/pump.dart';
import 'package:gazstation/features/pumps_dashboard/presentation/widgets/pump_card.dart';
import 'package:gazstation/features/station_list/data/models/remote_gas_station_models.dart';

class PumpsList extends StatelessWidget {
  const PumpsList({super.key, required this.pumps, required this.transactions});

  final List<Pump> pumps;
  final List<PumpTransactionDto> transactions;

  @override
  Widget build(BuildContext context) {
    final nozzleFuelTypes = <int, int>{};
    final pumpFuelTypes = <int, int>{};
    for (final pump in pumps) {
      final dominantFuelType = pump.nozzles.isNotEmpty
          ? pump.nozzles.first.fuelType
          : 0;
      pumpFuelTypes[pump.id] = dominantFuelType;
      for (final nozzle in pump.nozzles) {
        nozzleFuelTypes[nozzle.id] = nozzle.fuelType;
      }
    }

    double totalGasoilVolume = 0.0;
    double totalGasoilAmount = 0.0;
    double totalEssenceVolume = 0.0;
    double totalEssenceAmount = 0.0;
    double totalGPLVolume = 0.0;
    double totalGPLAmount = 0.0;

    for (final transaction in transactions) {
      final nozzleId = transaction.nozzleId;
      int? fuelType;
      if (nozzleId != null) {
        fuelType = nozzleFuelTypes[nozzleId];
      } else if (transaction.pumpId != null) {
        fuelType = pumpFuelTypes[transaction.pumpId!];
      }
      if (fuelType == null) {
        continue;
      }

      final volume = transaction.volume ?? 0;
      final amount = transaction.amount ?? 0;

      switch (fuelType) {
        case 1:
          totalGasoilVolume += volume;
          totalGasoilAmount += amount;
          break;
        case 2:
          totalEssenceVolume += volume;
          totalEssenceAmount += amount;
          break;
        case 3:
          totalGPLVolume += volume;
          totalGPLAmount += amount;
          break;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _TotalsHeader(
            totalGasoilVolume: totalGasoilVolume,
            totalGasoilAmount: totalGasoilAmount,
            totalEssenceVolume: totalEssenceVolume,
            totalEssenceAmount: totalEssenceAmount,
            totalGPLVolume: totalGPLVolume,
            totalGPLAmount: totalGPLAmount,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: pumps
                .map((pump) => PumpCard(pump: pump, transactions: transactions))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// Nouveau widget pour l'en-tête des totaux, style carte blanche
class _TotalsHeader extends StatelessWidget {
  const _TotalsHeader({
    required this.totalGasoilVolume,
    required this.totalGasoilAmount,
    required this.totalEssenceVolume,
    required this.totalEssenceAmount,
    required this.totalGPLVolume,
    required this.totalGPLAmount,
  });

  final double totalGasoilVolume;
  final double totalGasoilAmount;
  final double totalEssenceVolume;
  final double totalEssenceAmount;
  final double totalGPLVolume;
  final double totalGPLAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TotalBlock(
            label: 'Total Gasoil',
            volume: totalGasoilVolume,
            amount: totalGasoilAmount,
            color: const Color(0xFFF5B51B), // Or
          ),
          _TotalBlock(
            label: 'Total Essence',
            volume: totalEssenceVolume,
            amount: totalEssenceAmount,
            color: const Color(0xFFE74C3C), // Rouge
          ),
          _TotalBlock(
            label: 'Total GPL',
            volume: totalGPLVolume,
            amount: totalGPLAmount,
            color: const Color(0xFF4CAF50), // Vert
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher un bloc de total
class _TotalBlock extends StatelessWidget {
  const _TotalBlock({
    required this.label,
    required this.volume,
    required this.amount,
    required this.color,
  });

  final String label;
  final double volume;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatLiters(volume, decimals: 2),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatNumber(amount, decimals: 2)} DA',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF707A8A),
          ),
        ),
      ],
    );
  }
}
