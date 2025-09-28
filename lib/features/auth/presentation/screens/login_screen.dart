import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/navigation/app_router.dart';
import 'package:gazstation/core/network/api_client_provider.dart';
import 'package:gazstation/features/auth/presentation/providers/auth_controller.dart';
import 'package:gazstation/features/auth/presentation/widgets/login_form_section.dart';
import 'package:gazstation/features/auth/presentation/widgets/login_header.dart';

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

  @override
  void initState() {
    super.initState();
    _baseUrlController.text = ref.read(apiBaseUrlProvider);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      context.goNamed(AppRoute.stations.name);
      return;
    }

    final errorMessage =
        ref.read(authControllerProvider).errorMessage ??
        'Connexion impossible. Veuillez vérifier vos informations.';
    _showError(errorMessage);
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
                onTogglePasswordVisibility: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSubmit: _handleLogin,
                isLoading: authState.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
