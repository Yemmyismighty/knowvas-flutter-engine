import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Utility class that provides Tailwind CSS equivalent styling for Flutter
/// This ensures exact consistency with the React web version
class TailwindUtils {
  TailwindUtils._();

  // ==================== SPACING ====================
  
  /// Tailwind spacing system (4px base unit)
  static const double space0 = 0.0;    // space-0
  static const double space1 = 4.0;    // space-1
  static const double space2 = 8.0;    // space-2
  static const double space3 = 12.0;   // space-3
  static const double space4 = 16.0;   // space-4
  static const double space5 = 20.0;   // space-5
  static const double space6 = 24.0;   // space-6
  static const double space8 = 32.0;   // space-8
  static const double space10 = 40.0;  // space-10
  static const double space12 = 48.0;  // space-12
  static const double space16 = 64.0;  // space-16
  static const double space20 = 80.0;  // space-20
  static const double space24 = 96.0;  // space-24
  static const double space32 = 128.0; // space-32

  // ==================== TYPOGRAPHY ====================
  
  /// Get TextStyle matching Tailwind typography classes
  static TextStyle textStyle(String className, {Color? color}) {
    TextStyle baseStyle = const TextStyle();
    
    // Font sizes
    if (className.contains('text-xs')) {
      baseStyle = baseStyle.copyWith(fontSize: 12.0);
    } else if (className.contains('text-sm')) {
      baseStyle = baseStyle.copyWith(fontSize: 14.0);
    } else if (className.contains('text-base')) {
      baseStyle = baseStyle.copyWith(fontSize: 16.0);
    } else if (className.contains('text-lg')) {
      baseStyle = baseStyle.copyWith(fontSize: 18.0);
    } else if (className.contains('text-xl')) {
      baseStyle = baseStyle.copyWith(fontSize: 20.0);
    } else if (className.contains('text-2xl')) {
      baseStyle = baseStyle.copyWith(fontSize: 24.0);
    } else if (className.contains('text-3xl')) {
      baseStyle = baseStyle.copyWith(fontSize: 30.0);
    }
    
    // Font weights
    if (className.contains('font-thin')) {
      baseStyle = baseStyle.copyWith(fontWeight: FontWeight.w100);
    } else if (className.contains('font-light')) {
      baseStyle = baseStyle.copyWith(fontWeight: FontWeight.w300);
    } else if (className.contains('font-normal')) {
      baseStyle = baseStyle.copyWith(fontWeight: FontWeight.w400);
    } else if (className.contains('font-medium')) {
      baseStyle = baseStyle.copyWith(fontWeight: FontWeight.w500);
    } else if (className.contains('font-semibold')) {
      baseStyle = baseStyle.copyWith(fontWeight: FontWeight.w600);
    } else if (className.contains('font-bold')) {
      baseStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);
    }
    
    // Line height
    if (className.contains('leading-tight')) {
      baseStyle = baseStyle.copyWith(height: 1.25);
    } else if (className.contains('leading-normal')) {
      baseStyle = baseStyle.copyWith(height: 1.5);
    } else if (className.contains('leading-relaxed')) {
      baseStyle = baseStyle.copyWith(height: 1.625);
    }
    
    // Letter spacing
    if (className.contains('tracking-tight')) {
      baseStyle = baseStyle.copyWith(letterSpacing: -0.025);
    } else if (className.contains('tracking-normal')) {
      baseStyle = baseStyle.copyWith(letterSpacing: 0.0);
    } else if (className.contains('tracking-wide')) {
      baseStyle = baseStyle.copyWith(letterSpacing: 0.025);
    }
    
    if (color != null) {
      baseStyle = baseStyle.copyWith(color: color);
    }
    
