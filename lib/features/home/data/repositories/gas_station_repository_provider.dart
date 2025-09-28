import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gazstation/features/home/data/repositories/remote_gas_station_repository.dart';
import 'package:gazstation/features/home/domain/repositories/gas_station_repository.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_client.dart';
import 'cached_gas_station_repository.dart';

const _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://cld.dzbias.com',
);

final _httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiBaseUrlProvider = StateProvider<String>((ref) => _defaultBaseUrl);

final _apiClientProvider = Provider<ApiClient>((ref) {
  final httpClient = ref.watch(_httpClientProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiClient(httpClient: httpClient, baseUrl: baseUrl);
});

final gasStationRepositoryProvider = Provider<GasStationRepository>((ref) {
  final apiClient = ref.watch(_apiClientProvider);

  final remoteRepository = RemoteGasStationRepository(
    apiClient: apiClient,
  );

  // Wrap the remote repository with the cached repository
  return CachedGasStationRepository(remoteRepository: remoteRepository);
});
