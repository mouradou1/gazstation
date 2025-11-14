import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/station_list/presentation/providers/gas_stations_providers.dart';
import 'package:gazstation/features/station_details/presentation/widgets/station_centered_message.dart';
// Nous allons créer ce widget juste après
import 'package:gazstation/features/pumps_dashboard/presentation/widgets/pumps_list.dart';

class PumpsDashboardScreen extends ConsumerWidget {
  const PumpsDashboardScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pumpsAsync = ref.watch(pumpsProvider(stationId));

    return Scaffold(
      // Ajout du backgroundColor pour être homogène avec le reste de l'app
      backgroundColor: AppTheme.lightBackground,
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
            'Visualisation des Pompes',
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
        child: pumpsAsync.when(
          data: (data) {
            if (data.pumps.isEmpty) {
              return const StationCenteredMessage(
                title: 'Aucune pompe trouvée',
                message: 'Aucune pompe n\'est disponible pour cette station.',
              );
            }
            // Ce widget (PumpsList) sera mis à jour au prochain tour
            return PumpsList(
              pumps: data.pumps,
              transactions: data.transactions,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => StationCenteredMessage(
            title: 'Erreur',
            message: 'Impossible de charger les données des pompes.\n$error',
          ),
        ),
      ),
    );
  }
}
