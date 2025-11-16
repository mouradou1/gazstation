import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/navigation/app_router.dart';
import 'package:gazstation/core/network/api_client_provider.dart';
import 'package:gazstation/features/auth/presentation/providers/auth_controller.dart';
import 'package:gazstation/features/auth/presentation/widgets/login_form_section.dart';
import 'package:gazstation/features/auth/presentation/widgets/login_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _baseUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  static const _rememberMeKey = 'remember_me';
  static const _savedBaseUrlKey = 'saved_base_url';
  static const _savedUsernameKey = 'saved_username';

  @override
  void initState() {
    super.initState();
    _baseUrlController.text = ref.read(apiBaseUrlProvider);
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberMeKey) ?? true;
    final savedBaseUrl = prefs.getString(_savedBaseUrlKey);
    final savedUsername = prefs.getString(_savedUsernameKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _rememberMe = remember;
      if (remember) {
        if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
          _baseUrlController.text = savedBaseUrl;
          final notifier = ref.read(apiBaseUrlProvider.notifier);
          if (notifier.state != savedBaseUrl) {
            notifier.state = savedBaseUrl;
          }
        }
        if (savedUsername != null) {
          _emailController.text = savedUsername;
        }
      }
    });
  }

  Future<void> _persistRememberedCredentials({
    required String baseUrl,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, true);
    await prefs.setString(_savedBaseUrlKey, baseUrl);
    await prefs.setString(_savedUsernameKey, username);
  }

  Future<void> _clearRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, false);
    await prefs.remove(_savedBaseUrlKey);
    await prefs.remove(_savedUsernameKey);
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final baseUrl = _baseUrlController.text.trim();
    final username = _emailController.text.trim();
    final password = _passwordController.text;

    if (baseUrl.isEmpty || username.isEmpty || password.isEmpty) {
      _showError(
        "Veuillez renseigner l'URL du serveur, l'email et le mot de passe.",
      );
      return;
    }

    final notifier = ref.read(apiBaseUrlProvider.notifier);
    if (notifier.state != baseUrl) {
      notifier.state = baseUrl;
    }

    final controller = ref.read(authControllerProvider.notifier);
    controller.resetError();

    final user = await controller.login(username: username, password: password);

    if (!mounted) {
      return;
    }

    if (user != null) {
      if (_rememberMe) {
        await _persistRememberedCredentials(
          baseUrl: baseUrl,
          username: username,
        );
      } else {
        await _clearRememberedCredentials();
      }
      context.goNamed(AppRoute.stations.name);
      return;
    }

    final errorMessage =
        ref.read(authControllerProvider).errorMessage ??
        'Connexion impossible. Veuillez vérifier vos informations.';
    _showError(errorMessage);
  }

  void _toggleRememberMe(bool value) {
    setState(() => _rememberMe = value);
    if (!value) {
      _clearRememberedCredentials();
    }
  }

  void _showError(String message) {
    if (message.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LoginHeader(),
              const SizedBox(height: 32),
              LoginFormSection(
                baseUrlController: _baseUrlController,
                emailController: _emailController,
                passwordController: _passwordController,
                obscurePassword: _obscurePassword,
                rememberMe: _rememberMe,
                onTogglePasswordVisibility: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSubmit: _handleLogin,
                onRememberMeChanged: _toggleRememberMe,
                isLoading: authState.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
