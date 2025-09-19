import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gazstation/features/home/data/repositories/gas_station_repository_provider.dart';
import 'package:gazstation/features/home/domain/entities/gas_station.dart';

final gasStationsProvider = FutureProvider<List<GasStation>>((ref) async {
  final repository = ref.watch(gasStationRepositoryProvider);
  return repository.fetchStations();
});

final gasStationProvider = FutureProvider.family<GasStation?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(gasStationRepositoryProvider);
  return repository.fetchStationById(id);
});

final fuelTankProvider =
    FutureProvider.family<FuelTank?, ({String stationId, String fuelId})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(gasStationRepositoryProvider);
      return repository.fetchTankById(params.stationId, params.fuelId);
    });
