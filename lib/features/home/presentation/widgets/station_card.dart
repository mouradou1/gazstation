import 'package:flutter/material.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/home/domain/entities/gas_station.dart';

class StationCard extends StatelessWidget {
  const StationCard({super.key, required this.station, required this.onTap});

  final GasStation station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badges = _AlertBadges(alerts: station.alerts);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3D6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.local_gas_station,
                      color: AppTheme.navy,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          station.address,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF707A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  badges,
                ],
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.navy,
                    textStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  label: const Text('Voir les détails'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBadges extends StatelessWidget {
  const _AlertBadges({required this.alerts});

  final StationAlerts alerts;

  @override
  Widget build(BuildContext context) {
    final items = <_AlertBadgeData>[
      _AlertBadgeData(
        count: alerts.information,
        icon: Icons.info_outline_rounded,
        color: const Color(0xFF4F8EF7),
      ),
      _AlertBadgeData(
        count: alerts.warnings,
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFF7C749),
      ),
      _AlertBadgeData(
        count: alerts.critical,
        icon: Icons.report_problem_rounded,
        color: const Color(0xFFE74C3C),
      ),
    ].where((item) => item.count > 0).toList();

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF52B788),
          size: 22,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AlertBadge(data: item),
          ),
      ],
    );
  }
}

class _AlertBadgeData {
  const _AlertBadgeData({
    required this.count,
    required this.icon,
    required this.color,
  });

  final int count;
  final IconData icon;
  final Color color;
}

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.data});

  final _AlertBadgeData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          Positioned(
            right: -6,
            top: -8,
            child: CircleAvatar(
              radius: 11,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: data.color,
                child: Text(
                  '${data.count}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
