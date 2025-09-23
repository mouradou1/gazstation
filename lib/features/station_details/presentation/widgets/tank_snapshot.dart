import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/home/domain/entities/gas_station.dart';

class TankSnapshot extends StatelessWidget {
  const TankSnapshot({
    super.key,
    required this.tank,
    required this.onSeeDetails,
    this.showSeeDetails = true,
    this.onTap,
    this.isSelected = false,
  });

  final FuelTank tank;
  final VoidCallback onSeeDetails;
  final bool showSeeDetails;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = tank.fillPercent.clamp(0.0, 1.0);
    final percentLabel = '${(percent * 100).toStringAsFixed(0)}%';
    final isLow = percent <= tank.warningThresholdPercent;

    // La couleur du point de statut est maintenant toujours verte pour correspondre à l'image.
    final levelColor = const Color(0xFF38C172);

    final borderRadius = BorderRadius.circular(28);
    final borderColor = isSelected ? AppTheme.navy : Colors.transparent;

    final lastSyncLabel = _formatLastSync(tank.lastSync);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: isSelected ? 2 : 0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                offset: Offset(0, 12),
                blurRadius: 24,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                                text:
                                '${tank.capacityLiters.toStringAsFixed(0)}L',
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusDot(color: levelColor),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Dernier synchro',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: const Color(0xFF7C8596),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            lastSyncLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF272B36),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _HorizontalTankGauge(tank: tank, percentLabel: percentLabel),
              const SizedBox(height: 12),
              if (showSeeDetails)
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: onSeeDetails,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Afficher plus',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppTheme.navy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastSync(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
  }
}

class _HorizontalTankGauge extends StatelessWidget {
  const _HorizontalTankGauge({required this.tank, required this.percentLabel});

  final FuelTank tank;
  final String percentLabel;

  Color _getGaugeColor(double percent) {
    if (percent < 0.2) {
      return const Color(0xFFFF4D52);
    }
    if (percent < 0.5) {
      return const Color(0xFFFFC431);
    }
    return const Color(0xFF38C172);
  }

  @override
  Widget build(BuildContext context) {
    final percent = tank.fillPercent.clamp(0.0, 1.0);
    final gaugeColor = _getGaugeColor(percent);
    return LayoutBuilder(
      builder: (context, constraints) {
        const totalHeight = 138.0;
        const gaugeHeight = 68.0;
        const bubbleWidth = 126.0;
        const bubbleHeight = 60.0;
        const bubbleTop = 6.0;

        final maxWidth = constraints.maxWidth;
        final bubbleLeft = math.max(0.0, maxWidth - bubbleWidth);
        final availableForConnector = bubbleLeft - 12;
        final maxByConnector = availableForConnector > 0
            ? availableForConnector / 0.72
            : maxWidth;
        final gaugeWidth = math.min(
          math.max(160.0, maxWidth * 0.62),
          math.min(maxByConnector, maxWidth - 12),
        );
        final gaugeTop = totalHeight - gaugeHeight;

        final connectorStart = Offset(gaugeWidth * 0.72, gaugeTop);
        final connectorTargetX = bubbleLeft > 8 ? bubbleLeft - 8 : bubbleLeft;
        final connectorEnd = Offset(
          connectorTargetX,
          bubbleTop + bubbleHeight / 2,
        );

        final capSize = const Size(32, 14);

        // LA CORRECTION EST ICI
        final capOffset = Offset(
          connectorStart.dx - capSize.width / 2,
          gaugeTop - capSize.height / 2, // Positionne le capuchon sur la jauge
        );

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GaugeConnectorPainter(
                    start: connectorStart,
                    end: connectorEnd,
                  ),
                ),
              ),
              Positioned(
                left: capOffset.dx,
                top: capOffset.dy,
                width: capSize.width,
                height: capSize.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E6EF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD2D7E2)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: gaugeTop,
                width: gaugeWidth,
                height: gaugeHeight,
                child: _GaugeBar(
                  percent: percent,
                  percentLabel: percentLabel,
                  gaugeColor: gaugeColor,
                ),
              ),
              Positioned(
                left: bubbleLeft,
                top: bubbleTop,
                width: bubbleWidth,
                height: bubbleHeight,
                child: _MeasurementBubble(
                  volumeLabel: '${_formatQuantity(tank.currentVolumeLiters)} L',
                  heightLabel: '${_formatQuantity(tank.currentHeightCm)} cm',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatQuantity(double value) {
    final rounded = value.round().abs();
    final digits = rounded.toString().split('').reversed.toList();
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += 3) {
      final slice = digits.sublist(i, math.min(i + 3, digits.length));
      groups.add(slice.reversed.join());
    }
    final formatted = groups.reversed.join(' ');
    return value < 0 ? '-$formatted' : formatted;
  }
}

class _GaugeBar extends StatelessWidget {
  const _GaugeBar({
    required this.percent,
    required this.percentLabel,
    required this.gaugeColor,
  });

  final double percent;
  final String percentLabel;
  final Color gaugeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topColor = Color.lerp(Colors.white, gaugeColor, 0.65)!;
    final fillGradient = LinearGradient(
      colors: [topColor, gaugeColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFFE0E4F0), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: percent.clamp(0.0, 1.0),
                widthFactor: 1.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: fillGradient),
                ),
              ),
            ),
            Text(
              percentLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF141722),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementBubble extends StatelessWidget {
  const _MeasurementBubble({
    required this.volumeLabel,
    required this.heightLabel,
  });

  final String volumeLabel;
  final String heightLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E4EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              volumeLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF202430),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              heightLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E7688),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugeConnectorPainter extends CustomPainter {
  const _GaugeConnectorPainter({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD2D7E2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(start.dx, end.dy)
      ..lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GaugeConnectorPainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      width: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 8),
        ],
      ),
    );
  }
}