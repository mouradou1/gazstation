import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/navigation/app_router.dart';
import 'package:gazstation/features/home/domain/entities/gas_station.dart';
import 'package:gazstation/features/station_details/presentation/widgets/fuel_trend_chart_card.dart';
import 'package:gazstation/features/station_details/presentation/widgets/tank_log_tile.dart';
import 'package:gazstation/features/station_details/presentation/widgets/tank_snapshot.dart';

class StationDetailContent extends StatelessWidget {
  const StationDetailContent({
    super.key,
    required this.station,
    required this.selectedTankId,
    required this.onSelectTank,
  });

  final GasStation station;
  final String? selectedTankId;
  final ValueChanged<String> onSelectTank;

  @override
  Widget build(BuildContext context) {
    final tanks = station.tanks;
    String? effectiveTankId = selectedTankId;
    FuelTank? selectedTank;

    if (tanks.isNotEmpty) {
      effectiveTankId ??= tanks.first.id;
      try {
        selectedTank = tanks.firstWhere((tank) => tank.id == effectiveTankId);
      } on StateError {
        effectiveTankId = tanks.first.id;
        selectedTank = tanks.first;
      }
    }

    final fuelTank = selectedTank;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.address,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (tanks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7FB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Aucune cuve disponible pour cette station.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  SizedBox(
                    height: 320,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tanks.length,
                      padding: EdgeInsets.zero,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final tank = tanks[index];
                        return SizedBox(
                          width: 300,
                          child: TankSnapshot(
                            tank: tank,
                            onTap: () => onSelectTank(tank.id),
                            isSelected: tank.id == effectiveTankId,
                            onSeeDetails: () => context.pushNamed(
                              AppRoute.fuelDetail.name,
                              pathParameters: {
                                'stationId': station.id,
                                'fuelId': tank.id,
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (fuelTank != null) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x11000000),
                          offset: Offset(0, 10),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        _PaginatedTankLogs(logs: fuelTank.logs),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const FuelTrendChartCard(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaginatedTankLogs extends StatefulWidget {
  const _PaginatedTankLogs({required this.logs});

  final List<TankLogEntry> logs;

  @override
  State<_PaginatedTankLogs> createState() => _PaginatedTankLogsState();
}

class _PaginatedTankLogsState extends State<_PaginatedTankLogs> {
  static const _itemsPerPage = 5;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.logs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Pas de mouvements enregistrés récemment.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final totalPages = (widget.logs.length / _itemsPerPage).ceil();
    final currentPage = _currentPage < 0
        ? 0
        : (_currentPage >= totalPages ? totalPages - 1 : _currentPage);

    if (currentPage != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentPage = currentPage);
        }
      });
    }

    final startIndex = currentPage * _itemsPerPage;
    final endIndex = math.min(startIndex + _itemsPerPage, widget.logs.length);
    final visibleLogs = widget.logs.sublist(startIndex, endIndex);

    return Column(
      children: [
        ...visibleLogs.asMap().entries.map((entry) {
          final globalIndex = startIndex + entry.key;
          return TankLogTile(
            entry: entry.value,
            showDivider: globalIndex != widget.logs.length - 1,
          );
        }),
        const SizedBox(height: 8),
        if (totalPages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PaginationButton(
                icon: Icons.chevron_left,
                enabled: currentPage > 0,
                onPressed: currentPage > 0
                    ? () => setState(() => _currentPage = currentPage - 1)
                    : null,
              ),
              Text(
                'Page ${currentPage + 1} / $totalPages',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              _PaginationButton(
                icon: Icons.chevron_right,
                enabled: currentPage < totalPages - 1,
                onPressed: currentPage < totalPages - 1
                    ? () => setState(() => _currentPage = currentPage + 1)
                    : null,
              ),
            ],
          ),
      ],
    );
  }
}

class _PaginationButton extends StatelessWidget {
  const _PaginationButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? const Color(0xFFEFF2FA)
            : const Color(0xFFF5F6FA),
        foregroundColor: enabled
            ? const Color(0xFF2F3038)
            : const Color(0xFFB9BFCD),
        minimumSize: const Size(36, 36),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}
