import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:gazstation/core/network/api_client.dart';
import 'package:gazstation/core/network/repository_error.dart';
import 'package:gazstation/features/home/data/models/remote_gas_station_models.dart';
import 'package:gazstation/features/home/domain/entities/gas_station.dart';
import 'package:gazstation/features/home/domain/repositories/gas_station_repository.dart';

class RemoteGasStationRepository implements GasStationRepository {
  RemoteGasStationRepository({
    required this.apiClient,
    this.basePath = '/api',
    this.errorReporter,
  });

  final ApiClient apiClient;
  final String basePath;
  final RepositoryErrorReporter? errorReporter;
  final Set<String> _silencedErrorContexts = <String>{};

  String get _stationsPath => '$basePath/stations';
  String get _stationDetailsPath => '$basePath/Tires';
  String get _tanksPath => '$basePath/cuves';

  List<dynamic> _asList(dynamic data) => data is List ? data : const [];

  bool _hasValue(String? value) => value?.trim().isNotEmpty ?? false;

  @override
  Future<List<GasStation>> fetchStationsList({bool forceRefresh = false}) async {
    final stationsJson = _asList(await apiClient.get(_stationsPath));
    final stations = stationsJson
        .whereType<Map<String, dynamic>>()
        .map(StationDto.fromJson)
        .toList();

    final detailFutures = stations.map(
      (station) => _guard<StationDetailsDto?>(
        () => _fetchStationDetails(station.id),
        null,
        context: 'stationDetailsList(${station.id})',
      ),
    );
    final detailResults = await Future.wait(detailFutures);
    final detailsMap = <int, StationDetailsDto>{
      for (final detail in detailResults)
        if (detail != null) detail.stationId: detail,
    };

    return stations.map((stationDto) {
      final details = detailsMap[stationDto.id];
      final address = _hasValue(details?.address)
          ? details!.address!.trim()
          : _hasValue(stationDto.address)
              ? stationDto.address!.trim()
              : 'Adresse inconnue';

      return GasStation(
        id: stationDto.id.toString(),
        name: stationDto.name,
        address: address,
        alerts: const StationAlerts(
          information: 0,
          warnings: 0,
          critical: 0,
        ),
        tanks: const <FuelTank>[],
      );
    }).toList();
  }

  @override
  Future<GasStation?> fetchStationDetails(
    String id, {
    bool forceRefresh = false,
  }) async {
    final stationId = int.tryParse(id);
    if (stationId == null) {
      developer.log(
        'Invalid station id: $id',
        name: 'RemoteGasStationRepository',
        level: 900,
      );
      return null;
    }

    try {
      final stationsJson = _asList(await apiClient.get(_stationsPath));
      final stations = stationsJson
          .whereType<Map<String, dynamic>>()
          .map(StationDto.fromJson)
          .toList();

      final station = stations.firstWhere((item) => item.id == stationId);
      // _mapStationAsync already guards its internal API calls
      return await _mapStationAsync(station);
    } on StateError {
      return null;
    }
  }

  @override
  Future<FuelTank?> fetchTankById(
    String stationId,
    String tankId, {
    bool forceRefresh = false,
  }) async {
    final station = await fetchStationDetails(
      stationId,
      forceRefresh: forceRefresh,
    );
    if (station == null) {
      return null;
    }

    try {
      return station.tanks.firstWhere((tank) => tank.id == tankId);
    } on StateError {
      return null;
    }
  }

  Future<GasStation> _mapStationAsync(StationDto station) async {
    final detailsFuture = _guard<StationDetailsDto?>(
      () => _fetchStationDetails(station.id),
      null,
      context: 'stationDetails(${station.id})',
    );
    final tanksFuture = _guard<List<TankDto>>(
      () => _fetchTanks(station.id),
      const <TankDto>[],
      context: 'stationTanks(${station.id})',
    );

    final details = await detailsFuture;
    final tanks = await tanksFuture;

    final tankEntities = tanks.map((tank) {
      return _mapTank(
        tank,
        const <TankMovementDto>[],
        const <PumpTransactionDto>[],
      );
    }).toList();

    final criticalTanks = tankEntities
        .where((tank) => tank.fillPercent <= tank.warningThresholdPercent)
        .length;

    final alerts = StationAlerts(
      information: max(tankEntities.length - criticalTanks, 0),
      warnings: criticalTanks,
      critical: 0,
    );

    final address = _hasValue(details?.address)
        ? details!.address!.trim()
        : _hasValue(station.address)
            ? station.address!.trim()
            : 'Adresse inconnue';

    return GasStation(
      id: station.id.toString(),
      name: station.name,
      address: address,
      alerts: alerts,
      tanks: tankEntities,
    );
  }

