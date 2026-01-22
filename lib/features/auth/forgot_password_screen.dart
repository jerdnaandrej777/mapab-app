import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';

/// Passwort-Zurücksetzen Screen
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).resetPassword(
          _emailController.text.trim(),
        );

    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passwort zurücksetzen'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessState(theme, colorScheme) : _buildFormState(theme, colorScheme, authState),
        ),
      ),
    );
  }

  Widget _buildFormState(ThemeData theme, ColorScheme colorScheme, AppAuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Icon(
            Icons.lock_reset,
            size: 64,
            color: colorScheme.primary,
          ),

          const SizedBox(height: 24),

          // Header
          Text(
            'Passwort vergessen?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Gib deine E-Mail-Adresse ein und wir senden dir einen Link zum Zurücksetzen.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Email Field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-Mail',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendResetEmail(),
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

          const SizedBox(height: 24),

          // Error Message
          if (authState.error != null) ...[
            Container(
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
                      authState.error!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit Button
          FilledButton(
            onPressed: authState.isLoading ? null : _sendResetEmail,
            child: authState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Link senden'),
          ),

          const SizedBox(height: 16),

          // Back to Login
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Zurück zur Anmeldung'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success Icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read,
            size: 64,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 24),

        // Success Message
        Text(
          'E-Mail gesendet!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Wir haben dir eine E-Mail an\n${_emailController.text}\ngesendet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Klicke auf den Link in der E-Mail, um ein neues Passwort zu setzen. Der Link ist 24 Stunden gültig.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 32),

        // Back to Login
        FilledButton(
          onPressed: () => context.go('/login'),
          child: const Text('Zurück zur Anmeldung'),
        ),

        const SizedBox(height: 16),

        // Resend
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child: const Text('Erneut senden'),
        ),
      ],
    );
  }
}
