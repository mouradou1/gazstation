import 'package:flutter/material.dart';
import 'package:gazstation/core/theme/app_theme.dart';

class FuelTrendChartCard extends StatefulWidget {
  const FuelTrendChartCard({super.key});

  @override
  State<FuelTrendChartCard> createState() => _FuelTrendChartCardState();
}

class _FuelTrendChartCardState extends State<FuelTrendChartCard> {
  int _selectedIndex = 1;
  static const _ranges = ['24H', '1W', '1M', '1Y', 'All'];

  @override
  Widget build(BuildContext context) {
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
            height: 160,
            child: CustomPaint(
              painter: _FuelTrendPainter(),
              size: const Size(double.infinity, double.infinity),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: ranges.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isSelected = index == selectedIndex;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onChanged(index),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF7C8596),
            ),
            selectedColor: AppTheme.navy,
            backgroundColor: const Color(0xFFF1F2F7),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.transparent,
              ),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    );
  }
}

class _FuelTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final areaPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x1A3D6DFF), Color(0x333D6DFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = const Color(0xFF1E53FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final axisPaint = Paint()
      ..color = const Color(0xFFE3E6EF)
      ..strokeWidth = 1;

    final path = Path();
    final points = _samplePoints(size);
    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final areaPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, linePaint);

    for (int i = 1; i <= 4; i++) {
      final dy = size.height * i / 5;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), axisPaint);
    }
  }

  List<Offset> _samplePoints(Size size) {
    final width = size.width;
    final height = size.height;
    return [
      Offset(0, height * 0.05),
      Offset(width * 0.18, height * 0.3),
      Offset(width * 0.36, height * 0.5),
      Offset(width * 0.6, height * 0.65),
      Offset(width * 0.82, height * 0.8),
      Offset(width, height * 0.9),
    ];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
