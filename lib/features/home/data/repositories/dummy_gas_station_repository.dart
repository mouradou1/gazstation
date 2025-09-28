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
  Future<List<GasStation>> fetchStations({bool forceRefresh = false}) {
    return _withDelay(() => dummyStations);
  }

  @override
  Future<GasStation?> fetchStationById(String id, {bool forceRefresh = false}) {
    return _withDelay(() {
      try {
        return dummyStations.firstWhere((station) => station.id == id);
      } on StateError {
        return null;
      }
    });
  }

  @override
  Future<GasStation> fetchStationDetails(String id) async {
    final station = await fetchStationById(id);
    if (station == null) {
      throw StateError('Station not found: $id');
    }
    return station;
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
