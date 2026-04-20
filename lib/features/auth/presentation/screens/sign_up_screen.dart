import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/auth_response.dart';
import '../providers/auth_provider.dart';
import '_auth_shared.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1D4ED8), Color(0xFF6B21A8), Color(0xFF9D4EDD)],
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
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: const _SignUpForm(key: ValueKey('signup-form')),
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

class _SignUpForm extends ConsumerStatefulWidget {
  const _SignUpForm({super.key});
  @override
  ConsumerState<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<_SignUpForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreed = false;
  bool _loading = false;
  bool _success = false;
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
    _firstCtrl.dispose(); _lastCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose(); _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _googleSignIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).googleSignIn();
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

  int _strength(String p) {
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  Color _strengthColor(int s) => [Colors.red, Colors.red, Colors.orange, Colors.blue, Colors.green][s];
  String _strengthLabel(int s) => ['', 'Weak', 'Fair', 'Good', 'Strong'][s];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms'), backgroundColor: Colors.red));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).signUp(
      signUpData: SignUpData(
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        username: _emailCtrl.text.trim().split('@').first,
      ),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    final s = ref.read(authProvider);
    if (s.error == null) {
      setState(() => _success = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/auth/verify-email?email=${Uri.encodeComponent(_emailCtrl.text.trim())}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(authProvider.select((s) => s.error));
    final pass = _passCtrl.text;
    final strength = _strength(pass);

    if (_success) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 80),
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green, Color(0xFF059669)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 24),
          const Text('Account Created!',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text('Check your email for a verification code.',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)),
        ]),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final titleSize = w < 340 ? 22.0 : 26.0;
            final subtitleSize = w < 340 ? 12.0 : 14.0;
            final cardPadding = w < 340 ? 16.0 : 20.0;
            final logoSize = w < 340 ? 56.0 : 64.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                Center(
                  child: Column(children: [
                    Container(
                      width: logoSize, height: logoSize,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 24)],
                      ),
                      child: ClipOval(child: Image.asset('assets/logo.png', fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.menu_book_rounded, color: AppTheme.brandPrimary, size: logoSize * 0.5))),
                    ),
                    const SizedBox(height: 16),
                    Text('Create account',
                        style: TextStyle(color: Colors.white, fontSize: titleSize, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Join thousands of readers on Knowvas',
                        style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: subtitleSize),
                        textAlign: TextAlign.center),
                  ]),
                ),

                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  padding: EdgeInsets.all(cardPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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

                    // Name row
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstCtrl,
                          enabled: !_loading,
                          style: kAuthInputStyle,
                          decoration: authInputDecoration(
                              label: 'First Name', hint: 'John', icon: Icons.person_outline_rounded),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastCtrl,
                          enabled: !_loading,
                          style: kAuthInputStyle,
                          decoration: authInputDecoration(
                              label: 'Last Name', hint: 'Doe', icon: Icons.person_outline_rounded),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_loading,
                      style: kAuthInputStyle,
                      decoration: authInputDecoration(
                          label: 'Email', hint: 'you@example.com', icon: Icons.mail_outline_rounded),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      enabled: !_loading,
                      style: kAuthInputStyle,
                      onChanged: (_) => setState(() {}),
                      decoration: authInputDecoration(
                        label: 'Password', hint: '••••••••', icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white54, size: 20),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
                    ),

                    if (pass.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(children: List.generate(4, (i) => Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: i < strength ? _strengthColor(strength) : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ))),
                      const SizedBox(height: 4),
                      Text('Password strength: ${_strengthLabel(strength)}',
                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                    ],
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      enabled: !_loading,
                      style: kAuthInputStyle,
                      decoration: authInputDecoration(
                        label: 'Confirm Password', hint: '••••••••', icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white54, size: 20),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 16),

                    // Terms
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(
                        width: 20, height: 20,
                        child: Checkbox(
                          value: _agreed,
                          onChanged: _loading ? null : (v) => setState(() => _agreed = v ?? false),
                          activeColor: Colors.white,
                          checkColor: AppTheme.brandPrimary,
                          side: BorderSide(color: Colors.white.withOpacity(0.5)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(TextSpan(
                          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                          children: const [
                            TextSpan(text: 'I agree to the '),
                            TextSpan(text: 'Terms of Service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            TextSpan(text: ' and '),
                            TextSpan(text: 'Privacy Policy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        )),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_loading || !_agreed) ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.brandPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          disabledBackgroundColor: Colors.white.withOpacity(0.3),
                        ),
                        child: _loading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(AppTheme.brandPrimary)))
                            : const Text('Create Account',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Already have an account? ',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14)),
              GestureDetector(
                onTap: () => context.go('/auth/sign-in'),
                child: const Text('Sign in',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline, decorationColor: Colors.white)),
              ),
            ]),
          ],
        ); // LayoutBuilder
      },
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
                children: const [
                  Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4285F4),
                      fontFamily: 'Arial',
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Continue with Google',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
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
