import 'package:flutter/material.dart';
import 'package:gazstation/core/utils/formatters.dart';
import 'package:gazstation/features/pumps_dashboard/domain/entities/pump.dart';
import 'package:gazstation/features/pumps_dashboard/presentation/widgets/pump_card.dart';

class PumpsList extends StatelessWidget {
  const PumpsList({super.key, required this.pumps});

  final List<Pump> pumps;

  @override
  Widget build(BuildContext context) {
    // CORRECTION : Calcul des totaux réels
    double totalGasoil = 0.0;
    double totalEssence = 0.0;
    double totalGPL = 0.0;

    for (final pump in pumps) {
      for (final nozzle in pump.nozzles) {
        switch (nozzle.fuelType) {
          case 1: // GAZOIL
            totalGasoil += nozzle.volume;
            break;
          case 2: // ESSENCE
            totalEssence += nozzle.volume;
            break;
          case 3: // GPL
            totalGPL += nozzle.volume;
            break;
        }
      }
    }
    // FIN DE LA CORRECTION

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _TotalsHeader(
            totalGasoil: totalGasoil,
            totalEssence: totalEssence,
            totalGPL: totalGPL,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: pumps
                .map((pump) => PumpCard(pump: pump))
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
    required this.totalGasoil,
    required this.totalEssence,
    required this.totalGPL,
  });

  final double totalGasoil;
  final double totalEssence;
  final double totalGPL;

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
            volume: totalGasoil,
            color: const Color(0xFFF5B51B), // Or
          ),
          _TotalBlock(
            label: 'Total Essence',
            volume: totalEssence,
            color: const Color(0xFFE74C3C), // Rouge
          ),
          _TotalBlock(
            label: 'Total GPL',
            volume: totalGPL,
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
    required this.color,
  });

  final String label;
  final double volume;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          formatLiters(volume, decimals: 2),
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '0,00 DA', // Montant en dur pour l'instant
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: const Color(0xFF707A8A)),
        ),
      ],
    );
  }
}