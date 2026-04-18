import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '_auth_shared.dart';

// ─── Screen shell ─────────────────────────────────────────────────────────────

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3D0F6B), Color(0xFF6B21A8), Color(0xFF9D4EDD)],
          ),
        ),
        child: Stack(
          children: [
            const AuthBgOrbs(),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                        onPressed: () => context.go('/landing'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: const _SignInForm(key: ValueKey('signin-form')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form ─────────────────────────────────────────────────────────────────────

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm({super.key});
  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _googleSignIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).googleSignIn();
    if (!mounted) return;
    setState(() => _loading = false);
    final s = ref.read(authProvider);
    // Router handles navigation to /home when isAuthenticated becomes true.
    // We only need to handle the device management case manually.
    if (s.requiresDeviceManagement) {
      context.push('/auth/manage-devices?token=${Uri.encodeComponent(s.deviceManagementToken!)}');
    } else if (s.isAuthenticated) {
      HapticFeedback.heavyImpact();
      // Router will redirect — but push explicitly to avoid delay
      context.go('/home');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    final s = ref.read(authProvider);
    if (s.requiresDeviceManagement) {
      context.push('/auth/manage-devices?token=${Uri.encodeComponent(s.deviceManagementToken!)}');
    } else if (s.isAuthenticated) {
      HapticFeedback.heavyImpact();
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(authProvider.select((s) => s.error));
    final sessionTerminated = ref.watch(authProvider.select((s) => s.sessionTerminated));
    final terminationReason = ref.watch(authProvider.select((s) => s.sessionTerminationReason));

    // Clear the termination flag once the user lands on this screen
    ref.listen(authProvider.select((s) => s.sessionTerminated), (_, terminated) {
      if (terminated) {
        Future.microtask(() => ref.read(authProvider.notifier).clearSessionTermination());
      }
    });

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // Logo + header
            Center(
              child: Column(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 24)],
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/logo.png', fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.menu_book_rounded, color: AppTheme.brandPrimary, size: 36)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Welcome back',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Sign in to continue your reading journey',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15),
                    textAlign: TextAlign.center),
              ]),
            ),

            const SizedBox(height: 32),

            // Glass card
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (sessionTerminated) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            terminationReason == SessionTerminationReason.deviceRemoved
                                ? 'You were signed out because this device was removed.'
                                : 'Your session has expired. Please sign in again.',
                            style: const TextStyle(color: Colors.orange, fontSize: 13),
                          )),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(error,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Continue with Google ──────────────────────────────
                    _GoogleButton(onTap: _loading ? null : _googleSignIn, isLoading: _loading),
                    const SizedBox(height: 16),
                    _OrDivider(),
                    const SizedBox(height: 16),
                    // ─────────────────────────────────────────────────────

                    TextFormField(
                      controller: _emailCtrl,
                      enabled: !_loading,
                      style: kAuthInputStyle,
                      decoration: authInputDecoration(
                          label: 'Email', hint: 'you@example.com', icon: Icons.mail_outline_rounded),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      enabled: !_loading,
                      style: kAuthInputStyle,
                      decoration: authInputDecoration(
                        label: 'Password', hint: '••••••••', icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white54, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ),

                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/auth/forgot-password'),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                        child: Text('Forgot password?',
                            style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.brandPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(AppTheme.brandPrimary)))
                            : const Text('Sign In',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Don't have an account? ",
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14)),
              GestureDetector(
                onTap: () => context.go('/auth/sign-up'),
                child: const Text('Sign up',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline, decorationColor: Colors.white)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Google button & divider ───────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap, this.isLoading = false});
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF4285F4)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4285F4),
                      fontFamily: 'Arial',
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Continue with Google',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4285F4),
        fontFamily: 'Arial',
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Divider(color: Colors.white.withOpacity(0.25), thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('or',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
      ),
      Expanded(child: Divider(color: Colors.white.withOpacity(0.25), thickness: 1)),
    ]);
  }
}
