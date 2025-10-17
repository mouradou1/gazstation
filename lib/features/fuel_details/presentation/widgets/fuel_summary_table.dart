import 'package:flutter/material.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/station_list/domain/entities/gas_station.dart';

class FuelSummaryTable extends StatelessWidget {
  const FuelSummaryTable({super.key, required this.summary});

  final TankSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Min :',
            chipLabel: summary.minVolume.toStringAsFixed(0),
            chipColor: const Color(0xFFE74C3C),
            icon: Icons.arrow_downward,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Max :',
            chipLabel: summary.maxVolume.toStringAsFixed(0),
            chipColor: const Color(0xFF4CAF50),
            icon: Icons.arrow_upward,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Commencer par :',
            chipLabel: summary.startVolume.toStringAsFixed(0),
            chipColor: const Color(0xFFE74C3C),
            icon: Icons.arrow_downward,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Terminer :',
            chipLabel: summary.endVolume.toStringAsFixed(0),
            chipColor: const Color(0xFF4CAF50),
            icon: Icons.arrow_upward,
          ),
          const SizedBox(height: 18),
          _FooterValue(
            label: 'La différence',
            value: '${summary.totalDifference.toStringAsFixed(0)} L',
          ),
          const SizedBox(height: 6),
          Text(
            'Le total est entre le 23/05/2024 09:41 et le 24/05/2024 09:41',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.navy,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _FooterValue(
                  label: 'Achat :',
                  value: '${summary.totalPurchase.toStringAsFixed(0)} L',
                ),
              ),
              Expanded(
                child: _FooterValue(
                  label: 'Vente :',
                  value: '${summary.totalSale.toStringAsFixed(0)} L',
                  align: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.chipLabel,
    required this.chipColor,
    required this.icon,
  });

  final String label;
  final String chipLabel;
  final Color chipColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        _ValueChip(icon: icon, color: chipColor, label: chipLabel),
      ],
    );
  }
}

class _FooterValue extends StatelessWidget {
  const _FooterValue({
    required this.label,
    required this.value,
    this.align = TextAlign.left,
  });

  final String label;
  final String value;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: align,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF9AA1B0)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: align,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
