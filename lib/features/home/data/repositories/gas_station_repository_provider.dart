import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gazstation/features/home/data/repositories/dummy_gas_station_repository.dart';
import 'package:gazstation/features/home/domain/repositories/gas_station_repository.dart';

final gasStationRepositoryProvider = Provider<GasStationRepository>((ref) {
  return DummyGasStationRepository();
});