  Future<StationDetailsDto?> _fetchStationDetails(int stationId) async {
    final response = await apiClient.get(
      _stationDetailsPath,
      queryParameters: {'StationID': stationId},
    );
    final details = _asList(response)
        .whereType<Map<String, dynamic>>()
        .map(StationDetailsDto.fromJson)
        .where((detail) => detail.stationId == stationId)
        .toList();

    if (details.isNotEmpty) {
      return details.first;
    }

    return null;
  }

  Future<List<TankDto>> _fetchTanks(int stationId) async {
    final response = await apiClient.post(
      _tanksPath,
      body: {'StationID': stationId},
    );
    return _asList(
      response,
    ).whereType<Map<String, dynamic>>().map(TankDto.fromJson).toList();
  }

  String _contextKey(String context) {
    final separatorIndex = context.indexOf('(');
    if (separatorIndex == -1) {
      return context;
    }
    return context.substring(0, separatorIndex);
  }

  String? _contextIdentifier(String context) {
    final start = context.indexOf('(');
    if (start == -1) {
      return null;
    }
    final end = context.indexOf(')', start + 1);
    if (end == -1 || end <= start + 1) {
      return null;
    }
    return context.substring(start + 1, end);
  }

  String _contextDescription(String contextKey) {
    switch (contextKey) {
      case 'stationDetails':
        return 'les détails de la station';
      case 'stationDetailsList':
        return 'les détails de la station';
      case 'stationTanks':
        return 'les cuves de la station';
      case 'tankMovements':
        return 'les mouvements de cuve';
      case 'pumpTransactions':
        return 'les transactions de pompe';
      case 'mapStation':
        return 'la station';
      default:
        return 'les données';
    }
  }

