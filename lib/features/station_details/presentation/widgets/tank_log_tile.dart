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
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(entry.dateTime),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.volumeLiters.toStringAsFixed(0)} L',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9AA1B0),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.heightCm.toStringAsFixed(0)} cm',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hauteur',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9AA1B0),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chipIcon, size: 16, color: chipColor),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.variationPercent.abs().toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: chipColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
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
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year  $hour:$minute';
  }
}
