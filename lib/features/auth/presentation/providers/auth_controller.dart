import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gazstation/core/network/api_client.dart';
import 'package:gazstation/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:gazstation/features/auth/domain/entities/auth_user.dart';
import 'package:gazstation/features/auth/domain/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticating, authenticated, failure }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.authenticating;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    Object? user = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user == _sentinel ? this.user : user as AuthUser?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const _sentinel = Object();
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref);
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState());

  final Ref _ref;

  AuthRepository get _repository => _ref.read(authRepositoryProvider);

  Future<AuthUser?> login({
    required String username,
    required String password,
  }) async {
    if (state.isLoading) {
      return null;
    }

    state = state.copyWith(
      status: AuthStatus.authenticating,
      user: null,
      errorMessage: null,
    );

    try {
      final user = await _repository.login(
        username: username,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      );
      return user;
    } on ApiException catch (error) {
      state = state.copyWith(
        status: AuthStatus.failure,
        user: null,
        errorMessage: _mapApiError(error),
      );
    } on FormatException catch (error) {
      state = state.copyWith(
        status: AuthStatus.failure,
        user: null,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.failure,
        user: null,
        errorMessage:
            'Impossible de se connecter pour le moment. Veuillez réessayer.',
      );
    }

    return null;
  }

  void resetError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  void logout() {
    state = const AuthState();
  }

  String _mapApiError(ApiException error) {
    switch (error.statusCode) {
      case 401:
      case 403:
        return 'Identifiants incorrects. Veuillez vérifier vos informations.';
      case 404:
        return "Service d'authentification introuvable. Vérifiez l'URL du serveur.";
      default:
        return 'La connexion a échoué (code ${error.statusCode}).';
    }
  }
}
