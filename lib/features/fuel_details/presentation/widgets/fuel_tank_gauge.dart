import 'package:flutter/material.dart';

class FuelTankGauge extends StatelessWidget {
  const FuelTankGauge({super.key, required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final palette = _GaugePalette.forPercent(percent);

    return SizedBox(
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 60),
              _GaugeBody(percent: percent, palette: palette),
              const SizedBox(width: 60),
            ],
          ),
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugeBody extends StatelessWidget {
  const _GaugeBody({required this.percent, required this.palette});

  final double percent;
  final _GaugePalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E8EF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 18,
                  width: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9AA1B0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          width: 180,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(44),
                  border: Border.all(color: const Color(0xFFE1E4EE), width: 2),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: percent.clamp(0.0, 1.0),
                  widthFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(42),
                      ),
                      gradient: LinearGradient(
                        colors: [palette.fillStart, palette.fillEnd],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GaugePalette {
  const _GaugePalette({required this.fillStart, required this.fillEnd});

  final Color fillStart;
  final Color fillEnd;

  static _GaugePalette forPercent(double percent) {
    if (percent >= 0.5) {
      return const _GaugePalette(
        fillStart: Color(0xFF7CA8FF),
        fillEnd: Color(0xFF233388),
      );
    }
    if (percent >= 0.2) {
      return const _GaugePalette(
        fillStart: Color(0xFFFFE27A),
        fillEnd: Color(0xFFF6B21B),
      );
    }
    return const _GaugePalette(
      fillStart: Color(0xFFFFA4A4),
      fillEnd: Color(0xFFE53935),
    );
  }
}
