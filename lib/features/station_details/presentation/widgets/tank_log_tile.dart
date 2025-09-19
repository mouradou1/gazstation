import 'package:flutter/material.dart';
import 'package:gazstation/features/home/domain/entities/gas_station.dart';

class TankLogTile extends StatelessWidget {
  const TankLogTile({
    super.key,
    required this.entry,
    required this.showDivider,
  });

  final TankLogEntry entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = entry.isPositive;
    final chipColor = isPositive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE74C3C);
    final chipIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(entry.dateTime),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${entry.volumeLiters.toStringAsFixed(0)}L',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 18),
                        Text(
                          '${entry.heightCm.toStringAsFixed(0)} cm',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(entry.dateTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _VariationChip(
                    color: chipColor,
                    icon: chipIcon,
                    percent: entry.variationPercent,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFE6E8EF)),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$day.$month.$year';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _VariationChip extends StatelessWidget {
  const _VariationChip({
    required this.color,
    required this.icon,
    required this.percent,
  });

  final Color color;
  final IconData icon;
  final double percent;

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
          Text(
            percent.abs().toStringAsFixed(0),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 16, color: color),
        ],
      ),
    );
  }
}
