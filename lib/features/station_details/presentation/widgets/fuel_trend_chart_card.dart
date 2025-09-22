import 'dart:math';

import 'package:flutter/material.dart';

class FuelTrendChartCard extends StatefulWidget {
  const FuelTrendChartCard({super.key});

  @override
  State<FuelTrendChartCard> createState() => _FuelTrendChartCardState();
}

class _FuelTrendChartCardState extends State<FuelTrendChartCard> {
  int _selectedIndex = 1;
  static const _ranges = ['24H', '1W', '1M', '1Y', 'All'];
  static const _defaultMaxValue = 5000.0;

  static final Map<String, List<_TrendPoint>> _trendData = {
    '24H': [
      const _TrendPoint(weekday: 'Mon', dayNumber: '15', value: 3200),
      const _TrendPoint(weekday: 'Tue', dayNumber: '16', value: 3000),
      const _TrendPoint(weekday: 'Wed', dayNumber: '17', value: 2800),
      const _TrendPoint(weekday: 'Thu', dayNumber: '18', value: 2400),
      const _TrendPoint(weekday: 'Fri', dayNumber: '19', value: 2100),
      const _TrendPoint(weekday: 'Sat', dayNumber: '20', value: 1800),
    ],
    '1W': [
      const _TrendPoint(weekday: 'Mon', dayNumber: '15', value: 3600),
      const _TrendPoint(weekday: 'Tue', dayNumber: '16', value: 3000),
      const _TrendPoint(weekday: 'Wed', dayNumber: '17', value: 2400),
      const _TrendPoint(weekday: 'Thu', dayNumber: '18', value: 1900),
      const _TrendPoint(weekday: 'Fri', dayNumber: '19', value: 1400),
      const _TrendPoint(weekday: 'Sat', dayNumber: '20', value: 900),
      const _TrendPoint(weekday: 'Sun', dayNumber: '21', value: 500),
      const _TrendPoint(weekday: 'Mon', dayNumber: '22', value: 0),
    ],
    '1M': [
      const _TrendPoint(weekday: 'Week 1', dayNumber: '', value: 4200),
      const _TrendPoint(weekday: 'Week 2', dayNumber: '', value: 3800),
      const _TrendPoint(weekday: 'Week 3', dayNumber: '', value: 3200),
      const _TrendPoint(weekday: 'Week 4', dayNumber: '', value: 2500),
    ],
    '1Y': [
      const _TrendPoint(weekday: 'Q1', dayNumber: '', value: 4600),
      const _TrendPoint(weekday: 'Q2', dayNumber: '', value: 3400),
      const _TrendPoint(weekday: 'Q3', dayNumber: '', value: 2200),
      const _TrendPoint(weekday: 'Q4', dayNumber: '', value: 1600),
    ],
    'All': [
      const _TrendPoint(weekday: '2019', dayNumber: '', value: 5000),
      const _TrendPoint(weekday: '2020', dayNumber: '', value: 4200),
      const _TrendPoint(weekday: '2021', dayNumber: '', value: 3300),
      const _TrendPoint(weekday: '2022', dayNumber: '', value: 2200),
      const _TrendPoint(weekday: '2023', dayNumber: '', value: 1500),
      const _TrendPoint(weekday: '2024', dayNumber: '', value: 900),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final rangeKey = _ranges[_selectedIndex];
    final dataPoints = _trendData[rangeKey] ?? const <_TrendPoint>[];
    final maxValue = dataPoints.isEmpty
        ? _defaultMaxValue
        : dataPoints.map((point) => point.value).fold<double>(0, max);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RangeTabs(
            ranges: _ranges,
            selectedIndex: _selectedIndex,
            onChanged: (index) => setState(() => _selectedIndex = index),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: _FuelTrendPainter(
                points: dataPoints,
                maxValue: max(_defaultMaxValue, maxValue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({
    required this.ranges,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> ranges;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(ranges.length, (index) {
        final label = ranges[index];
        final isSelected = index == selectedIndex;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onChanged(index),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF7C8596),
          ),
          selectedColor: const Color(0xFF2F3038),
          backgroundColor: const Color(0xFFF4F6FB),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide.none,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }),
    );
  }
}

class _FuelTrendPainter extends CustomPainter {
  _FuelTrendPainter({required this.points, required this.maxValue});

  final List<_TrendPoint> points;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    const leftPadding = 44.0;
    const rightPadding = 16.0;
    const topPadding = 16.0;
    const bottomPadding = 48.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final chartRect = Rect.fromLTWH(
      leftPadding,
      topPadding,
      chartWidth,
      chartHeight,
    );

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x1A3D6DFF), Color(0x333D6DFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect);

    final linePaint = Paint()
      ..color = const Color(0xFF1E53FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final axisPaint = Paint()
      ..color = const Color(0xFFE3E6EF)
      ..strokeWidth = 1;

    final path = Path();
    final offsets = _computeOffsets(chartRect, points);

    path.moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      path.lineTo(offset.dx, offset.dy);
    }

    final areaPath = Path.from(path)
      ..lineTo(offsets.last.dx, chartRect.bottom)
      ..lineTo(offsets.first.dx, chartRect.bottom)
      ..close();

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, linePaint);

    const horizontalSteps = 5;
    final stepValue = maxValue / horizontalSteps;
    for (var i = 0; i <= horizontalSteps; i++) {
      final dy = chartRect.bottom - (chartHeight / horizontalSteps) * i;
      canvas.drawLine(
        Offset(leftPadding, dy),
        Offset(leftPadding + chartWidth, dy),
        axisPaint,
      );

      final labelText = '${(stepValue * i / 1000).round()}k';
      final labelPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF99A1B3),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);
      labelPainter.paint(
        canvas,
        Offset(
          chartRect.left - 12 - labelPainter.width,
          dy - labelPainter.height / 2,
        ),
      );
    }

    for (final point in points.indexed) {
      final index = point.$1;
      final value = point.$2;
      final dx = offsets[index].dx;
      final weekPainter = TextPainter(
        text: TextSpan(
          text: value.weekday,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF99A1B3),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);
      weekPainter.paint(
        canvas,
        Offset(dx - weekPainter.width / 2, chartRect.bottom + 12),
      );
      if (value.dayNumber.isNotEmpty) {
        final dayPainter = TextPainter(
          text: TextSpan(
            text: value.dayNumber,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF323848),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: double.infinity);
        dayPainter.paint(
          canvas,
          Offset(dx - dayPainter.width / 2, chartRect.bottom + 28),
        );
      }
    }
  }

  List<Offset> _computeOffsets(Rect chartRect, List<_TrendPoint> points) {
    if (points.length == 1) {
      final single = points.first;
      final y = _valueToY(chartRect, single.value);
      return [Offset(chartRect.center.dx, y)];
    }

    final step = chartRect.width / (points.length - 1);
    return List.generate(points.length, (index) {
      final x = chartRect.left + step * index;
      final y = _valueToY(chartRect, points[index].value);
      return Offset(x, y);
    });
  }

  double _valueToY(Rect chartRect, double value) {
    final normalized = (value / maxValue).clamp(0.0, 1.0);
    return chartRect.bottom - normalized * chartRect.height;
  }

  @override
  bool shouldRepaint(covariant _FuelTrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.maxValue != maxValue;
  }
}

class _TrendPoint {
  const _TrendPoint({
    required this.weekday,
    required this.dayNumber,
    required this.value,
  });

  final String weekday;
  final String dayNumber;
  final double value;
}
