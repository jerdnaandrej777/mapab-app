import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/account_provider.dart';
import '../../core/supabase/supabase_config.dart';

/// Login Screen mit Email/Passwort und Gast-Modus
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLocalLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLocalLoading = true);

    try {
      await ref.read(accountNotifierProvider.notifier).createGuestAccount();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocalLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final isCloudAvailable = SupabaseConfig.isConfigured;
    final isLoading = authState.isLoading || _isLocalLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                _buildLogo(colorScheme),
                const SizedBox(height: 32),

                // Titel
                Text(
                  'Willkommen bei MapAB',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Dein AI-Reiseplaner für unvergessliche Trips',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Cloud-Login (wenn verfügbar)
                if (isCloudAvailable) ...[
                  _buildCloudLoginForm(theme, colorScheme, authState, isLoading),
                  const SizedBox(height: 24),
                  _buildDivider(theme),
                  const SizedBox(height: 24),
                ],

                // Gast-Modus
                _buildGuestSection(theme, colorScheme, isLoading, isCloudAvailable),

                // Error Message
                if (authState.error != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(colorScheme, authState.error!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.explore,
        size: 64,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildCloudLoginForm(
    ThemeData theme,
    ColorScheme colorScheme,
    AppAuthState authState,
    bool isLoading,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-Mail',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte E-Mail eingeben';
              }
              if (!value.contains('@')) {
                return 'Ungültige E-Mail';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Passwort',
              prefixIcon: const Icon(Icons.lock_outlined),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _signIn(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte Passwort eingeben';
              }
              if (value.length < 6) {
                return 'Mindestens 6 Zeichen';
              }
              return null;
            },
          ),

          const SizedBox(height: 8),

          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : () => context.push('/forgot-password'),
              child: const Text('Passwort vergessen?'),
            ),
          ),

          const SizedBox(height: 16),

          // Login Button
          FilledButton(
            onPressed: isLoading ? null : _signIn,
            child: isLoading && authState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Anmelden'),
          ),

          const SizedBox(height: 12),

          // Register Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Noch kein Konto? ',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              TextButton(
                onPressed: isLoading ? null : () => context.push('/register'),
                child: const Text('Registrieren'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ODER',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGuestSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLoading,
    bool isCloudAvailable,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gast-Button
        OutlinedButton.icon(
          onPressed: isLoading ? null : _continueAsGuest,
          icon: _isLocalLoading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              : const Icon(Icons.person_outline),
          label: const Text('Als Gast fortfahren'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),

        const SizedBox(height: 16),

        // Info-Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCloudAvailable
                      ? 'Als Gast werden deine Daten nur lokal gespeichert und nicht synchronisiert.'
                      : 'Deine Daten werden lokal auf deinem Gerät gespeichert.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(ColorScheme colorScheme, String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: colorScheme.onErrorContainer),
            onPressed: () => ref.read(authNotifierProvider.notifier).clearError(),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
