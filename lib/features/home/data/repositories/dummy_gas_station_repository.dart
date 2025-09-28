import 'dart:async';

import 'package:gazstation/features/home/data/dummy_stations.dart';
import 'package:gazstation/features/home/domain/entities/gas_station.dart';
import 'package:gazstation/features/home/domain/repositories/gas_station_repository.dart';

class DummyGasStationRepository implements GasStationRepository {
  DummyGasStationRepository({this.delay = const Duration(milliseconds: 250)});

  final Duration delay;

  Future<T> _withDelay<T>(T Function() body) async {
    if (!delay.isNegative && delay.inMilliseconds > 0) {
      await Future<void>.delayed(delay);
    }
    return body();
  }

  @override
  Future<List<GasStation>> fetchStationsList({bool forceRefresh = false}) {
    return _withDelay(() => dummyStations);
  }

  @override
  Future<GasStation?> fetchStationDetails(
    String id, {
    bool forceRefresh = false,
  }) {
    return _withDelay(() {
      try {
        return dummyStations.firstWhere((station) => station.id == id);
      } on StateError {
        return null;
      }
    });
  }

  @override
  Future<FuelTank?> fetchTankById(
    String stationId,
    String tankId, {
    bool forceRefresh = false,
  }) {
    return _withDelay(() {
      try {
        final station = dummyStations.firstWhere(
          (station) => station.id == stationId,
        );
        return station.tanks.firstWhere((tank) => tank.id == tankId);
      } on StateError {
        return null;
      }
    });
  }
}
