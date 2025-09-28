import 'package:gazstation/core/network/api_client.dart';
import 'package:gazstation/features/auth/data/models/auth_user_dto.dart';
import 'package:gazstation/features/auth/domain/entities/auth_user.dart';
import 'package:gazstation/features/auth/domain/repositories/auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({required this.apiClient, this.basePath = '/api'});

  final ApiClient apiClient;
  final String basePath;

  String get _loginPath => '$basePath/Autho';

  @override
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final response = await apiClient.post(
      _loginPath,
      body: {'NomUtilisateur': username, 'MotDePasse': password},
    );

    final payload = _extractPayload(response);
    final dto = AuthUserDto.fromJson(payload);
    return dto.toDomain();
  }

  Map<String, dynamic> _extractPayload(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is List) {
      for (final item in response) {
        if (item is Map<String, dynamic>) {
          return item;
        }
      }
    }

    throw const FormatException('Unexpected authentication response format');
  }
}