    return baseStyle;
  }

  // ==================== BORDER RADIUS ====================
  
  /// Get BorderRadius matching Tailwind rounded classes
  static BorderRadius borderRadius(String className) {
    switch (className) {
      case 'rounded-none':
        return BorderRadius.zero;
      case 'rounded-sm':
        return BorderRadius.circular(2.0);
      case 'rounded':
        return BorderRadius.circular(4.0);
      case 'rounded-md':
        return BorderRadius.circular(6.0);
      case 'rounded-lg':
        return BorderRadius.circular(8.0);
      case 'rounded-xl':
        return BorderRadius.circular(12.0);
      case 'rounded-2xl':
        return BorderRadius.circular(16.0);
      case 'rounded-3xl':
        return BorderRadius.circular(24.0);
      case 'rounded-full':
        return BorderRadius.circular(9999.0);
      default:
        return BorderRadius.circular(4.0);
    }
  }

  // ==================== SHADOWS ====================
  
  /// Get BoxShadow list matching Tailwind shadow classes
  static List<BoxShadow> shadow(String className) {
    switch (className) {
      case 'shadow-sm':
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];
      case 'shadow':
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];
      case 'shadow-md':
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case 'shadow-lg':
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ];
      case 'shadow-xl':
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ];
      case 'shadow-2xl':
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 50,
            offset: const Offset(0, 25),
          ),
        ];
      case 'shadow-brand':
        return [
          BoxShadow(
            color: AppTheme.brandPrimary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.brandPrimary.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ];
      case 'shadow-brand-lg':
        return [
          BoxShadow(
            color: AppTheme.brandPrimary.withOpacity(0.25),
            blurRadius: 50,
            offset: const Offset(0, 25),
          ),
        ];
      default:
        return [];
    }
  }

  // ==================== DIMENSIONS ====================
  
  /// Get Size matching Tailwind width/height classes
  static Size size(String widthClass, String heightClass) {
    return Size(
      _getDimension(widthClass),
      _getDimension(heightClass),
    );
  }
  
  static double _getDimension(String className) {
    // Extract number from class like 'w-48' or 'h-64'
    final match = RegExp(r'\d+').firstMatch(className);
    if (match != null) {
      final value = int.parse(match.group(0)!);
      return value * 4.0; // Tailwind uses 4px base unit
    }
    return 0.0;
  }

  // ==================== COLORS ====================
  
  /// Get Color matching Tailwind color classes
  static Color? color(String className) {
    if (className.contains('brand-')) {
      final shade = className.split('-').last;
      switch (shade) {
        case '50': return AppTheme.brand50;
        case '100': return AppTheme.brand100;
        case '200': return AppTheme.brand200;
        case '300': return AppTheme.brand300;
        case '400': return AppTheme.brand400;
        case '500': return AppTheme.brand500;
        case '600': return AppTheme.brand600;
        case '700': return AppTheme.brand700;
        case '800': return AppTheme.brand800;
        case '900': return AppTheme.brand900;
        case '950': return AppTheme.brand950;
      }
    }
    
    // Standard colors
    if (className.contains('white')) return Colors.white;
    if (className.contains('black')) return Colors.black;
    if (className.contains('transparent')) return Colors.transparent;
    
    // Gray colors
    if (className.contains('gray-')) {
      final shade = className.split('-').last;
      switch (shade) {
        case '50': return Colors.grey[50];
        case '100': return Colors.grey[100];
        case '200': return Colors.grey[200];
        case '300': return Colors.grey[300];
        case '400': return Colors.grey[400];
        case '500': return Colors.grey[500];
        case '600': return Colors.grey[600];
        case '700': return Colors.grey[700];
        case '800': return Colors.grey[800];
        case '900': return Colors.grey[900];
      }
    }
    
    return null;
  }

  // ==================== GRADIENTS ====================
  
  /// Get Gradient matching Tailwind gradient classes
  static Gradient? gradient(String className) {
    if (className.contains('from-brand-600') && className.contains('to-brand-700')) {
      return const LinearGradient(
        colors: [AppTheme.brand600, AppTheme.brand700],
      );
    }
    
    if (className.contains('from-brand-500') && className.contains('to-brand-700')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.brand500, AppTheme.brand700],
      );
    }
    
    return null;
  }

  // ==================== TRANSFORMS ====================
  
  /// Get Transform matrix for 3D effects matching CSS transforms
  static Matrix4 transform3D({
    double perspective = 1000.0,
    double rotateX = 0.0,
    double rotateY = 0.0,
    double rotateZ = 0.0,
    double translateX = 0.0,
    double translateY = 0.0,
    double translateZ = 0.0,
    double scale = 1.0,
  }) {
    final matrix = Matrix4.identity();
    
    // Set perspective
    matrix.setEntry(3, 2, 0.001 * (1000.0 / perspective));
    
    // Apply transforms
    if (translateX != 0.0 || translateY != 0.0 || translateZ != 0.0) {
      matrix.translate(translateX, translateY, translateZ);
    }
    
    if (rotateX != 0.0) matrix.rotateX(rotateX);
    if (rotateY != 0.0) matrix.rotateY(rotateY);
    if (rotateZ != 0.0) matrix.rotateZ(rotateZ);
    
    if (scale != 1.0) matrix.scale(scale);
    
    return matrix;
  }

  // ==================== ANIMATION CURVES ====================
  
  /// Get Curve matching CSS easing functions
  static Curve curve(String easingFunction) {
    switch (easingFunction) {
      case 'ease-in-out':
        return Curves.easeInOut;
      case 'ease-in':
        return Curves.easeIn;
      case 'ease-out':
        return Curves.easeOut;
      case 'ease':
        return Curves.ease;
      case 'linear':
        return Curves.linear;
      case 'bounce':
        return Curves.bounceOut;
      case 'elastic':
        return Curves.elasticOut;
      default:
        return Curves.easeInOut;
    }
  }

  // ==================== RESPONSIVE BREAKPOINTS ====================
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }
  
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1280;
  }

  // ==================== HELPER METHODS ====================
  
  /// Create EdgeInsets matching Tailwind padding classes
  static EdgeInsets padding(String className) {
    final match = RegExp(r'p-(\d+)').firstMatch(className);
    if (match != null) {
      final value = int.parse(match.group(1)!) * 4.0;
      return EdgeInsets.all(value);
    }
    
    // Handle px, py, pl, pr, pt, pb
    double left = 0, top = 0, right = 0, bottom = 0;
    
    final pxMatch = RegExp(r'px-(\d+)').firstMatch(className);
    if (pxMatch != null) {
      final value = int.parse(pxMatch.group(1)!) * 4.0;
      left = right = value;
    }
    
    final pyMatch = RegExp(r'py-(\d+)').firstMatch(className);
    if (pyMatch != null) {
      final value = int.parse(pyMatch.group(1)!) * 4.0;
      top = bottom = value;
    }
    
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }
  
  /// Create EdgeInsets matching Tailwind margin classes
  static EdgeInsets margin(String className) {
    final match = RegExp(r'm-(\d+)').firstMatch(className);
    if (match != null) {
      final value = int.parse(match.group(1)!) * 4.0;
      return EdgeInsets.all(value);
    }
    return EdgeInsets.zero;
  }
}