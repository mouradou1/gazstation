import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gazstation/features/home/domain/entities/gas_station.dart';

class FuelTrendChartCard extends StatefulWidget {
  const FuelTrendChartCard({super.key, required this.logs});

  final List<TankLogEntry> logs;

  @override
  State<FuelTrendChartCard> createState() => _FuelTrendChartCardState();
}

class _FuelTrendChartCardState extends State<FuelTrendChartCard> {
  static const _ranges = ['24H', '1W', '1M', '1Y', 'All'];
  static const _defaultMaxValue = 5000.0;

  int _selectedIndex = 1;
  Map<String, List<_TrendPoint>> _trendData = const {};

  @override
  void initState() {
    super.initState();
    _trendData = _buildTrendData(widget.logs);
    _ensureSelectedRangeHasData();
  }

  @override
  void didUpdateWidget(covariant FuelTrendChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.logs, oldWidget.logs)) {
      _trendData = _buildTrendData(widget.logs);
      _ensureSelectedRangeHasData();
    }
  }

  void _ensureSelectedRangeHasData() {
    if (_ranges.isEmpty) {
      return;
    }
    final currentKey = _ranges[_selectedIndex];
    if (_trendData[currentKey]?.isNotEmpty ?? false) {
      return;
    }
    for (var index = 0; index < _ranges.length; index++) {
      final key = _ranges[index];
      if (_trendData[key]?.isNotEmpty ?? false) {
        _selectedIndex = index;
        return;
      }
    }
    _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final rangeKey = _ranges[_selectedIndex];
    final dataPoints = _trendData[rangeKey] ?? const <_TrendPoint>[];
    final maxValue = dataPoints.isEmpty
        ? _defaultMaxValue
        : dataPoints.map((point) => point.value).fold<double>(0, max);
    final rangeAvailability = List.generate(
      _ranges.length,
      (index) => _trendData[_ranges[index]]?.isNotEmpty ?? false,
    );

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
            enabled: rangeAvailability,
            onChanged: (index) => setState(() => _selectedIndex = index),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: dataPoints.isEmpty
                ? const _EmptyTrendPlaceholder()
                : CustomPaint(
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

  Map<String, List<_TrendPoint>> _buildTrendData(List<TankLogEntry> logs) {
    if (logs.isEmpty) {
      return {for (final range in _ranges) range: const <_TrendPoint>[]};
    }

    final sorted = [...logs]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final latest = sorted.last.dateTime;

    final data = <String, List<_TrendPoint>>{
      '24H': _build24hPoints(sorted, latest),
      '1W': _build1wPoints(sorted, latest),
      '1M': _build1mPoints(sorted, latest),
      '1Y': _build1yPoints(sorted, latest),
      'All': _buildAllPoints(sorted),
    };

    for (final range in _ranges) {
      data.putIfAbsent(range, () => const <_TrendPoint>[]);
    }

    return data;
  }

  List<_TrendPoint> _build24hPoints(List<TankLogEntry> logs, DateTime latest) {
    final filtered = _filterByStart(
      logs,
      latest.subtract(const Duration(hours: 24)),
    );
    if (filtered.isEmpty) {
      return const <_TrendPoint>[];
    }

    final collapsed = _collapseEntries(
      filtered,
      (date) => DateTime(date.year, date.month, date.day, date.hour),
    );

    return _mapCollapsedToPoints(
      collapsed,
      primaryLabel: (key) => '${key.hour.toString().padLeft(2, '0')}h',
      secondaryLabel: (key) => key.day.toString().padLeft(2, '0'),
      maxPoints: 12,
    );
  }

  List<_TrendPoint> _build1wPoints(List<TankLogEntry> logs, DateTime latest) {
    final filtered = _filterByStart(
      logs,
      latest.subtract(const Duration(days: 7)),
    );
    if (filtered.isEmpty) {
      return const <_TrendPoint>[];
    }

    final collapsed = _collapseEntries(
      filtered,
      (date) => DateTime(date.year, date.month, date.day),
    );

    return _mapCollapsedToPoints(
      collapsed,
      primaryLabel: (key) => _weekdayLabel(key.weekday),
      secondaryLabel: (key) => key.day.toString().padLeft(2, '0'),
    );
  }

  List<_TrendPoint> _build1mPoints(List<TankLogEntry> logs, DateTime latest) {
    final filtered = _filterByStart(
      logs,
      latest.subtract(const Duration(days: 30)),
    );
    if (filtered.isEmpty) {
      return const <_TrendPoint>[];
    }

    final collapsed = _collapseEntries(filtered, _startOfWeek);

    return _mapCollapsedToPoints(
      collapsed,
      primaryLabel: (key) => _monthShortLabel(key.month),
      secondaryLabel: (key) => key.day.toString().padLeft(2, '0'),
      maxPoints: 8,
    );
  }

  List<_TrendPoint> _build1yPoints(List<TankLogEntry> logs, DateTime latest) {
    final filtered = _filterByStart(
      logs,
      latest.subtract(const Duration(days: 365)),
    );
    if (filtered.isEmpty) {
      return const <_TrendPoint>[];
    }

    final collapsed = _collapseEntries(
      filtered,
      (date) => DateTime(date.year, date.month),
    );

    return _mapCollapsedToPoints(
      collapsed,
      primaryLabel: (key) => _monthShortLabel(key.month),
      secondaryLabel: (key) => key.year.toString(),
      maxPoints: 12,
    );
  }

  List<_TrendPoint> _buildAllPoints(List<TankLogEntry> logs) {
    if (logs.isEmpty) {
      return const <_TrendPoint>[];
    }

    final oldest = logs.first.dateTime;
    final latest = logs.last.dateTime;
    final totalDays = latest.difference(oldest).inDays;

    if (totalDays <= 365) {
      final collapsed = _collapseEntries(
        logs,
        (date) => DateTime(date.year, date.month),
      );

      return _mapCollapsedToPoints(
        collapsed,
        primaryLabel: (key) => _monthShortLabel(key.month),
        secondaryLabel: (key) => key.year.toString(),
        maxPoints: 12,
      );
    }

    final collapsed = _collapseEntries(logs, (date) => DateTime(date.year));

    return _mapCollapsedToPoints(
      collapsed,
      primaryLabel: (key) => key.year.toString(),
      secondaryLabel: (_) => '',
      maxPoints: 12,
    );
  }

  List<TankLogEntry> _filterByStart(List<TankLogEntry> logs, DateTime start) {
    final result = <TankLogEntry>[];
    for (final entry in logs) {
      if (!entry.dateTime.isBefore(start)) {
        result.add(entry);
      }
    }
    return result;
  }

  List<_CollapsedEntry> _collapseEntries(
    List<TankLogEntry> logs,
    DateTime Function(DateTime) keyBuilder,
  ) {
    if (logs.isEmpty) {
      return const <_CollapsedEntry>[];
    }

    final map = <DateTime, TankLogEntry>{};
    for (final entry in logs) {
      final key = keyBuilder(entry.dateTime);
      map[key] = entry;
    }

    final keys = map.keys.toList()..sort();
    return [for (final key in keys) (key: key, entry: map[key]!)];
  }

  List<_TrendPoint> _mapCollapsedToPoints(
    List<_CollapsedEntry> entries, {
    required String Function(DateTime) primaryLabel,
    String Function(DateTime)? secondaryLabel,
    int? maxPoints,
  }) {
    if (entries.isEmpty) {
      return const <_TrendPoint>[];
    }

    final effectiveEntries = maxPoints != null
        ? _limitEntries(entries, maxPoints)
        : entries;

    return [
      for (final item in effectiveEntries)
        _TrendPoint(
          weekday: primaryLabel(item.key),
          dayNumber: secondaryLabel?.call(item.key) ?? '',
          value: item.entry.volumeLiters,
        ),
    ];
  }

  List<_CollapsedEntry> _limitEntries(
    List<_CollapsedEntry> entries,
    int maxPoints,
  ) {
    if (entries.length <= maxPoints) {
      return entries;
    }
    if (maxPoints <= 1) {
      return [entries.last];
    }

    final limited = <_CollapsedEntry>[];
    final step = (entries.length - 1) / (maxPoints - 1);

    for (var index = 0; index < maxPoints; index++) {
      final position = (index * step).round();
      final boundedIndex = position < entries.length
          ? position
          : entries.length - 1;
      final entry = entries[boundedIndex];
      if (limited.isEmpty || limited.last.key != entry.key) {
        limited.add(entry);
      }
    }

    if (limited.last.key != entries.last.key) {
      limited.add(entries.last);
    }

    final deduplicated = <_CollapsedEntry>[];
    for (final entry in limited) {
      if (deduplicated.isEmpty || deduplicated.last.key != entry.key) {
        deduplicated.add(entry);
      }
    }

    return deduplicated;
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final index = weekday - 1;
    if (index < 0 || index >= labels.length) {
      return 'Day';
    }
    return labels[index];
  }

  String _monthShortLabel(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final index = month - 1;
    if (index < 0 || index >= labels.length) {
      return 'M';
    }
    return labels[index];
  }

  DateTime _startOfWeek(DateTime date) {
    final midnight = DateTime(date.year, date.month, date.day);
    final difference = date.weekday - DateTime.monday;
    return midnight.subtract(Duration(days: difference));
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({
    required this.ranges,
    required this.selectedIndex,
    required this.onChanged,
    required this.enabled,
  });

  final List<String> ranges;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<bool> enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(ranges.length, (index) {
        final label = ranges[index];
        final isSelected = index == selectedIndex;
        final isEnabled = enabled.length > index ? enabled[index] : true;
        final textColor = isSelected
            ? Colors.white
            : (isEnabled ? const Color(0xFF7C8596) : const Color(0xFFBDC3CF));
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: isEnabled ? (_) => onChanged(index) : null,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
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

class _EmptyTrendPlaceholder extends StatelessWidget {
  const _EmptyTrendPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Aucune donnée disponible',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFF99A1B3)),
      ),
    );
  }
}

typedef _CollapsedEntry = ({DateTime key, TankLogEntry entry});

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
