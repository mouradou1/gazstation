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
        return const Color(0xFFF5B51B); // Orange
      case 'ESS':
        return const Color(0xFFE74C3C); // Rouge
      case 'GPL':
        return const Color(0xFF4CAF50); // Vert (Changé pour correspondre à votre demande précédente)
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fuelColor = _getFuelColor(summary.fuelTypeName);

    // CORRECTION ICI : Vérification de la capacité > 0 pour éviter la division par zéro (Infinity -> 100%)
    final realPercent = summary.totalCapacityLiters > 0
        ? (summary.realVolumeLiters / summary.totalCapacityLiters).clamp(0.0, 1.0)
        : 0.0;

    final theoreticalPercent = summary.totalCapacityLiters > 0
        ? (summary.theoreticalVolumeLiters / summary.totalCapacityLiters).clamp(0.0, 1.0)
        : 0.0;

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
            color: AppTheme.navy,
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
            valueColor: const Color(0xFFE74C3C),
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

// Widget privé pour la jauge horizontale
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
    // Sécurité pour l'affichage du texte (0.0% au lieu de NaN%)
    final displayPercent = percent.isNaN || percent.isInfinite ? 0.0 : percent;

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
              '${(displayPercent * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: displayPercent,
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