import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gazstation/core/utils/formatters.dart';
import 'package:gazstation/features/station_list/domain/entities/gas_station.dart';

class FuelTrendChartCard extends StatefulWidget {
  const FuelTrendChartCard({super.key, required this.logs});

  final List<TankLogEntry> logs;

  @override
  State<FuelTrendChartCard> createState() => _FuelTrendChartCardState();
}

class _FuelTrendChartCardState extends State<FuelTrendChartCard> {
  static const _ranges = ['24H', '1W', '1M', '1Y', 'All'];
  static const _defaultMaxValue = 5000.0;

  int _selectedRangeIndex = 1;
  int? _touchedIndex; // Pour gérer l'interaction tactile
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
    if (_ranges.isEmpty) return;
    final currentKey = _ranges[_selectedRangeIndex];
    if (_trendData[currentKey]?.isNotEmpty ?? false) return;

    for (var index = 0; index < _ranges.length; index++) {
      final key = _ranges[index];
      if (_trendData[key]?.isNotEmpty ?? false) {
        _selectedRangeIndex = index;
        return;
      }
    }
    _selectedRangeIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final rangeKey = _ranges[_selectedRangeIndex];
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
          // CORRECTION ICI : Utilisation de Wrap au lieu de Row
          // Cela permet aux onglets de passer à la ligne si l'écran est trop étroit
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,    // Espace horizontal entre le titre et les tabs
            runSpacing: 12.0, // Espace vertical si ça passe à la ligne
            children: [
              Text(
                'Évolution du stock',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _RangeTabs(
                ranges: _ranges,
                selectedIndex: _selectedRangeIndex,
                enabled: rangeAvailability,
                onChanged: (index) => setState(() {
                  _selectedRangeIndex = index;
                  _touchedIndex = null; // Reset selection on change
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: dataPoints.isEmpty
                ? const _EmptyTrendPlaceholder()
                : LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanUpdate: (details) => _onTouch(details.localPosition, constraints.maxWidth, dataPoints.length),
                  onTapDown: (details) => _onTouch(details.localPosition, constraints.maxWidth, dataPoints.length),
                  onPanEnd: (_) => setState(() => _touchedIndex = null),
                  onTapUp: (_) => setState(() => _touchedIndex = null),
                  child: CustomPaint(
                    painter: _FuelTrendPainter(
                      points: dataPoints,
                      maxValue: max(_defaultMaxValue, maxValue),
                      touchedIndex: _touchedIndex,
                    ),
                    size: Size(constraints.maxWidth, 220),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onTouch(Offset localPosition, double width, int pointsLength) {
    if (pointsLength == 0) return;

    // Marges définies dans le painter (doivent correspondre)
    const leftPadding = 44.0;
    const rightPadding = 16.0;
    final chartWidth = width - leftPadding - rightPadding;

    // Calcul de l'index relatif à la position X
    final x = localPosition.dx - leftPadding;
    final step = chartWidth / (pointsLength - 1);

    int index = (x / step).round();
    index = index.clamp(0, pointsLength - 1);

    if (_touchedIndex != index) {
      setState(() => _touchedIndex = index);
    }
  }

  // --- Data Building Logic ---
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
    final filtered = _filterByStart(logs, latest.subtract(const Duration(hours: 24)));
    if (filtered.isEmpty) return const <_TrendPoint>[];

    final collapsed = _collapseEntries(filtered, (date) => DateTime(date.year, date.month, date.day, date.hour));
    final buckets = _generateHourlyBuckets(latest, 24);

    return _mapBuckets(
      collapsed,
      buckets,
      primaryLabel: (key) => '${key.hour}h',
      secondaryLabel: (key) => key.day.toString(),
      fullDateLabel: (key) => '${key.day}/${key.month} ${key.hour}h00',
    );
  }

  List<_TrendPoint> _build1wPoints(List<TankLogEntry> logs, DateTime latest) {
    final filtered = _filterByStart(logs, latest.subtract(const Duration(days: 7)));
    if (filtered.isEmpty) return const <_TrendPoint>[];

    final collapsed = _collapseEntries(filtered, (date) => DateTime(date.year, date.month, date.day));
    final buckets = _generateDailyBuckets(latest, 7);

    return _mapBuckets(
      collapsed,
      buckets,
      primaryLabel: (key) => _weekdayLabel(key.weekday),
      secondaryLabel: (key) => key.day.toString(),
      fullDateLabel: (key) => '${_weekdayLabel(key.weekday)} ${key.day}/${key.month}',
    );
  }

  List<_TrendPoint> _build1mPoints(List<TankLogEntry> logs, DateTime latest) {
    final filtered = _filterByStart(logs, latest.subtract(const Duration(days: 30)));
    if (filtered.isEmpty) return const <_TrendPoint>[];

    final collapsed = _collapseEntries(filtered, (date) => DateTime(date.year, date.month, date.day));
    final buckets = _generateDailyBuckets(latest, 30);

    return _mapBuckets(
      collapsed,
      buckets,
      primaryLabel: (key) => key.day.toString(),
      secondaryLabel: (key) => _monthShortLabel(key.month),
      fullDateLabel: (key) => '${key.day} ${_monthShortLabel(key.month)}',
    );
  }

  List<_TrendPoint> _build1yPoints(List<TankLogEntry> logs, DateTime latest) {
    final filtered = _filterByStart(logs, latest.subtract(const Duration(days: 365)));
    if (filtered.isEmpty) return const <_TrendPoint>[];

    final collapsed = _collapseEntries(filtered, (date) => DateTime(date.year, date.month));
    final buckets = _generateMonthlyBuckets(latest, 12);

    return _mapBuckets(
      collapsed,
      buckets,
      primaryLabel: (key) => _monthShortLabel(key.month),
      secondaryLabel: (key) => key.year.toString(),
      fullDateLabel: (key) => '${_monthShortLabel(key.month)} ${key.year}',
    );
  }

  List<_TrendPoint> _buildAllPoints(List<TankLogEntry> logs) {
    if (logs.isEmpty) return const <_TrendPoint>[];
    final oldest = logs.first.dateTime;
    final latest = logs.last.dateTime;

    if (latest.difference(oldest).inDays <= 365) {
      final collapsed = _collapseEntries(logs, (date) => DateTime(date.year, date.month));
      return _mapCollapsedToPoints(collapsed,
        primaryLabel: (key) => _monthShortLabel(key.month),
        secondaryLabel: (key) => key.year.toString(),
        fullDateLabel: (key) => '${_monthShortLabel(key.month)} ${key.year}',
      );
    }

    final collapsed = _collapseEntries(logs, (date) => DateTime(date.year));
    return _mapCollapsedToPoints(collapsed,
      primaryLabel: (key) => key.year.toString(),
      secondaryLabel: (_) => '',
      fullDateLabel: (key) => key.year.toString(),
    );
  }

  // --- Helpers ---
  List<TankLogEntry> _filterByStart(List<TankLogEntry> logs, DateTime start) {
    return logs.where((e) => !e.dateTime.isBefore(start)).toList();
  }

  List<_CollapsedEntry> _collapseEntries(List<TankLogEntry> logs, DateTime Function(DateTime) keyBuilder) {
    final map = <DateTime, TankLogEntry>{};
    for (final entry in logs) {
      map[keyBuilder(entry.dateTime)] = entry;
    }
    final keys = map.keys.toList()..sort();
    return [for (final key in keys) (key: key, entry: map[key]!)];
  }

  List<_TrendPoint> _mapCollapsedToPoints(
      List<_CollapsedEntry> entries, {
        required String Function(DateTime) primaryLabel,
        String Function(DateTime)? secondaryLabel,
        required String Function(DateTime) fullDateLabel,
      }) {
    return [
      for (final item in entries)
        _TrendPoint(
          weekday: primaryLabel(item.key),
          dayNumber: secondaryLabel?.call(item.key) ?? '',
          fullDate: fullDateLabel(item.key),
          value: item.entry.volumeLiters,
        ),
    ];
  }

  List<_TrendPoint> _mapBuckets(
      List<_CollapsedEntry> entries,
      List<DateTime> buckets, {
        required String Function(DateTime) primaryLabel,
        String Function(DateTime)? secondaryLabel,
        required String Function(DateTime) fullDateLabel,
      }) {
    if (entries.isEmpty || buckets.isEmpty) return const <_TrendPoint>[];

    final sortedEntries = [...entries]..sort((a, b) => a.key.compareTo(b.key));
    var entryIndex = 0;
    var lastKnown = sortedEntries.first;
    final result = <_TrendPoint>[];

    for (final bucket in buckets) {
      while (entryIndex < sortedEntries.length && !sortedEntries[entryIndex].key.isAfter(bucket)) {
        lastKnown = sortedEntries[entryIndex];
        entryIndex++;
      }
      final entry = bucket.isBefore(sortedEntries.first.key) ? sortedEntries.first : lastKnown;

      result.add(_TrendPoint(
        weekday: primaryLabel(bucket),
        dayNumber: secondaryLabel?.call(bucket) ?? '',
        fullDate: fullDateLabel(bucket),
        value: entry.entry.volumeLiters,
      ));
    }
    return result;
  }

  // --- Date Generators ---
  String _weekdayLabel(int w) => const ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'][w - 1];
  String _monthShortLabel(int m) => const ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'][m - 1];

  List<DateTime> _generateHourlyBuckets(DateTime latest, int hours) {
    final start = DateTime(latest.year, latest.month, latest.day, latest.hour).subtract(Duration(hours: hours - 1));
    return List.generate(hours, (i) => start.add(Duration(hours: i)));
  }

  List<DateTime> _generateDailyBuckets(DateTime latest, int days) {
    final start = DateTime(latest.year, latest.month, latest.day).subtract(Duration(days: days - 1));
    return List.generate(days, (i) => start.add(Duration(days: i)));
  }

  List<DateTime> _generateMonthlyBuckets(DateTime latest, int months) {
    final start = DateTime(latest.year, latest.month - (months - 1));
    return List.generate(months, (i) => DateTime(start.year, start.month + i));
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.ranges, required this.selectedIndex, required this.onChanged, required this.enabled});
  final List<String> ranges;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<bool> enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 8, // Espace entre les lignes si les onglets passent à la ligne
      children: List.generate(ranges.length, (index) {
        final isSelected = index == selectedIndex;
        final isEnabled = enabled.length > index ? enabled[index] : true;
        return GestureDetector(
          onTap: isEnabled ? () => onChanged(index) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2F3038) : const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              ranges[index],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (isEnabled ? const Color(0xFF7C8596) : const Color(0xFFBDC3CF)),
              ),
            ),
          ),
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF99A1B3)),
      ),
    );
  }
}

