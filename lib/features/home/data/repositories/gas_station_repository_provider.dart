import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gazstation/core/network/api_client.dart';
import 'package:gazstation/core/network/repository_error.dart';
import 'package:gazstation/features/home/data/repositories/remote_gas_station_repository.dart';
import 'package:gazstation/features/home/domain/repositories/gas_station_repository.dart';
import 'package:http/http.dart' as http;

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

class RepositoryErrorNotifier extends StateNotifier<RepositoryError?> {
  RepositoryErrorNotifier() : super(null);

  void report(RepositoryError error) {
    state = error;
  }

  void clear() {
    if (state != null) {
      state = null;
    }
  }
}

final repositoryErrorProvider =
    StateNotifierProvider<RepositoryErrorNotifier, RepositoryError?>(
  (ref) => RepositoryErrorNotifier(),
);

final gasStationRepositoryProvider = Provider<GasStationRepository>((ref) {
  final apiClient = ref.watch(_apiClientProvider);
  final errorNotifier = ref.watch(repositoryErrorProvider.notifier);
  return RemoteGasStationRepository(
    apiClient: apiClient,
    errorReporter: errorNotifier.report,
  );
});
