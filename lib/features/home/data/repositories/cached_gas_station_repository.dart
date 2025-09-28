import 'dart:async';

import 'package:gazstation/features/home/domain/entities/gas_station.dart';
import 'package:gazstation/features/home/domain/repositories/gas_station_repository.dart';

class CachedGasStationRepository implements GasStationRepository {
  CachedGasStationRepository({required this.remoteRepository});

  final GasStationRepository remoteRepository;

  List<GasStation>? _stationsCache;
  DateTime? _lastFetchTime;

  static const _cacheDuration = Duration(minutes: 5);

  bool get _isCacheValid {
    if (_lastFetchTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  @override
  Future<List<GasStation>> fetchStationsList({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _stationsCache != null) {
      return _stationsCache!;
    }

    final stations = await remoteRepository.fetchStationsList(
      forceRefresh: forceRefresh,
    );
    _stationsCache = stations;
    _lastFetchTime = DateTime.now();
    return stations;
  }

  @override
  Future<GasStation?> fetchStationDetails(String id, {bool forceRefresh = false}) async {
    final station = await remoteRepository.fetchStationDetails(
      id,
      forceRefresh: forceRefresh,
    );

    if (station != null) {
      _stationsCache ??= <GasStation>[];
      final index = _stationsCache!.indexWhere((s) => s.id == id);
      if (index != -1) {
        _stationsCache![index] = station;
      } else {
        _stationsCache!.add(station);
      }
      _lastFetchTime = DateTime.now();
    }

    return station;
  }

  @override
  Future<FuelTank?> fetchTankById(
      String stationId,
      String tankId, {
        bool forceRefresh = false,
      }) {
    // The fetchStationDetails call in the remote repository will be cached,
    // so this indirectly benefits from the cache as well.
    return remoteRepository.fetchTankById(
      stationId,
      tankId,
      forceRefresh: forceRefresh,
    );
  }
}
