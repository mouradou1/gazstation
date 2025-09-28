import 'package:flutter/material.dart';

class LoginFormSection extends StatelessWidget {
  const LoginFormSection({
    super.key,
    required this.baseUrlController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
    required this.isLoading,
  });

  final TextEditingController baseUrlController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('URL du serveur', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            controller: baseUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://mon-serveur.com',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 20),
          Text('Username', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 20),
          Text('Mot de passe', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onTogglePasswordVisibility,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Se connecter'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Besoin d’un accès ?', style: theme.textTheme.bodySmall),
              TextButton(onPressed: () {}, child: const Text('Contactez-nous')),
            ],
          ),
        ],
      ),
    );
  }
}
