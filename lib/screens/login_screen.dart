import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Neon Nocturne styled login screen.
///
/// Single primary CTA — "Continue with Google" — that delegates to
/// [AuthService.signInWithGoogle]. Surfaces inline errors via a snackbar and
/// never navigates manually: the auth-state listener in `main.dart` handles
/// the redirect to `MainShell` once a session is established.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      // No navigation here — main.dart's auth guard will swap screens.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: $e'),
          backgroundColor: context.colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Container(
          // Subtle "neon" gradient backdrop that matches the dark theme.
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 1.2,
              colors: [
                colors.primary.withValues(alpha: 0.18),
                colors.background,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                _NeonLogo(color: colors.primary),
                const SizedBox(height: 32),
                Text(
                  'DailyDash',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Track expenses offline.\nSync seamlessly when online.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                const Spacer(flex: 3),
                _GoogleButton(
                  isLoading: _isLoading,
                  onPressed: _handleGoogleSignIn,
                ),
                const SizedBox(height: 16),
                Text(
                  'By continuing you agree to keep your data\nsynced via your Google account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceDim,
                      ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeonLogo extends StatelessWidget {
  const _NeonLogo({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.6)],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.bolt_rounded,
          size: 56,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: colors.primary.withValues(alpha: 0.4),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            colors.primary.withValues(alpha: 0.08),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.login_rounded, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
