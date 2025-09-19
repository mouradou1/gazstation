import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/theme/app_theme.dart';
import 'package:gazstation/features/home/presentation/providers/gas_stations_providers.dart';
import 'package:gazstation/features/station_details/presentation/widgets/station_centered_message.dart';
import 'package:gazstation/features/station_details/presentation/widgets/station_detail_content.dart';

class StationDetailScreen extends ConsumerStatefulWidget {
  const StationDetailScreen({super.key, required this.stationId});

  final String stationId;

  @override
  ConsumerState<StationDetailScreen> createState() =>
      _StationDetailScreenState();
}

class _StationDetailScreenState extends ConsumerState<StationDetailScreen> {
  String? _selectedTankId;
  int _selectedRangeIndex = 1; // default to 1W

  @override
  Widget build(BuildContext context) {
    final stationAsync = ref.watch(gasStationProvider(widget.stationId));
    final appBarTitle = stationAsync.value?.name ?? 'Détails station';

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
        child: stationAsync.when(
          data: (station) {
            if (station == null) {
              return const StationCenteredMessage(
                title: 'Station introuvable',
                message: 'Impossible de trouver cette station.',
              );
            }
            return StationDetailContent(
              station: station,
              selectedTankId: _selectedTankId,
              onSelectTank: (value) => setState(() => _selectedTankId = value),
              selectedRangeIndex: _selectedRangeIndex,
              onSelectRange: (value) =>
                  setState(() => _selectedRangeIndex = value),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => StationCenteredMessage(
            title: 'Erreur',
            message: 'Impossible de charger la station.\n$error',
          ),
        ),
      ),
    );
  }
}
