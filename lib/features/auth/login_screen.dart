import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/account_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/l10n/l10n.dart';

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
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    // Gespeicherte Credentials laden (nach Build-Phase)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedCredentials();
    });
  }

  Future<void> _loadSavedCredentials() async {
    // Kurz warten bis Settings vollständig initialisiert sind
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final settings = ref.read(settingsNotifierProvider);
    if (settings.rememberMe) {
      final notifier = ref.read(settingsNotifierProvider.notifier);
      final email = await notifier.getSavedEmail();
      final password = await notifier.getSavedPassword();
      if (!mounted) return;
      setState(() {
        _emailController.text = email ?? '';
        _passwordController.text = password ?? '';
        _rememberMe = true;
      });
      debugPrint('[Login] Gespeicherte Anmeldedaten geladen');
    } else {
      debugPrint('[Login] Keine gespeicherten Anmeldedaten gefunden');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    // Prüfe ob Supabase konfiguriert ist
    if (!SupabaseConfig.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.authCloudLoginUnavailable),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(authNotifierProvider.notifier).signIn(
          email,
          password,
        );

    if (success && mounted) {
      // Credentials speichern oder löschen basierend auf Remember-Me
      try {
        final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
        if (_rememberMe) {
          await settingsNotifier.saveCredentials(email, password);
          debugPrint('[Login] Anmeldedaten gespeichert');
        } else {
          await settingsNotifier.clearCredentials();
          debugPrint('[Login] Anmeldedaten gelöscht');
        }
      } catch (e) {
        debugPrint('[Login] Credentials-Speicherung fehlgeschlagen: $e');
        // Fehler nicht blockierend - Navigation trotzdem durchführen
      }

      if (mounted) {
        context.go('/');
      }
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
          SnackBar(content: Text('${context.l10n.errorPrefix}$e')),
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

    // Debug-Output für Supabase-Konfiguration (nur im Debug-Modus)
    if (kDebugMode) {
      debugPrint('[Login] isCloudAvailable: $isCloudAvailable');
      debugPrint('[Login] SUPABASE_URL: ${SupabaseConfig.supabaseUrl.isEmpty ? "(leer)" : SupabaseConfig.supabaseUrl.substring(0, 20)}...');
      debugPrint('[Login] SUPABASE_ANON_KEY: ${SupabaseConfig.supabaseAnonKey.isEmpty ? "(leer)" : "***"}');
    }

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
                  context.l10n.authWelcomeTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.authWelcomeSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Cloud-Login Formular (immer anzeigen)
                _buildCloudLoginForm(theme, colorScheme, authState, isLoading, isCloudAvailable),
                const SizedBox(height: 24),
                _buildDivider(theme),
                const SizedBox(height: 24),

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
    bool isCloudAvailable,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Warnung wenn Supabase nicht konfiguriert
          if (!isCloudAvailable) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.authCloudNotAvailable,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Email Field
          TextFormField(
            controller: _emailController,
            maxLength: 254,
            decoration: InputDecoration(
              labelText: context.l10n.authEmailLabel,
              prefixIcon: const Icon(Icons.email_outlined),
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.l10n.authEmailEmpty;
              }
              if (!value.contains('@')) {
                return context.l10n.authEmailInvalid;
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: context.l10n.authPasswordLabel,
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
                return context.l10n.authPasswordEmpty;
              }
              if (value.length < 8) {
                return context.l10n.authPasswordMinLength;
              }
              return null;
            },
          ),

          const SizedBox(height: 8),

          // Remember Me + Forgot Password Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remember Me Checkbox
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () {
                            setState(() => _rememberMe = !_rememberMe);
                          },
                    child: Text(
                      context.l10n.authRememberMe,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              // Forgot Password
              TextButton(
                onPressed: isLoading ? null : () => context.push('/forgot-password'),
                child: Text(context.l10n.authForgotPassword),
              ),
            ],
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
                : Text(context.l10n.authSignIn),
          ),

          const SizedBox(height: 12),

          // Register Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.authNoAccount,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              TextButton(
                onPressed: isLoading ? null : () => context.push('/register'),
                child: Text(context.l10n.authRegister),
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
            context.l10n.or,
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
          label: Text(context.l10n.authContinueAsGuest),
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
                      ? context.l10n.authGuestInfoCloud
                      : context.l10n.authGuestInfoLocal,
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
