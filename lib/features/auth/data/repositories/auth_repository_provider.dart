import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gazstation/core/network/api_client_provider.dart';
import 'package:gazstation/features/auth/data/repositories/remote_auth_repository.dart';
import 'package:gazstation/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RemoteAuthRepository(apiClient: apiClient);
});
