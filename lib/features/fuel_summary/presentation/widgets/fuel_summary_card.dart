import 'package:flutter/material.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/core/utils/formatters.dart';
import 'package:gazstation/features/fuel_summary/domain/entities/fuel_summary.dart';

class FuelSummaryCard extends StatelessWidget {
  const FuelSummaryCard({super.key, required this.summary});

  final FuelSummary summary;

  // Fonction utilitaire pour choisir la couleur en fonction du nom du carburant
  Color _getFuelColor(String fuelName) {
    switch (fuelName.toUpperCase()) {
      case 'DZL':
        return const Color(0xFFF39C12); // Orange
      case 'ESS':
        return const Color(0xFFE74C3C); // Rouge
      case 'GPL':
        return const Color(0xFF2ECC71); // Vert
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fuelColor = _getFuelColor(summary.fuelTypeName);
    final realPercent = (summary.realVolumeLiters / summary.totalCapacityLiters)
        .clamp(0.0, 1.0);
    final theoreticalPercent =
    (summary.theoreticalVolumeLiters / summary.totalCapacityLiters)
        .clamp(0.0, 1.0);

    return Container(
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
          // En-tête avec le nom et la capacité
          Text(
            summary.fuelTypeName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Capacité totale : ${formatLiters(summary.totalCapacityLiters)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF707A8A),
            ),
          ),
          const SizedBox(height: 24),

          // Jauge pour le volume Réel
          _SummaryGauge(
            label: 'Réel',
            percent: realPercent,
            volume: summary.realVolumeLiters,
            color: fuelColor,
          ),
          const SizedBox(height: 16),

          // Jauge pour le volume Théorique
          _SummaryGauge(
            label: 'Théorique',
            percent: theoreticalPercent,
            volume: summary.theoreticalVolumeLiters,
            color: AppTheme.navy, // Couleur différente pour distinguer
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE6E8EF)),
          const SizedBox(height: 20),

          // Ligne "Reste à remplir"
          _InfoRow(
            label: 'Reste à remplir',
            value: formatLiters(summary.remainingToFillLiters),
          ),
          const SizedBox(height: 12),

          // Ligne "Manque"
          _InfoRow(
            label: 'Manque',
            value: formatLiters(summary.shortfallLiters),
            valueColor: const Color(0xFFE74C3C), // Rouge pour le manque
          ),
        ],
      ),
    );
  }
}

// Widget privé pour une ligne d'information (ex: Reste à remplir)
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF707A8A),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor ?? AppTheme.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Widget privé pour la nouvelle jauge horizontale
class _SummaryGauge extends StatelessWidget {
  const _SummaryGauge({
    required this.label,
    required this.percent,
    required this.volume,
    required this.color,
  });

  final String label;
  final double percent;
  final double volume;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${(percent * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 12,
            backgroundColor: const Color(0xFFF1F2F7),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            formatLiters(volume),
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}