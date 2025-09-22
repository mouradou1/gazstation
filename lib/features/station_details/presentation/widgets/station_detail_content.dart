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
                        if (fuelTank.logs.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Pas de mouvements enregistrés récemment.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        else
                          ...fuelTank.logs.asMap().entries.map(
                            (entry) => TankLogTile(
                              entry: entry.value,
                              showDivider:
                                  entry.key != fuelTank.logs.length - 1,
                            ),
                          ),
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
