import 'package:flutter/material.dart';
import 'package:gazstation/core/theme/app_theme.dart';

class FuelHeaderCard extends StatelessWidget {
  const FuelHeaderCard({
    super.key,
    required this.label,
    required this.capacity,
    required this.volume,
    required this.height,
    required this.lastSync,
  });

  final String label;
  final String capacity;
  final String volume;
  final String height;
  final String lastSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricBlock(title: 'Volume (Litre)', value: volume),
              _MetricBlock(title: 'Dernier synchro', value: lastSync),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niveau (litre)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9AA1B0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(volume, style: theme.textTheme.bodyMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Hauteur',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9AA1B0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(height, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Capacité $capacity',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF9AA1B0)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
