import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _cardsCtrl;
  late final AnimationController _btnsCtrl;
  late final AnimationController _floatCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _btnsFade;
  late final Animation<Offset> _btnsSlide;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _cardsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _btnsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic),
    );
    _btnsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOut),
    );
    _btnsSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _btnsCtrl, curve: Curves.easeOutCubic),
    );
    _float = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Staggered entrance
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _textCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _cardsCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 700), () { if (mounted) _btnsCtrl.forward(); });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _floatCtrl.dispose();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _cardsCtrl.dispose();
    _btnsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _floatCtrl, _logoCtrl, _textCtrl, _cardsCtrl, _btnsCtrl]),
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3D0F6B), Color(0xFF6B21A8), Color(0xFF9D4EDD)],
              ),
            ),
            child: Stack(
              children: [
                // Animated background orbs
                _buildOrb(size, 0.15, 0.05, 200, const Color(0xFFE879F9), 0.0),
                _buildOrb(size, 0.7, 0.6, 280, const Color(0xFF818CF8), 0.33),
                _buildOrb(size, 0.0, 0.7, 160, const Color(0xFF34D399), 0.66),

                // Floating book cards in background
                _buildFloatingCard(size, 0.05, 0.25, const Color(0xFFE879F9), 0.15, -0.18),
                _buildFloatingCard(size, 0.78, 0.15, const Color(0xFF818CF8), 0.12, 0.22),
                _buildFloatingCard(size, 0.82, 0.55, const Color(0xFF34D399), 0.10, -0.14),
                _buildFloatingCard(size, 0.02, 0.65, const Color(0xFFFBBF24), 0.08, 0.16),

                // Main content
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.06),

                        // Logo
                        Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.translate(
                            offset: Offset(0, _float.value * 0.5),
                            child: _buildLogo(),
                          ),
                        ),

                        SizedBox(height: size.height * 0.05),

                        // Hero text
                        FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: _buildHeroText(context),
                          ),
                        ),

                        SizedBox(height: size.height * 0.05),

                        // Feature pills
                        _buildFeaturePills(),

                        SizedBox(height: size.height * 0.06),

                        // Buttons
                        FadeTransition(
                          opacity: _btnsFade,
                          child: SlideTransition(
                            position: _btnsSlide,
                            child: _buildButtons(context),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrb(Size size, double xFrac, double yFrac, double diameter, Color color, double phase) {
    final angle = (_bgCtrl.value + phase) * 2 * math.pi;
    final dx = math.cos(angle) * 20;
    final dy = math.sin(angle) * 20;

    return Positioned(
      left: size.width * xFrac + dx - diameter / 2,
      top: size.height * yFrac + dy - diameter / 2,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
        ),
      ),
    );
  }

  Widget _buildFloatingCard(Size size, double xFrac, double yFrac, Color color, double opacity, double floatFactor) {
    final floatY = _float.value * floatFactor * 3;
    final floatX = _float.value * floatFactor * 1.5;

    return Positioned(
      left: size.width * xFrac + floatX,
      top: size.height * yFrac + floatY,
      child: Transform.rotate(
        angle: floatFactor * 0.8,
        child: Container(
          width: 52,
          height: 72,
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(opacity * 1.5), width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/logo.png', fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.menu_book_rounded, color: AppTheme.brandPrimary, size: 44)),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Knowvas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroText(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Your Digital Reading',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE879F9), Color(0xFFFBBF24)],
          ).createShader(bounds),
          child: const Text(
            'Sanctuary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Discover extraordinary stories, connect with\nbrilliant creators, and immerse yourself in\na world of knowledge.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 16,
            height: 1.7,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturePills() {
    final features = [
      ('📚', 'Vast Library'),
      ('🎧', 'Audiobooks'),
      ('🎨', 'Comics'),
      ('📰', 'Magazines'),
      ('⭐', 'Personalized'),
      ('🌍', 'Community'),
    ];

    return AnimatedBuilder(
      animation: _cardsCtrl,
      builder: (context, _) {
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: List.generate(features.length, (i) {
            final delay = i * 0.12;
            final progress = (((_cardsCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0));
            final curve = Curves.easeOutBack.transform(progress);

            return Transform.scale(
              scale: curve,
              child: Opacity(
                opacity: progress.clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(features[i].$1, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        features[i].$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.go('/auth/sign-up');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.brandPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Get Started — It\'s Free',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go('/auth/sign-in');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('I already have an account',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'By continuing, you agree to our Terms & Privacy Policy',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