  String _apiErrorMessage(ApiException error) {
    final body = error.body;
    if (body == null || body.trim().isEmpty) {
      return 'Code ${error.statusCode}';
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['error'] ?? decoded['message'];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is String && first.trim().isNotEmpty) {
          return first.trim();
        }
      }
    } catch (_) {
      // Ignored: fallback to raw body below.
    }

    return body.trim();
  }

  void _reportError(String context, Object error) {
    final reporter = errorReporter;
    if (reporter == null) {
      return;
    }

    final contextKey = _contextKey(context);
    final identifier = _contextIdentifier(context);
    final target = _contextDescription(contextKey);
    final scope = identifier != null ? '$target (ID $identifier)' : target;

    String title = 'Erreur serveur';
    late final String message;

    if (error is ApiException) {
      final reason = _apiErrorMessage(error);
      final sanitizedReason = reason.isEmpty ? 'Erreur inconnue' : reason;
      message =
          'Impossible de récupérer $scope. (${error.statusCode}) $sanitizedReason';
    } else if (error is TimeoutException) {
      title = 'Temps dépassé';
      message =
          'Le chargement de $scope prend plus de temps que prévu. Veuillez réessayer.';
    } else {
      title = 'Erreur inattendue';
      message = 'Une erreur est survenue lors de la récupération de $scope.';
    }

    reporter(RepositoryError(context: context, title: title, message: message));
  }

  Future<T> _guard<T>(
    Future<T> Function() runner,
    T fallback, {
    required String context,
  }) async {
    final contextKey = _contextKey(context);
    try {
      final result = await runner();
      _silencedErrorContexts.remove(contextKey);
      return result;
    } on ApiException catch (error, stackTrace) {
      developer.log(
        'API error while $context',
        name: 'RemoteGasStationRepository',
        error: error,
        stackTrace: stackTrace,
      );
      final shouldReport = _silencedErrorContexts.add(contextKey);
      if (shouldReport) {
        _reportError(context, error);
      }
      return fallback;
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Timeout while $context',
        name: 'RemoteGasStationRepository',
        error: error,
        stackTrace: stackTrace,
      );
      final shouldReport = _silencedErrorContexts.add(contextKey);
      if (shouldReport) {
        _reportError(context, error);
      }
      return fallback;
    } on Exception catch (error, stackTrace) {
      developer.log(
        'Unexpected error while $context',
        name: 'RemoteGasStationRepository',
        error: error,
        stackTrace: stackTrace,
      );
      final shouldReport = _silencedErrorContexts.add(contextKey);
      if (shouldReport) {
        _reportError(context, error);
      }
      return fallback;
    }
  }

  FuelTank _mapTank(
    TankDto tank,
    List<TankMovementDto> movements,
    List<PumpTransactionDto> transactions,
  ) {
    final capacity = (tank.capacityLiters == null || tank.capacityLiters == 0)
        ? (tank.currentVolume ?? 1)
        : tank.capacityLiters!;
    final warningThreshold =
        (tank.warningThresholdPercent != null &&
            tank.warningThresholdPercent! > 0 &&
            tank.warningThresholdPercent! <= 1)
        ? tank.warningThresholdPercent!
        : 0.1;

    final logs = _buildLogEntries(movements, tank, transactions);
    final lastLog = logs.isNotEmpty ? logs.first : null;

    final currentVolume = tank.currentVolume ?? lastLog?.volumeLiters ?? 0;
    final currentHeight = tank.currentHeight ?? lastLog?.heightCm ?? 0;
    final lastSync = _resolveLastSync(tank, movements, logs);

    final summary = _buildSummary(logs);

    return FuelTank(
      id: (tank.localId ?? tank.id).toString(),
      label: tank.label,
      capacityLiters: capacity,
      currentVolumeLiters: currentVolume,
      currentHeightCm: currentHeight,
      lastSync: lastSync,
      warningThresholdPercent: warningThreshold,
      logs: logs,
      summary: summary,
    );
  }

  List<TankLogEntry> _buildLogEntries(
    List<TankMovementDto> movements,
    TankDto tank,
    List<PumpTransactionDto> transactions,
  ) {
    if (movements.isEmpty && transactions.isEmpty) {
      return const <TankLogEntry>[];
    }

    final sortedMovements = [...movements]
      ..sort((a, b) {
        final aDate = a.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    if (sortedMovements.isNotEmpty) {
      final entries = <TankLogEntry>[];
      for (var index = 0; index < sortedMovements.length; index++) {
        final movement = sortedMovements[index];
        final next = index + 1 < sortedMovements.length
            ? sortedMovements[index + 1]
            : null;

        final volume = movement.valueLiters ?? tank.currentVolume ?? 0;
        final previousVolume = next?.valueLiters ?? volume;
        final variation = volume - previousVolume;
        final height = movement.value ?? tank.currentHeight ?? 0;
        final dateTime = movement.modifiedAt ?? DateTime.now();

        entries.add(
          TankLogEntry(
            dateTime: dateTime,
            volumeLiters: volume,
            heightCm: height,
            variationPercent: variation,
          ),
        );
      }
      return entries;
    }

    final fallbackTransactions = [...transactions]
      ..removeWhere((tx) => tx.dateTime == null)
      ..sort((a, b) => b.dateTime!.compareTo(a.dateTime!));

    return fallbackTransactions
        .map(
          (tx) => TankLogEntry(
            dateTime: tx.dateTime!,
            volumeLiters: tx.volume ?? 0,
            heightCm: tank.currentHeight ?? 0,
            variationPercent: tx.volume ?? 0,
          ),
        )
        .toList();
  }

  DateTime _resolveLastSync(
    TankDto tank,
    List<TankMovementDto> movements,
    List<TankLogEntry> logs,
  ) {
    if (tank.lastSync != null) {
      return tank.lastSync!;
    }

    final latestMovementDate = movements
        .map((movement) => movement.modifiedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (previous, current) => previous == null || current.isAfter(previous)
              ? current
              : previous,
        );

    if (latestMovementDate != null) {
      return latestMovementDate;
    }

    if (logs.isNotEmpty) {
      return logs.first.dateTime;
    }

    return DateTime.now();
  }

  TankSummary _buildSummary(List<TankLogEntry> logs) {
    if (logs.isEmpty) {
      return const TankSummary(
        minVolume: 0,
        maxVolume: 0,
        startVolume: 0,
        endVolume: 0,
        totalDifference: 0,
        totalPurchase: 0,
        totalSale: 0,
      );
    }

    final volumes = logs.map((entry) => entry.volumeLiters).toList();
    final minVolume = volumes.reduce(min);
    final maxVolume = volumes.reduce(max);
    final startVolume = volumes.last;
    final endVolume = volumes.first;
    final totalDifference = endVolume - startVolume;
    final totalPurchase = logs
        .where((entry) => entry.variationPercent >= 0)
        .fold<double>(0, (sum, entry) => sum + entry.variationPercent);
    final totalSale = logs
        .where((entry) => entry.variationPercent < 0)
        .fold<double>(0, (sum, entry) => sum + entry.variationPercent.abs());

    return TankSummary(
      minVolume: minVolume,
      maxVolume: maxVolume,
      startVolume: startVolume,
      endVolume: endVolume,
      totalDifference: totalDifference,
      totalPurchase: totalPurchase,
      totalSale: totalSale,
    );
  }
}
