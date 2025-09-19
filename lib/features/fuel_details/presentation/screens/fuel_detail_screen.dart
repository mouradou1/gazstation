import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/home/presentation/providers/gas_stations_providers.dart';
import 'package:gazstation/features/fuel_details/presentation/widgets/fuel_centered_message.dart';
import 'package:gazstation/features/fuel_details/presentation/widgets/fuel_header_card.dart';
import 'package:gazstation/features/fuel_details/presentation/widgets/fuel_summary_table.dart';
import 'package:gazstation/features/station_details/presentation/widgets/tank_snapshot.dart';

class FuelDetailScreen extends ConsumerWidget {
  const FuelDetailScreen({
    super.key,
    required this.stationId,
    required this.fuelId,
  });

  final String stationId;
  final String fuelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tankAsync = ref.watch(
      fuelTankProvider((stationId: stationId, fuelId: fuelId)),
    );
    final appBarTitle = tankAsync.value?.label ?? 'Détails produit';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        elevation: 0,
        toolbarHeight: 84,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            appBarTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: tankAsync.when(
          data: (tank) {
            if (tank == null) {
              return const FuelCenteredMessage(
                title: 'Produit introuvable',
                message:
                    'Impossible de localiser ce carburant pour la station sélectionnée.',
              );
            }
            final summary = tank.summary;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  FuelHeaderCard(
                    label: tank.label,
                    capacity: '${tank.capacityLiters.toStringAsFixed(0)} L',
                    volume: '${tank.currentVolumeLiters.toStringAsFixed(0)} L',
                    height: '${tank.currentHeightCm.toStringAsFixed(0)} mm',
                    lastSync: _formatDate(tank.lastSync),
                  ),
                  const SizedBox(height: 20),
                  FuelSummaryTable(summary: summary),
                  const SizedBox(height: 20),
                  TankSnapshot(
                    tank: tank,
                    onSeeDetails: () {},
                    showSeeDetails: false,
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => FuelCenteredMessage(
            title: 'Erreur',
            message: 'Impossible de charger le carburant.\n$error',
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
