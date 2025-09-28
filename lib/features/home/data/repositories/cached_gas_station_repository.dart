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
  Future<List<GasStation>> fetchStations({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _stationsCache != null) {
      return _stationsCache!;
    }

    final stations = await remoteRepository.fetchStations(forceRefresh: forceRefresh);
    _stationsCache = stations;
    _lastFetchTime = DateTime.now();
    return stations;
  }

  @override
  Future<GasStation?> fetchStationById(String id, {bool forceRefresh = false}) async {
    // Prefer returning a fully-detailed station. If cache is present and looks
    // detailed (has at least one tank), return it; otherwise fetch details.
    if (!forceRefresh && _isCacheValid && _stationsCache != null) {
      try {
        final cached = _stationsCache!.firstWhere((station) => station.id == id);
        if (cached.tanks.isNotEmpty) {
          return cached;
        }
        // Fall through to fetch full details below if lightweight.
      } on StateError {
        // Not in cache, will fetch from remote below
      }
    }

    // Delegate to remote which returns full details, then update cache.
    final station = await remoteRepository.fetchStationById(id, forceRefresh: forceRefresh);
    if (station != null) {
      // Update cache
      _stationsCache ??= [];
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
  Future<GasStation> fetchStationDetails(String id) async {
    // Always fetch full details from remote, then update the cache
    final station = await remoteRepository.fetchStationDetails(id);

    // Update or insert into cache
    _stationsCache ??= <GasStation>[];
    final index = _stationsCache!.indexWhere((s) => s.id == id);
    if (index != -1) {
      _stationsCache![index] = station;
    } else {
      _stationsCache!.add(station);
    }
    _lastFetchTime = DateTime.now();

    return station;
  }

  @override
  Future<FuelTank?> fetchTankById(
      String stationId,
      String tankId, {
        bool forceRefresh = false,
      }) {
    // The fetchStationById call in the remote repository will be cached,
    // so this indirectly benefits from the cache as well.
    return remoteRepository.fetchTankById(stationId, tankId, forceRefresh: forceRefresh);
  }
}
