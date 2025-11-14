import 'package:flutter/material.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/core/utils/formatters.dart';
import 'package:gazstation/features/pumps_dashboard/domain/entities/pump.dart';
import 'package:gazstation/features/station_list/data/models/remote_gas_station_models.dart';

class PumpCard extends StatelessWidget {
  const PumpCard({super.key, required this.pump, required this.transactions});

  final Pump pump;
  final List<PumpTransactionDto> transactions;

  // Fonction utilitaire pour mapper le type de carburant à un nom et une couleur
  ({String name, Color color}) _getFuelInfo(int fuelType) {
    switch (fuelType) {
      case 1:
        return (name: 'GAZOIL', color: const Color(0xFFF5B51B)); // Or
      case 2:
        return (name: 'ESSENCE', color: const Color(0xFFE74C3C)); // Rouge
      case 3:
        return (name: 'GPL', color: const Color(0xFF4CAF50)); // Vert
      default:
        return (name: 'INCONNU', color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 350, // Largeur fixe pour chaque carte
      // Nouveau style : fond blanc, ombre et bordure arrondie
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte (icône et nom de la pompe)
          Row(
            children: [
              // MODIFICATION ICI : Image.asset remplacé par une Icon
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.local_gas_station,
                  color: AppTheme.navy,
                  size: 28,
                ),
              ),
              // FIN DE LA MODIFICATION
              const SizedBox(width: 16),
              Text(
                pump.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE6E8EF)),
          const SizedBox(height: 8),

          // Affiche chaque pistolet de la pompe
          ...pump.nozzles.map((nozzle) {
            final fuelInfo = _getFuelInfo(nozzle.fuelType);
            final nozzleAmount = transactions
                .where((transaction) => transaction.nozzleId == nozzle.id)
                .fold<double>(
                  0,
                  (sum, transaction) => sum + (transaction.amount ?? 0),
                );
            return _NozzleRow(
              fuelName: fuelInfo.name,
              fuelColor: fuelInfo.color,
              voletLabel: nozzle.label,
              volume: nozzle.volume,
              amount: nozzleAmount,
            );
          }),
        ],
      ),
    );
  }
}

// Widget privé pour afficher une seule ligne de pistolet (style adapté)
class _NozzleRow extends StatelessWidget {
  const _NozzleRow({
    required this.fuelName,
    required this.fuelColor,
    required this.voletLabel,
    required this.volume,
    required this.amount,
  });

  final String fuelName;
  final Color fuelColor;
  final String voletLabel;
  final double volume;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // Info Carburant (Badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: fuelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              fuelName,
              style: TextStyle(
                color: fuelColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Nom du volet
          Expanded(
            child: Text(
              voletLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF707A8A),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Volume et Montant
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatLiters(volume, decimals: 2),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatNumber(amount, decimals: 2)} DA',
                style: const TextStyle(color: Color(0xFF707A8A), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
