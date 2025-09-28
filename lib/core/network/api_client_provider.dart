import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

const _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://cld.dzbias.com',
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiBaseUrlProvider = StateProvider<String>((ref) => _defaultBaseUrl);

final apiClientProvider = Provider<ApiClient>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiClient(httpClient: httpClient, baseUrl: baseUrl);
});
