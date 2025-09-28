import 'package:gazstation/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> login({required String username, required String password});
}
