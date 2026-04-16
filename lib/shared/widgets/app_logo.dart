import 'package:flutter/material.dart';

import '../../core/constants/app_branding.dart';
import '../../core/theme/app_theme.dart';

/// App logo widget that adapts to the current theme
class AppLogo extends StatelessWidget {
  final double? size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoSize = size ?? 48.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.brand400,
                AppTheme.brand600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(logoSize * 0.2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandPrimary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'K',
              style: TextStyle(
                fontSize: logoSize * 0.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        // App name (optional)
        if (showText) ...[
          SizedBox(height: logoSize * 0.2),
          Text(
            AppBranding.appName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.brand900,
                ),
          ),
        ],
      ],
    );
  }
}

/// Branded app bar with logo
class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showLogo;

  const BrandedAppBar({
    super.key,
    this.title,
    this.actions,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) ...[
            const AppLogo(size: 32),
            const SizedBox(width: 12),
          ],
          if (title != null)
            Text(
              title!,
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
