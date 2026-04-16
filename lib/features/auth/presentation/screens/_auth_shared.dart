import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared animated background orbs used across auth screens
class AuthBgOrbs extends StatefulWidget {
  const AuthBgOrbs({super.key});
  @override
  State<AuthBgOrbs> createState() => _AuthBgOrbsState();
}

class _AuthBgOrbsState extends State<AuthBgOrbs> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final a = _ctrl.value * 2 * math.pi;
        return Stack(children: [
          Positioned(
            left: size.width * 0.7 + math.cos(a) * 15,
            top: -60 + math.sin(a) * 15,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE879F9).withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -60 + math.cos(a + 2) * 12,
            top: size.height * 0.5 + math.sin(a + 2) * 12,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF818CF8).withOpacity(0.1),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

/// Shared input field style for auth screens (dark glass style)
InputDecoration authInputDecoration({
  required String label,
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
    prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white.withOpacity(0.08),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white54, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

const TextStyle kAuthInputStyle = TextStyle(color: Colors.white, fontSize: 15);
