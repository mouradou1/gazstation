import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gazstation/core/navigation/app_router.dart';
import 'package:gazstation/features/auth/presentation/widgets/login_form_section.dart';
import 'package:gazstation/features/auth/presentation/widgets/login_header.dart';
import 'package:gazstation/features/home/data/repositories/gas_station_repository_provider.dart';

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

  void _handleLogin() {
    final baseUrl = _baseUrlController.text.trim();
    if (baseUrl.isNotEmpty) {
      ref.read(apiBaseUrlProvider.notifier).state = baseUrl;
    }
    context.goNamed(AppRoute.stations.name);
  }

  @override
  Widget build(BuildContext context) {
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
