import 'package:flutter/material.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import '../../../home/domain/entities/gas_station.dart';

class TankSnapshot extends StatelessWidget {
  const TankSnapshot({
    super.key,
    required this.tank,
    required this.onSeeDetails,
  });

  final FuelTank tank;
  final VoidCallback onSeeDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = tank.fillPercent.clamp(0.0, 1.0);
    final isLow = percent <= tank.warningThresholdPercent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 12),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: '${tank.label} ',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(
                            text: '${tank.capacityLiters.toStringAsFixed(0)}L',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF707A8A),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isLow)
                      Row(
                        children: const [
                          Icon(
                            Icons.error_outline,
                            color: Color(0xFFE74C3C),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Alerte rupture de stock',
                            style: TextStyle(
                              color: Color(0xFFE74C3C),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              _StatusDot(isLow: isLow),
            ],
          ),
          const SizedBox(height: 32),

          _HorizontalTankGauge(
            tank: tank,
          ),
          const SizedBox(height: 18),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onSeeDetails,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.navy,
              ),
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              label: const Text('Afficher plus'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalTankGauge extends StatelessWidget {
  const _HorizontalTankGauge({
    required this.tank,
  });

  final FuelTank tank;

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
  }

  Color _getGaugeColor(double percent) {
    if (percent <= 0.10) {
      return const Color(0xFFE57373);
    } else if (percent <= 0.30) {
      return const Color(0xFFFFC107);
    } else {
      return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = tank.fillPercent;
    final percentLabel = '${(percent * 100).toStringAsFixed(0)}%'; // **2) Donnée pour le pourcentage**
    final gaugeColor = _getGaugeColor(percent);

    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Le corps du réservoir (jauge)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                borderRadius: BorderRadius.circular(30),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Remplissage vertical
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: percent,
                      widthFactor: 1.0, // Assure que ça prend toute la largeur
                      child: Container(
                        color: gaugeColor,
                      ),
                    ),
                  ),
                  // **2) Affichage du pourcentage à l'intérieur**
                  Text(
                    percentLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: percent <= 0.10 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // **1) Connexion entre le bouchon et la carte de détails**
          Positioned(
            top: 25, // Ajusté pour être précis
            right: 80, // Ajusté pour être précis
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // La ligne de connexion
                Container(
                  height: 15, // hauteur de la ligne
                  width: 1.5,
                  color: const Color(0xFFBDBDBD),
                ),
                // Le bouchon du réservoir
                Container(
                  height: 20,
                  width: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Carte des détails
          Positioned(
            top: -15,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      'Dernier synchro',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(tank.lastSync),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tank.currentVolumeLiters.toStringAsFixed(0)} L',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tank.currentHeightCm.toStringAsFixed(0)} cm',
                        style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF9AA1B0)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isLow});

  final bool isLow;

  @override
  Widget build(BuildContext context) {
    final color = isLow ? const Color(0xFFE53935) : const Color(0xFF4CAF50);
    return Container(
      height: 12,
      width: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}