typedef _CollapsedEntry = ({DateTime key, TankLogEntry entry});

class _TrendPoint {
  const _TrendPoint({required this.weekday, required this.dayNumber, required this.fullDate, required this.value});
  final String weekday;
  final String dayNumber;
  final String fullDate;
  final double value;
}

class _FuelTrendPainter extends CustomPainter {
  _FuelTrendPainter({required this.points, required this.maxValue, this.touchedIndex});

  final List<_TrendPoint> points;
  final double maxValue;
  final int? touchedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftPadding = 44.0;
    const rightPadding = 16.0;
    const topPadding = 20.0;
    const bottomPadding = 48.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartRect = Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight);

    // 1. Dessiner la grille et les labels Y
    _drawGridAndLabels(canvas, chartRect, chartWidth, chartHeight);

    // 2. Calculer les points (x, y)
    final offsets = _computeOffsets(chartRect, points);

    // 3. Dessiner la courbe lissée
    final linePath = Path();
    if (offsets.length > 1) {
      linePath.moveTo(offsets.first.dx, offsets.first.dy);
      for (int i = 0; i < offsets.length - 1; i++) {
        final p0 = offsets[i];
        final p1 = offsets[i + 1];
        // Lissage simple par spline quadratique
        final controlPoint = Offset((p0.dx + p1.dx) / 2, p0.dy);
        final controlPoint2 = Offset((p0.dx + p1.dx) / 2, p1.dy);
        linePath.cubicTo(controlPoint.dx, controlPoint.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
      }
    } else {
      linePath.moveTo(offsets.first.dx, offsets.first.dy);
      linePath.lineTo(offsets.first.dx, offsets.first.dy);
    }

    // Dégradé sous la courbe
    final areaPath = Path.from(linePath)
      ..lineTo(offsets.last.dx, chartRect.bottom)
      ..lineTo(offsets.first.dx, chartRect.bottom)
      ..close();

    final areaPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, chartRect.top),
        Offset(0, chartRect.bottom),
        [const Color(0xFF1E53FF).withOpacity(0.2), const Color(0xFF1E53FF).withOpacity(0.0)],
      );
    canvas.drawPath(areaPath, areaPaint);

    // Ligne de courbe
    final linePaint = Paint()
      ..color = const Color(0xFF1E53FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // 4. Dessiner les labels X (Dates)
    _drawXLabels(canvas, offsets, chartRect);

    // 5. INTERACTION : Dessiner l'overlay si touché
    if (touchedIndex != null && touchedIndex! < offsets.length) {
      _drawTouchOverlay(canvas, offsets[touchedIndex!], points[touchedIndex!], chartRect);
    }
  }

  void _drawGridAndLabels(Canvas canvas, Rect chartRect, double width, double height) {
    final axisPaint = Paint()..color = const Color(0xFFE3E6EF)..strokeWidth = 1;
    const horizontalSteps = 4;
    final stepValue = maxValue / horizontalSteps;

    for (var i = 0; i <= horizontalSteps; i++) {
      final dy = chartRect.bottom - (height / horizontalSteps) * i;
      // Ligne horizontale
      canvas.drawLine(Offset(chartRect.left, dy), Offset(chartRect.left + width, dy), axisPaint);

      // Label Y
      final labelText = _formatYAxisLabel(stepValue * i);
      final labelPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(fontSize: 10, color: Color(0xFF99A1B3), fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, Offset(chartRect.left - 8 - labelPainter.width, dy - labelPainter.height / 2));
    }
  }

  void _drawXLabels(Canvas canvas, List<Offset> offsets, Rect chartRect) {
    final maxLabels = (chartRect.width / 40).floor();
    final step = (offsets.length / maxLabels).ceil();

    for (var i = 0; i < offsets.length; i += step) {
      final point = points[i];
      final dx = offsets[i].dx;

      final painter = TextPainter(
        text: TextSpan(
          text: '${point.weekday}\n${point.dayNumber}',
          style: const TextStyle(fontSize: 10, color: Color(0xFF99A1B3), height: 1.2),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(canvas, Offset(dx - painter.width / 2, chartRect.bottom + 8));
    }
  }

  void _drawTouchOverlay(Canvas canvas, Offset pos, _TrendPoint data, Rect chartRect) {
    // Ligne verticale (Pointillés manuels pour éviter l'erreur pathEffect)
    final linePaint = Paint()
      ..color = const Color(0xFF1E53FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double dashHeight = 4;
    double dashSpace = 4;
    double startY = chartRect.top;

    while (startY < chartRect.bottom) {
      canvas.drawLine(
        Offset(pos.dx, startY),
        Offset(pos.dx, min(startY + dashHeight, chartRect.bottom)),
        linePaint,
      );
      startY += dashHeight + dashSpace;
    }

    // Point sur la courbe
    final circlePaint = Paint()..color = Colors.white;
    final circleBorder = Paint()..color = const Color(0xFF1E53FF)..strokeWidth = 3..style = PaintingStyle.stroke;

    canvas.drawCircle(pos, 5, circlePaint);
    canvas.drawCircle(pos, 5, circleBorder);

    // Tooltip (Bulle)
    final textSpan = TextSpan(
      children: [
        TextSpan(text: '${data.fullDate}\n', style: const TextStyle(color: Color(0xFFB0B5C1), fontSize: 10, height: 1.4)),
        TextSpan(text: formatLiters(data.value), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );

    final tooltipPainter = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();

    const padding = 12.0;
    final tooltipWidth = tooltipPainter.width + padding * 2;
    final tooltipHeight = tooltipPainter.height + padding;

    // Position intelligente du tooltip
    double tooltipX = pos.dx - tooltipWidth / 2;
    if (tooltipX < chartRect.left) tooltipX = chartRect.left;
    if (tooltipX + tooltipWidth > chartRect.right) tooltipX = chartRect.right - tooltipWidth;

    final tooltipY = pos.dy - tooltipHeight - 10;
    final finalTooltipY = tooltipY < 0 ? pos.dy + 15 : tooltipY;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, finalTooltipY, tooltipWidth, tooltipHeight),
      const Radius.circular(8),
    );

    final bgPaint = Paint()..color = const Color(0xFF1F2431).withOpacity(0.9);
    canvas.drawRRect(rrect, bgPaint);
    tooltipPainter.paint(canvas, Offset(tooltipX + padding, finalTooltipY + padding / 2));
  }

  List<Offset> _computeOffsets(Rect chartRect, List<_TrendPoint> points) {
    if (points.length <= 1) return [Offset(chartRect.center.dx, _valueToY(chartRect, points.first.value))];
    final step = chartRect.width / (points.length - 1);
    return List.generate(points.length, (i) {
      return Offset(chartRect.left + step * i, _valueToY(chartRect, points[i].value));
    });
  }

  double _valueToY(Rect chartRect, double value) {
    final normalized = (value / maxValue).clamp(0.0, 1.0);
    return chartRect.bottom - normalized * chartRect.height;
  }

  String _formatYAxisLabel(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} k';
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _FuelTrendPainter old) {
    return old.points != points || old.touchedIndex != touchedIndex || old.maxValue != maxValue;
  }
}