import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:gazstation/core/network/api_client.dart';
import 'package:gazstation/core/network/repository_error.dart';

import '../../../fuel_summary/domain/entities/fuel_summary.dart';
import '../../../pumps_dashboard/data/models/pump_dto.dart';
import '../../../pumps_dashboard/data/models/volet_dto.dart';
import '../../../pumps_dashboard/domain/entities/pump.dart';
import '../../domain/entities/gas_station.dart';
import '../../domain/repositories/gas_station_repository.dart';
import '../models/remote_gas_station_models.dart';

typedef PumpsWithTransactions = ({
List<Pump> pumps,
List<PumpTransactionDto> transactions,
});

class RemoteGasStationRepository implements GasStationRepository {
  RemoteGasStationRepository({
    required this.apiClient,
    this.basePath = '/api',
    this.errorReporter,
    this.tankMovementsCacheDuration = const Duration(minutes: 10),
  });

  final ApiClient apiClient;
  final String basePath;
  final RepositoryErrorReporter? errorReporter;
  final Duration tankMovementsCacheDuration;
  final Set<String> _silencedErrorContexts = <String>{};
  final Map<int, _TankMovementsCacheEntry> _tankMovementsCache =
  <int, _TankMovementsCacheEntry>{};
  final Map<int, Future<List<TankMovementDto>>> _pendingTankMovements =
  <int, Future<List<TankMovementDto>>>{};

  String get _stationsPath => '$basePath/stations';
  String get _tanksPath => '$basePath/cuves';
  String get _tankMovementsPath => '$basePath/MTcuves';
  String get _pumpsPath => '$basePath/pump2';
  String get _voletsPath => '$basePath/volets';
  String get _pumpTransactionsPath => '$basePath/pump';

  // Nouveaux endpoints pour le calcul théorique
  String get _purchaseSumPath => '$basePath/ligneAchat/somme';
  String get _salesSumPath => '$basePath/pump/volume';

  List<dynamic> _asList(dynamic data) => data is List ? data : const [];

  bool _hasValue(String? value) => value?.trim().isNotEmpty ?? false;

