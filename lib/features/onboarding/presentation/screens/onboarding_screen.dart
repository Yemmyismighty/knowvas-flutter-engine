import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';

const String _kOnboardingDone = 'onboarding_complete';

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

// ─── Main screen ─────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // 4 pages: 3 content + 1 CTA
  static const _totalPages = 4;

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    HapticFeedback.lightImpact();
    await markOnboardingDone();
    if (mounted) context.go('/landing');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCta = _currentPage == _totalPages - 1;
    final isContentSlide = !isCta;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _currentPage = i);
            },
            children: [
              const _Slide1Library(),
              const _Slide2Offline(),
              const _Slide3Community(),
              _Slide4Cta(onSignUp: () async {
                await markOnboardingDone();
                if (mounted) context.push('/auth/sign-up');
              }, onSignIn: () async {
                await markOnboardingDone();
                if (mounted) context.push('/auth/sign-in');
              }),
            ],
          ),

          // Skip (only on content slides)
          if (isContentSlide)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip',
                    style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),

          // Bottom controls (only on content slides)
          if (isContentSlide)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 32,
              right: 32,
              child: Column(
                children: [
                  // Dots (3 dots for 3 content slides)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? Colors.white : const Color(0x61FFFFFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.brandPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── SLIDE 4: CTA (dedicated, no competing content) ──────────────────────────

class _Slide4Cta extends StatefulWidget {
  const _Slide4Cta({required this.onSignUp, required this.onSignIn});
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  @override
  State<_Slide4Cta> createState() => _Slide4CtaState();
}

class _Slide4CtaState extends State<_Slide4Cta> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.75, curve: Curves.easeOut)),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.75, curve: Curves.easeOut)),
    );
    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.65, 1.0, curve: Curves.easeOut)),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D0F6B), Color(0xFF6B21A8), Color(0xFF9D4EDD)],
        ),
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  Transform.scale(
                    scale: _logoScale.value,
                    child: Container(
                      width: 96, height: 96,
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
                              const Icon(Icons.menu_book_rounded, color: AppTheme.brandPrimary, size: 48)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Text
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          const Text(
                            'Start your reading\njourney today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Join thousands of readers on Knowvas.\nFree to start, no credit card required.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 16,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Buttons
                  FadeTransition(
                    opacity: _btnFade,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              widget.onSignUp();
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
                              widget.onSignIn();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0x8AFFFFFF), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('I already have an account',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Shared slide shell ───────────────────────────────────────────────────────

class _SlideShell extends StatelessWidget {
  const _SlideShell({
    required this.gradient,
    required this.illustration,
    required this.title,
    required this.subtitle,
  });

  final List<Color> gradient;
  final Widget illustration;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(height: 280, child: illustration),
              const Spacer(flex: 2),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.2),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(subtitle,
                  style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 16, height: 1.6),
                  textAlign: TextAlign.center),
              const SizedBox(height: 160),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SLIDE 1: Animated book fan ───────────────────────────────────────────────

class _Slide1Library extends StatefulWidget {
  const _Slide1Library();

  @override
  State<_Slide1Library> createState() => _Slide1LibraryState();
}

class _Slide1LibraryState extends State<_Slide1Library>
    with TickerProviderStateMixin {
  late final AnimationController _fanCtrl;
  late final AnimationController _floatCtrl;
  late final List<Animation<double>> _fanAngles;
  late final List<Animation<double>> _fanOffsets;
  late final Animation<double> _float;

  static const _colors = [
    Color(0xFFE879F9),
    Color(0xFF818CF8),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFFF87171),
  ];

  @override
  void initState() {
    super.initState();

    _fanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    // Each book fans out to a different angle with staggered delay
    final targetAngles = [-0.28, -0.14, 0.0, 0.14, 0.28];
    final targetOffsets = [-52.0, -26.0, 0.0, 26.0, 52.0];

    _fanAngles = List.generate(5, (i) {
      final start = i * 0.06;
      return Tween<double>(begin: 0, end: targetAngles[i]).animate(
        CurvedAnimation(
          parent: _fanCtrl,
          curve: Interval(start, (start + 0.5).clamp(0, 1), curve: Curves.elasticOut),
        ),
      );
    });

    _fanOffsets = List.generate(5, (i) {
      final start = i * 0.06;
      return Tween<double>(begin: 0, end: targetOffsets[i]).animate(
        CurvedAnimation(
          parent: _fanCtrl,
          curve: Interval(start, (start + 0.5).clamp(0, 1), curve: Curves.easeOutBack),
        ),
      );
    });

    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Start fan after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fanCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fanCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SlideShell(
      gradient: const [Color(0xFF6B21A8), Color(0xFF9D4EDD)],
      title: 'Your entire library,\nin your pocket',
      subtitle: 'Thousands of eBooks, audiobooks,\ncomics and magazines — all in one place.',
      illustration: AnimatedBuilder(
        animation: Listenable.merge([_fanCtrl, _floatCtrl]),
        builder: (context, _) {
          return Transform.translate(
            offset: Offset(0, _float.value),
            child: SizedBox(
              width: 280,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow
                  Container(
                    width: 180, height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x14FFFFFF),
                    ),
                  ),
                  // Fanned books (back to front)
                  for (int i = 0; i < 5; i++)
                    Transform.rotate(
                      angle: _fanAngles[i].value,
                      child: Transform.translate(
                        offset: Offset(_fanOffsets[i].value, 0),
                        child: _BookCard(
                          color: _colors[i],
                          width: 80,
                          height: 120,
                          elevation: i == 2 ? 16 : 6,
                        ),
                      ),
                    ),
                  // Sparkles
                  ..._buildSparkles(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSparkles() {
    if (_fanCtrl.value < 0.8) return [];
    final opacity = ((_fanCtrl.value - 0.8) / 0.2).clamp(0.0, 1.0);
    return [
      Positioned(top: 10, right: 30, child: _Sparkle(opacity: opacity, size: 12)),
      Positioned(top: 30, left: 20, child: _Sparkle(opacity: opacity, size: 8)),
      Positioned(bottom: 20, right: 20, child: _Sparkle(opacity: opacity, size: 10)),
    ];
  }
}

// ─── SLIDE 2: Download animation ─────────────────────────────────────────────

class _Slide2Offline extends StatefulWidget {
  const _Slide2Offline();

  @override
  State<_Slide2Offline> createState() => _Slide2OfflineState();
}

class _Slide2OfflineState extends State<_Slide2Offline>
    with TickerProviderStateMixin {
  late final AnimationController _phoneCtrl;
  late final AnimationController _downloadCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _phoneSlide;
  late final Animation<double> _downloadProgress;
  late final Animation<double> _pulse;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();

    _phoneCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _downloadCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _phoneSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _phoneCtrl, curve: Curves.easeOutCubic),
    );

    _downloadProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _downloadCtrl, curve: Curves.easeInOut),
    );

    _checkScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _downloadCtrl,
        curve: const Interval(0.85, 1.0, curve: Curves.elasticOut),
      ),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _phoneCtrl.forward().then((_) {
        if (mounted) _downloadCtrl.forward().then((_) {
          if (mounted) {
            // Loop the download animation
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                _downloadCtrl.reset();
                _downloadCtrl.forward();
              }
            });
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _downloadCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SlideShell(
      gradient: const [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
      title: 'Read anywhere,\neven offline',
      subtitle: 'Download your favorites and enjoy\nthem without an internet connection.',
      illustration: AnimatedBuilder(
        animation: Listenable.merge([_phoneCtrl, _downloadCtrl, _pulseCtrl]),
        builder: (context, _) {
          final progress = _downloadProgress.value;
          final isDone = progress >= 0.99;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Phone
              Transform.translate(
                offset: Offset(0, _phoneSlide.value),
                child: Opacity(
                  opacity: _phoneCtrl.value,
                  child: Container(
                    width: 130, height: 220,
                    decoration: BoxDecoration(
                      color: Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Color(0x4DFFFFFF), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/logo.png', width: 44, height: 44, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.menu_book_rounded, color: Colors.white, size: 40)),
                        ),
                        const SizedBox(height: 12),
                        // Progress bar inside phone
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Color(0x3DFFFFFF),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDone ? const Color(0xFF34D399) : Colors.white,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isDone ? 'Ready offline' : '${(progress * 100).toInt()}%',
                          style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Download badge (bottom right)
              Positioned(
                bottom: 10, right: 50,
                child: Transform.scale(
                  scale: _pulse.value,
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: isDone ? const Color(0xFF34D399) : const Color(0xFF60A5FA),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDone ? const Color(0xFF34D399) : const Color(0xFF60A5FA))
                              .withOpacity(0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      scale: isDone ? _checkScale.value : 1.0,
                      child: Icon(
                        isDone ? Icons.check_rounded : Icons.download_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),

              // Wifi-off badge (top left)
              Positioned(
                top: 10, left: 50,
                child: Opacity(
                  opacity: _phoneCtrl.value,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Color(0x26FFFFFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0x4DFFFFFF)),
                    ),
                    child: Icon(Icons.wifi_off_rounded, color: Color(0xB3FFFFFF), size: 22),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── SLIDE 3: Community orbit ─────────────────────────────────────────────────

class _Slide3Community extends StatefulWidget {
  const _Slide3Community();

  @override
  State<_Slide3Community> createState() => _Slide3CommunityState();
}

class _Slide3CommunityState extends State<_Slide3Community>
    with TickerProviderStateMixin {
  late final AnimationController _orbitCtrl;
  late final AnimationController _logoCtrl;
  late final List<AnimationController> _avatarCtrls;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoPulse;

  static const _avatarColors = [
    Color(0xFFE879F9),
    Color(0xFF818CF8),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFFF87171),
    Color(0xFF60A5FA),
  ];

  @override
  void initState() {
    super.initState();

    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _logoScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );

    _logoPulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _orbitCtrl, curve: const SineCurve()),
    );

    // Staggered avatar pop-ins
    _avatarCtrls = List.generate(6, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      Future.delayed(Duration(milliseconds: 300 + i * 100), () {
        if (mounted) ctrl.forward();
      });
      return ctrl;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoCtrl.forward();
    });
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _logoCtrl.dispose();
    for (final c in _avatarCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SlideShell(
      gradient: const [Color(0xFF9D4EDD), Color(0xFF6B21A8)],
      title: 'Join thousands\nof readers',
      subtitle: 'Discover new stories, follow authors,\nand share your reading journey.',
      illustration: AnimatedBuilder(
        animation: Listenable.merge([_orbitCtrl, _logoCtrl, ..._avatarCtrls]),
        builder: (context, _) {
          return SizedBox(
            width: 260, height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Orbit ring
                Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0x1FFFFFFF), width: 1.5),
                  ),
                ),

                // Orbiting avatars
                for (int i = 0; i < 6; i++) ...[
                  _buildOrbitingAvatar(i),
                ],

                // Center logo
                Transform.scale(
                  scale: _logoScale.value * _logoPulse.value,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.menu_book_rounded, color: AppTheme.brandPrimary, size: 40),
                      ),
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

  Widget _buildOrbitingAvatar(int i) {
    final angle = _orbitCtrl.value * 2 * math.pi + (i * math.pi * 2 / 6);
    const radius = 110.0;
    final x = math.cos(angle) * radius;
    final y = math.sin(angle) * radius;

    final scaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _avatarCtrls[i], curve: Curves.elasticOut),
    );

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.scale(
        scale: scaleAnim.value,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _avatarColors[i],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: _avatarColors[i].withOpacity(0.4),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  const _BookCard({required this.color, required this.width, required this.height, this.elevation = 6});
  final Color color;
  final double width;
  final double height;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(10),
      shadowColor: Colors.black38,
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 5, width: width * 0.7,
                  decoration: BoxDecoration(color: Color(0x4DFFFFFF), borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 5),
              Container(height: 5, width: width * 0.5,
                  decoration: BoxDecoration(color: Color(0x33FFFFFF), borderRadius: BorderRadius.circular(3))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.opacity, required this.size});
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Icon(Icons.star_rounded, color: Color(0xB3FFFFFF), size: size),
    );
  }
}

/// Sine curve for smooth looping pulse
class SineCurve extends Curve {
  const SineCurve();

  @override
  double transformInternal(double t) => (math.sin(t * 2 * math.pi) + 1) / 2;
}
