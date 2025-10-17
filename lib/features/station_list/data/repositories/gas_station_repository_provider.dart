import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gazstation/core/network/api_client_provider.dart';
import 'package:gazstation/features/station_list/data/repositories/remote_gas_station_repository.dart';

import '../../domain/repositories/gas_station_repository.dart';
import 'cached_gas_station_repository.dart';

final gasStationRepositoryProvider = Provider<GasStationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  final remoteRepository = RemoteGasStationRepository(apiClient: apiClient);

  // Wrap the remote repository with the cached repository
  return CachedGasStationRepository(remoteRepository: remoteRepository);
});
