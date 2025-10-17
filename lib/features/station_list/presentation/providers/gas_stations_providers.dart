import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gazstation/features/station_list/data/repositories/gas_station_repository_provider.dart';
import 'package:gazstation/features/fuel_summary/domain/entities/fuel_summary.dart';
import 'package:gazstation/features/station_list/domain/entities/gas_station.dart';

import '../../../pumps_dashboard/domain/entities/pump.dart';


final stationsListProvider = FutureProvider<List<GasStation>>((ref) async {
  final repository = ref.watch(gasStationRepositoryProvider);
  return repository.fetchStationsList();
});

final stationDetailsProvider = FutureProvider.family<GasStation?, String>((
    ref,
    id,
    ) async {
  final repository = ref.watch(gasStationRepositoryProvider);
  return repository.fetchStationDetails(id);
});

final pumpsProvider = FutureProvider.family<List<Pump>, String>((
    ref,
    stationId,
    ) async {
  final repository = ref.watch(gasStationRepositoryProvider);
  return repository.fetchPumps(stationId);
});

// AJOUTEZ CE NOUVEAU PROVIDER
final fuelSummaryProvider = FutureProvider.family<List<FuelSummary>, String>((
    ref,
    stationId,
    ) async {
  final repository = ref.watch(gasStationRepositoryProvider);
  return repository.fetchFuelSummary(stationId);
});
