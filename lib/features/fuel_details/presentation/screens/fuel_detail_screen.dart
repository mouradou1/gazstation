import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/station_list/domain/entities/gas_station.dart';
import 'package:gazstation/features/fuel_details/presentation/widgets/fuel_summary_table.dart';
import 'package:gazstation/features/station_details/presentation/widgets/tank_snapshot.dart';

class FuelDetailScreen extends ConsumerWidget {
  const FuelDetailScreen({
    super.key,
    required this.stationId,
    required this.tank,
  });

  final String stationId;
  final FuelTank tank;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBarTitle = tank.label;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            // Le conteneur parent unique
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  offset: Offset(0, 10),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              children: [
                // Section 1: Contenu de l'en-tête
                _buildHeaderContent(context),
                const Divider(height: 1, indent: 20, endIndent: 20),

                // Section 2: Contenu du tableau résumé
                _buildSummaryContent(context),
                const Divider(height: 1, indent: 20, endIndent: 20),

                // Section 3: Snapshot de la cuve sans sa propre décoration
                TankSnapshot(
                  tank: tank,
                  onSeeDetails: () {},
                  showSeeDetails: false,
                  useCardDecoration: false, // Utilisation du nouveau paramètre
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Méthode privée pour construire le contenu de l'en-tête
  Widget _buildHeaderContent(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      child: Column(
        children: [
          Text(
            tank.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricBlock(title: 'Volume (Litre)', value: '${tank.currentVolumeLiters.toStringAsFixed(0)} L'),
              _MetricBlock(title: 'Dernier synchro', value: _formatDate(tank.lastSync)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niveau (litre)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9AA1B0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${tank.currentVolumeLiters.toStringAsFixed(0)} L', style: theme.textTheme.bodyMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Hauteur',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9AA1B0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${tank.currentHeightCm.toStringAsFixed(0)} mm', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Capacité ${tank.capacityLiters.toStringAsFixed(0)} L',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode privée pour construire le contenu du résumé
  Widget _buildSummaryContent(BuildContext context) {
    // Le widget FuelSummaryTable n'a pas de décoration propre,
    // on peut donc l'utiliser directement.
    return FuelSummaryTable(summary: tank.summary);
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

// Classe privée pour remplacer les métriques de FuelHeaderCard
class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF9AA1B0)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
