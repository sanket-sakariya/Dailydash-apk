import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Login/Signup screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Validate email format
  bool _isValidEmail() {
    final email = _emailController.text.trim();
    return email.isNotEmpty && email.contains('@') && email.contains('.');
  }

  /// Send OTP to email
  Future<void> _sendOtp() async {
    if (!_isValidEmail()) {
      setState(() => _errorMessage = 'Please enter a valid email first');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isSendingOtp = true;
    });

    try {
      await AuthService.instance.sendSignUpOtp(email: _emailController.text.trim());
      if (mounted) {
        setState(() {
          _otpSent = true;
          _successMessage = 'OTP sent to ${_emailController.text.trim()}';
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to send OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  /// Sign up with email, password, and OTP
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP');
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.signUpWithOtp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        otp: otp,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Sign in with email and password
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _otpSent = false;
      _errorMessage = null;
      _successMessage = null;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 80,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DailyDash',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Create your account' : 'Welcome back',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: colors.onSurfaceDim),
                  ),
                  const SizedBox(height: 48),

                  // Success message
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.success.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.success.withAlpha(51)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: colors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: colors.success, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.error.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.error.withAlpha(51)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: colors.error, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enabled: !_otpSent,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: colors.onSurfaceDim),
                      prefixIcon: Icon(Icons.email_outlined, color: colors.onSurfaceDim),
                      filled: true,
                      fillColor: _otpSent ? colors.surface.withAlpha(128) : colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_otpSent,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: colors.onSurfaceDim),
                      prefixIcon: Icon(Icons.lock_outline, color: colors.onSurfaceDim),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: colors.onSurfaceDim,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: _otpSent ? colors.surface.withAlpha(128) : colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (_isSignUp && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  // OTP Section (Sign Up only)
                  if (_isSignUp) ...[
                    const SizedBox(height: 16),

                    // OTP field with Send OTP button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // OTP input field
                        Expanded(
                          child: TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            enabled: _otpSent,
                            maxLength: 6,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 18,
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              labelText: 'OTP Code',
                              labelStyle: TextStyle(color: colors.onSurfaceDim),
                              hintText: _otpSent ? '000000' : 'Click Send OTP',
                              hintStyle: TextStyle(
                                color: colors.onSurfaceDim.withAlpha(100),
                                fontSize: 14,
                                letterSpacing: 0,
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: Icon(Icons.pin_outlined, color: colors.onSurfaceDim),
                              counterText: '',
                              filled: true,
                              fillColor: _otpSent ? colors.surface : colors.surface.withAlpha(128),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: colors.primary, width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Send OTP button
                        SizedBox(
                          height: 56,
                          child: TextButton(
                            onPressed: _isSendingOtp ? null : _sendOtp,
                            style: TextButton.styleFrom(
                              backgroundColor: _otpSent ? colors.success : colors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSendingOtp
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _otpSent ? 'Resend' : 'Send OTP',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    if (_otpSent) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Check your email for the 6-digit code',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceDim),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // Submit button
                  Builder(
                    builder: (context) {
                      final canSubmit = _isSignUp ? _otpSent : true;
                      return ElevatedButton(
                        onPressed: (_isSubmitting || !canSubmit)
                            ? null
                            : (_isSignUp ? _signUp : _signIn),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: colors.primary.withAlpha(80),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Create Account' : 'Sign In',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Toggle sign in/sign up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp ? 'Already have an account?' : "Don't have an account?",
                        style: TextStyle(color: colors.onSurfaceDim),
                      ),
                      TextButton(
                        onPressed: _toggleMode,
                        child: Text(
                          _isSignUp ? 'Sign In' : 'Sign Up',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
