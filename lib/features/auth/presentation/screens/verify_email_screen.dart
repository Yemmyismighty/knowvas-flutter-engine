
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/reveal_animation.dart';
import '../providers/auth_provider.dart';

/// Email Verification Screen - Matches React version design
/// 
/// This screen allows users to verify their email address by entering
/// a 6-digit code sent to their email after signup.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  
  const VerifyEmailScreen({
    required this.email,
    super.key,
  });

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  bool _resendSuccess = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).verifyEmail(
        email: widget.email,
        code: _codeController.text.trim(),
      );

      if (mounted) {
        final authState = ref.read(authProvider);
        
        if (authState.isAuthenticated) {
          setState(() => _success = true);
          
          // Small delay to show success state
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            // Navigate to welcome screen for profile completion
            context.go('/auth/welcome');
          }
        } else if (authState.error != null) {
          setState(() => _error = authState.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'An error occurred during verification');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendCode() async {
    setState(() {
      _isResending = true;
      _error = null;
      _resendSuccess = false;
    });

    try {
      await ref.read(authProvider.notifier).resendVerificationCode(
        email: widget.email,
      );

      if (mounted) {
        setState(() => _resendSuccess = true);
        
        // Hide success message after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _resendSuccess = false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to resend code. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.brand50,
              Colors.white,
              AppTheme.brand50.withOpacity(0.3),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background blur circles
            _buildBackgroundCircles(),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => context.pop(),
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Main card
                        RevealAnimation(
                          child: Card(
                            elevation: 20,
                            shadowColor: AppTheme.brandPrimary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(
                                  MediaQuery.of(context).size.width < 360 ? 16 : 24,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final w = constraints.maxWidth;
                                    final isSmall = w < 300;
                                    return Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildLogo(isSmall),
                                      SizedBox(height: isSmall ? 16 : 24),
                                      _buildHeader(isSmall),
                                      SizedBox(height: isSmall ? 16 : 24),
                                      // Error message
                                      if (_error != null) ...[
                                        _buildErrorMessage(_error!),
                                        const SizedBox(height: 12),
                                      ],
                                      // Success message for resend
                                      if (_resendSuccess) ...[
                                        _buildSuccessMessage(),
                                        const SizedBox(height: 12),
                                      ],
                                      _buildCodeField(),
                                      const SizedBox(height: 20),
                                      _buildVerifyButton(),
                                      const SizedBox(height: 16),
                                      _buildResendSection(),
                                      const SizedBox(height: 16),
                                      _buildSignInLink(),
                                    ],
                                  ),
                                );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.brand50,
              Colors.white,
              AppTheme.brand50.withOpacity(0.3),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundCircles(),
            Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                elevation: 20,
                shadowColor: AppTheme.brandPrimary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green, Color(0xFF059669)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Email Verified!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your account has been successfully created',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Redirecting you to complete your profile...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundCircles() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.brand400.withOpacity(0.2),
                  AppTheme.brand600.withOpacity(0.2),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.brand600.withOpacity(0.2),
                  AppTheme.brand800.withOpacity(0.2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(bool isSmall) {
    final logoSize = isSmall ? 36.0 : 48.0;
    final fontSize = isSmall ? 18.0 : 22.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/logo.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.brand600, AppTheme.brand800],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.menu_book, color: Colors.white, size: logoSize * 0.55),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.brand600, AppTheme.brand800],
          ).createShader(bounds),
          child: Text(
            'Knowvas',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isSmall) {
    return Column(
      children: [
        Text(
          'Verify Your Email',
          style: TextStyle(
            fontSize: isSmall ? 20.0 : 24.0,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'We sent a code to ${widget.email}',
          style: TextStyle(
            fontSize: isSmall ? 12.0 : 14.0,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verification code sent! Check your inbox.',
              style: TextStyle(color: Colors.green[800], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          enabled: !_isLoading,
          maxLength: 6,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.brand300, width: 2),
            ),
          ),
          onChanged: (value) {
            // Remove non-digits
            final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
            if (digitsOnly != value) {
              _codeController.value = TextEditingValue(
                text: digitsOnly,
                selection: TextSelection.collapsed(offset: digitsOnly.length),
              );
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the verification code';
            }
            if (value.length != 6) {
              return 'Code must be 6 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to your email',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return ElevatedButton(
      onPressed: (_isLoading || _codeController.text.length != 6)
          ? null
          : _handleVerify,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppTheme.brandPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        shadowColor: AppTheme.brandPrimary.withOpacity(0.3),
        disabledBackgroundColor: Colors.grey[300],
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Verify Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildResendSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: _isResending ? null : _handleResendCode,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: _isResending
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brand600),
                  ),
                )
              : const Text(
                  'Resend',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brand600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Already verified? ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          TextButton(
            onPressed: () => context.go('/auth/sign-in'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Sign in',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
