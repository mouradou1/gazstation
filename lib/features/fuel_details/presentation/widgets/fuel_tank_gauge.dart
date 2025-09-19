import 'package:flutter/material.dart';
import 'package:gazstation/core/theme/app_theme.dart';

class FuelTankGauge extends StatelessWidget {
  const FuelTankGauge({super.key, required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLow = percent <= 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${(percent * 100).toStringAsFixed(0)}%',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 6),
          ),
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: percent.clamp(0.0, 1.0),
            widthFactor: 1,
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: isLow ? const Color(0xFFE57373) : AppTheme.navy,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
            ),
          ),
        ),
        if (isLow) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.warning_amber_outlined, color: Color(0xFFE57373)),
              SizedBox(width: 8),
              Text(
                'Alerte rupture de stock',
                style: TextStyle(
                  color: Color(0xFFE57373),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
