import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/features/home/presentation/providers/gas_stations_providers.dart';
import 'package:gazstation/features/fuel_details/presentation/widgets/fuel_centered_message.dart';
import 'package:gazstation/features/fuel_details/presentation/widgets/fuel_metric_block.dart';
import 'package:gazstation/features/fuel_details/presentation/widgets/fuel_tank_gauge.dart';
import 'package:gazstation/features/fuel_details/presentation/widgets/fuel_threshold_row.dart';
import 'package:gazstation/core/theme/app_theme.dart';

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
        title: Text(appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
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
            final theme = Theme.of(context);
            final summary = tank.summary;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tank.label, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FuelMetricBlock(
                                label: 'Volume (litre)',
                                value:
                                    '${tank.currentVolumeLiters.toStringAsFixed(0)} L',
                              ),
                            ),
                            Expanded(
                              child: FuelMetricBlock(
                                label: 'Niveau',
                                value:
                                    '${tank.currentHeightCm.toStringAsFixed(0)} mm',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        FuelThresholdRow(
                          label: 'Min',
                          value: '${summary.minVolume.toStringAsFixed(0)} L',
                          icon: Icons.arrow_downward,
                          color: const Color(0xFFE57373),
                        ),
                        FuelThresholdRow(
                          label: 'Max',
                          value: '${summary.maxVolume.toStringAsFixed(0)} L',
                          icon: Icons.arrow_upward,
                          color: const Color(0xFF66BB6A),
                        ),
                        FuelThresholdRow(
                          label: 'Commencer par',
                          value: '${summary.startVolume.toStringAsFixed(0)} L',
                          icon: Icons.play_arrow_rounded,
                          color: AppTheme.navy,
                        ),
                        FuelThresholdRow(
                          label: 'Terminer',
                          value: '${summary.endVolume.toStringAsFixed(0)} L',
                          icon: Icons.flag_rounded,
                          color: AppTheme.gold,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F7FB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'La différence',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${summary.totalDifference.toStringAsFixed(0)} L',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Le total est entre le 23/05/2024 09:41 et le 24/05/2024 09:41',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: FuelMetricBlock(
                                label: 'Achat',
                                value:
                                    '${summary.totalPurchase.toStringAsFixed(0)} L',
                              ),
                            ),
                            Expanded(
                              child: FuelMetricBlock(
                                label: 'Vente',
                                value:
                                    '${summary.totalSale.toStringAsFixed(0)} L',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        FuelTankGauge(percent: tank.fillPercent),
                      ],
                    ),
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
