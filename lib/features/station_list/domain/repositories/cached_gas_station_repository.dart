import 'dart:async';

import '../../../fuel_summary/domain/entities/fuel_summary.dart';
import '../../../pumps_dashboard/domain/entities/pump.dart';
import '../entities/gas_station.dart';
import 'gas_station_repository.dart';

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
  Future<List<GasStation>> fetchStationsList({
    bool forceRefresh = false,
  }) async {
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
  Future<GasStation?> fetchStationDetails(
    String id, {
    bool forceRefresh = false,
  }) async {
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
    return remoteRepository.fetchTankById(
      stationId,
      tankId,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<PumpsWithTransactions> fetchPumps(
    String stationId, {
    bool forceRefresh = false,
  }) {
    // Pour l'instant, on ne met pas en cache les pompes, on délègue directement.
    return remoteRepository.fetchPumps(stationId, forceRefresh: forceRefresh);
  }

  // MÉTHODE MANQUANTE AJOUTÉE CI-DESSOUS
  @override
  Future<List<FuelSummary>> fetchFuelSummary(
    String stationId, {
    bool forceRefresh = false,
  }) {
    // On ne met pas en cache pour l'instant
    return remoteRepository.fetchFuelSummary(
      stationId,
      forceRefresh: forceRefresh,
    );
  }
}
