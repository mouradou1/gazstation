import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gazstation/features/home/data/repositories/gas_station_repository_provider.dart';
import 'package:gazstation/features/home/domain/entities/gas_station.dart';

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
