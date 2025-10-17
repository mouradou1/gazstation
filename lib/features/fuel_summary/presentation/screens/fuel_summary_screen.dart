import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/station_list/presentation/providers/gas_stations_providers.dart';
import 'package:gazstation/features/station_details/presentation/widgets/station_centered_message.dart';
import 'package:gazstation/features/fuel_summary/presentation/widgets/fuel_summary_card.dart';

class FuelSummaryScreen extends ConsumerWidget {
  const FuelSummaryScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(fuelSummaryProvider(stationId));

    return Scaffold(
      // Suppression du backgroundColor: const Color(0xFF0F133A)
      // pour utiliser le fond clair par défaut du thème.
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
            'Tableau de bord des cuves',
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
        child: summaryAsync.when(
          data: (summaries) {
            if (summaries.isEmpty) {
              return const StationCenteredMessage(
                title: 'Données indisponibles',
                message: 'Le résumé des cuves n\'est pas disponible.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: summaries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final summary = summaries[index];
                // Le FuelSummaryCard sera mis à jour dans le fichier suivant
                return FuelSummaryCard(summary: summary);
              },
            );
          },
          loading: () => const Center(
            // Changement de la couleur du CircularProgressIndicator
            // pour être visible sur le fond clair.
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => StationCenteredMessage(
            title: 'Erreur',
            message: 'Impossible de charger le résumé.\n$error',
          ),
        ),
      ),
    );
  }
}