  @override
  Future<List<GasStation>> fetchStationsList({
    bool forceRefresh = false,
  }) async {
    final stationsJson = _asList(await apiClient.get(_stationsPath));
    final stations = stationsJson
        .whereType<Map<String, dynamic>>()
        .map(StationDto.fromJson)
        .toList();

    return stations.map((stationDto) {
      final address = _hasValue(stationDto.address)
          ? stationDto.address!.trim()
          : 'Adresse inconnue';

      return GasStation(
        id: stationDto.id.toString(),
        name: stationDto.name,
        address: address,
        alerts: const StationAlerts(information: 0, warnings: 0, critical: 0),
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
      return await _mapStationAsync(station, forceRefresh: forceRefresh);
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

  @override
  Future<PumpsWithTransactions> fetchPumps(
      String stationId, {
        bool forceRefresh = false,
      }) async {
    final stationIdInt = int.tryParse(stationId);
    if (stationIdInt == null) {
      return (
      pumps: const <Pump>[],
      transactions: const <PumpTransactionDto>[],
      );
    }

    final pumpsFuture = _fetchPumps(stationIdInt);
    final voletsFuture = _fetchVolets(stationIdInt);
    final transactionsFuture = _fetchPumpTransactions(stationIdInt);

    final results = await Future.wait([
      pumpsFuture,
      voletsFuture,
      transactionsFuture,
    ]);

    final pumps = results[0] as List<PumpDto>;
    final volets = results[1] as List<VoletDto>;
    final transactions = results[2] as List<PumpTransactionDto>;

    final nozzlesByPumpId = <int, List<Nozzle>>{};
    for (final volet in volets) {
      final nozzle = Nozzle(
        id: volet.id,
        label: volet.label,
        fuelType: volet.type,
        volume: volet.volume,
      );
      (nozzlesByPumpId[volet.pumpId] ??= []).add(nozzle);
    }

    final pumpEntities = pumps.map((pumpDto) {
      final pumpKey = pumpDto.localId ?? pumpDto.id;
      return Pump(
        id: pumpDto.id,
        label: pumpDto.label,
        nozzles: nozzlesByPumpId[pumpKey] ?? const <Nozzle>[],
      );
    }).toList();

    return (pumps: pumpEntities, transactions: transactions);
  }

  // --- MODIFICATION MAJEURE ICI POUR LE RÉSUMÉ CARBURANT ---
  @override
  Future<List<FuelSummary>> fetchFuelSummary(
      String stationId, {
        bool forceRefresh = false,
      }) async {
    final stationIdInt = int.tryParse(stationId);
    if (stationIdInt == null) {
      return const <FuelSummary>[];
    }

    // 1. Récupérer uniquement les cuves (plus besoin des mouvements pour le stock initial)
    final tanks = await _fetchTanks(stationIdInt);

    // 2. Définir les types stricts demandés (1=DZL, 2=ESS, 3=GPL)
    final fuelTypes = [
      (typeId: 1, name: 'DZL'),
      (typeId: 2, name: 'ESS'),
      (typeId: 3, name: 'GPL'),
    ];

    final summaries = <FuelSummary>[];

    for (final fuelType in fuelTypes) {
      final typeId = fuelType.typeId;
      final typeName = fuelType.name;

      // A. Calculer le Réel (Somme des cuves correspondantes)
      double totalRealVolume = 0.0;
      double totalCapacity = 0.0;

      // Filtrer les cuves qui correspondent à ce type
      final matchingTanks = tanks.where((t) => _isTankOfType(t, typeId)).toList();

      for (final tank in matchingTanks) {
        totalRealVolume += tank.currentVolume ?? 0;
        totalCapacity += tank.capacityLiters ?? 0;
      }

      // B. Récupérer les Achats via API (ligneAchat/somme)
      final purchases = await _fetchTotalPurchases(stationIdInt, typeId);

      // C. Récupérer les Ventes via API (pump/volume)
      final sales = await _fetchTotalSales(stationIdInt, typeId);

      // D. Calculer le Théorique
      // NOUVELLE FORMULE : Total Achats (API) - Total Ventes (API)
      // Note : On clamp à 0 pour l'affichage, au cas où Ventes > Achats
      final theoreticalVolume = (purchases - sales).clamp(0.0, double.infinity);

      // E. Créer le résumé
      summaries.add(FuelSummary(
        fuelTypeName: typeName,
        totalCapacityLiters: totalCapacity,
        realVolumeLiters: totalRealVolume,
        theoreticalVolumeLiters: theoreticalVolume,
      ));
    }

    return summaries;
  }

  // --- NOUVEAUX HELPERS POUR LES API ---

  // Détermine si une cuve appartient au type 1 (DZL), 2 (ESS) ou 3 (GPL)
  bool _isTankOfType(TankDto tank, int targetTypeId) {
    final label = (tank.label).toUpperCase();

    // Logique de mappage basée sur vos indications
    // Type 1 = DZL
    if (targetTypeId == 1) {
      return label.contains('DZ') ||
          label.contains('GASOIL') ||
          label.contains('GAZOIL') ||
          label.contains('DIESEL') ||
          label.contains('GO ');
    }
    // Type 2 = ESS
    if (targetTypeId == 2) {
      return label.contains('ESS') ||
          label.contains('SP') ||
          label.contains('SUPER') ||
          label.contains('SANS PLOMB');
    }
    // Type 3 = GPL
    if (targetTypeId == 3) {
      return label.contains('GPL') || label.contains('SIRGHAZ');
    }

    return false;
  }

  Future<double> _fetchTotalPurchases(int stationId, int type) async {
    try {
      // API: /api/ligneAchat/somme
      final response = await apiClient.post(
        _purchaseSumPath,
        body: {'StationID': stationId, 'type': type},
      );

      // Réponse attendue: { "la_somme_qte": 10000 }
      if (response is Map<String, dynamic>) {
        final val = response['la_somme_qte'];
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      developer.log('Erreur fetchTotalPurchases: $e');
      return 0.0;
    }
  }

  Future<double> _fetchTotalSales(int stationId, int type) async {
    try {
      // API: /api/pump/volume
      final response = await apiClient.post(
        _salesSumPath,
        body: {'StationID': stationId, 'type': type},
      );

      // Réponse attendue: { ..., "la_somme_Volume": 69.99 }
      if (response is Map<String, dynamic>) {
        final val = response['la_somme_Volume'];
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      developer.log('Erreur fetchTotalSales: $e');
      return 0.0;
    }
  }

  // ------------------------------------

  Future<List<PumpDto>> _fetchPumps(int stationId) async {
    final response = await apiClient.post(
      _pumpsPath,
      body: {'StationID': stationId},
    );
    return _asList(
      response,
    ).whereType<Map<String, dynamic>>().map(PumpDto.fromJson).toList();
  }

  Future<List<PumpTransactionDto>> _fetchPumpTransactions(int stationId) async {
    final response = await apiClient.post(
      _pumpTransactionsPath,
      body: {'StationID': stationId},
    );
    return _asList(response)
        .whereType<Map<String, dynamic>>()
        .map(PumpTransactionDto.fromJson)
        .toList();
  }

  Future<List<VoletDto>> _fetchVolets(int stationId) async {
    final response = await apiClient.post(
      _voletsPath,
      body: {'StationID': stationId},
    );
    return _asList(
      response,
    ).whereType<Map<String, dynamic>>().map(VoletDto.fromJson).toList();
  }

  Future<GasStation> _mapStationAsync(
      StationDto station, {
        bool forceRefresh = false,
      }) async {
    final tanksFuture = _guard<List<TankDto>>(
          () => _fetchTanks(station.id),
      const <TankDto>[],
      context: 'stationTanks(${station.id})',
    );
    final movementsFuture = _guard<List<TankMovementDto>>(
          () => _getTankMovementsByStation(station.id, forceRefresh: forceRefresh),
      const <TankMovementDto>[],
      context: 'tankMovements(${station.id})',
    );
    final transactionsFuture = _guard<List<PumpTransactionDto>>(
          () => _fetchPumpTransactions(station.id),
      const <PumpTransactionDto>[],
      context: 'pumpTransactions(${station.id})',
    );

    final tanks = await tanksFuture;
    final movements = await movementsFuture;
    final transactions = await transactionsFuture;

    final tankEntities = tanks.map((tank) {
      final tankMovements = _filterMovementsForTank(movements, tank);
      final tankTransactions = transactions
          .where((tx) => tx.tankId == (tank.localId ?? tank.id))
          .toList();
      return _mapTank(tank, tankMovements, tankTransactions);
    }).toList();

    final criticalTanks = tankEntities
        .where((tank) => tank.fillPercent <= tank.warningThresholdPercent)
        .length;

    final alerts = StationAlerts(
      information: max(tankEntities.length - criticalTanks, 0),
      warnings: criticalTanks,
      critical: 0,
    );

    final address = _hasValue(station.address)
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

  Future<List<TankDto>> _fetchTanks(int stationId) async {
    final response = await apiClient.post(
      _tanksPath,
      body: {'StationID': stationId},
    );
    return _asList(
      response,
    ).whereType<Map<String, dynamic>>().map(TankDto.fromJson).toList();
  }

  Future<List<TankMovementDto>> _getTankMovementsByStation(
      int stationId, {
        bool forceRefresh = false,
      }) async {
    if (forceRefresh) {
      _invalidateTankMovementsCache(stationId);
    }

    final cached = _tankMovementsCache[stationId];
    if (cached != null && !_isTankMovementsCacheExpired(cached)) {
      return cached.movements;
    }

    if (!forceRefresh) {
      final pending = _pendingTankMovements[stationId];
      if (pending != null) {
        return pending;
      }
    }

    final fetchFuture = _downloadTankMovements(stationId);
    _pendingTankMovements[stationId] = fetchFuture;

    try {
      final movements = await fetchFuture;
      _tankMovementsCache[stationId] = _TankMovementsCacheEntry(
        fetchedAt: DateTime.now(),
        movements: movements,
      );
      return movements;
    } finally {
      _pendingTankMovements.remove(stationId);
    }
  }

  Future<List<TankMovementDto>> _downloadTankMovements(int stationId) async {
    final response = await apiClient.post(
      _tankMovementsPath,
      body: {'StationID': stationId},
    );

    final movements = _asList(response)
        .whereType<Map<String, dynamic>>()
        .map(TankMovementDto.fromJson)
        .where((movement) {
      if (movement.stationId == null) {
        return true;
      }
      return movement.stationId == stationId;
    })
        .toList();

    return List.unmodifiable(movements);
  }

  bool _isTankMovementsCacheExpired(_TankMovementsCacheEntry entry) {
    final age = DateTime.now().difference(entry.fetchedAt);
    return age >= tankMovementsCacheDuration;
  }

  void _invalidateTankMovementsCache(int stationId) {
    _tankMovementsCache.remove(stationId);
    _pendingTankMovements.remove(stationId);
  }

  List<TankMovementDto> _filterMovementsForTank(
      List<TankMovementDto> movements,
      TankDto tank,
      ) {
    if (movements.isEmpty) {
      return const <TankMovementDto>[];
    }

    final keys = <int>{if (tank.localId != null) tank.localId!, tank.id};

    return movements
        .where(
          (movement) =>
      movement.tankLocalId != null &&
          keys.contains(movement.tankLocalId!),
    )
        .toList();
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
    } catch (_) {}

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
    final capacity = (tank.capacityLiters == null || tank.capacityLiters! <= 0)
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
      entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return entries;
    }

    // Aucun mouvement disponible : on retourne une ligne plate avec le volume courant
    final now = DateTime.now();
    final baseVolume = tank.currentVolume ?? 0;
    final baseHeight = tank.currentHeight ?? 0;
    final fallbackTransactions = [...transactions]
      ..removeWhere((tx) => tx.dateTime == null)
      ..sort((a, b) => a.dateTime!.compareTo(b.dateTime!));

    if (fallbackTransactions.isNotEmpty) {
      return fallbackTransactions
          .map(
            (tx) => TankLogEntry(
          dateTime: tx.dateTime!,
          volumeLiters: tx.totalVolume ?? tx.volume ?? baseVolume,
          heightCm: tank.currentHeight ?? 0,
          variationPercent: tx.volume ?? 0,
        ),
      )
          .toList();
    }

    return [
      TankLogEntry(
        dateTime: now.subtract(const Duration(days: 1)),
        volumeLiters: baseVolume,
        heightCm: baseHeight,
        variationPercent: 0,
      ),
      TankLogEntry(
        dateTime: now,
        volumeLiters: baseVolume,
        heightCm: baseHeight,
        variationPercent: 0,
      ),
    ];
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

class _TankMovementsCacheEntry {
  _TankMovementsCacheEntry({required this.fetchedAt, required this.movements});

  final DateTime fetchedAt;
  final List<TankMovementDto> movements;
}