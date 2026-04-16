import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Flutter widget that exactly mirrors the React MainNavbar component
class MainNavbar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onCartPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onSignInPressed;
  final VoidCallback? onSignUpPressed;
  final bool isAuthenticated;
  final String? currentRoute;

  const MainNavbar({
    super.key,
    this.onCartPressed,
    this.onSearchPressed,
    this.onProfilePressed,
    this.onSignInPressed,
    this.onSignUpPressed,
    this.isAuthenticated = false,
    this.currentRoute,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80); // Match React header height

  @override
  State<MainNavbar> createState() => _MainNavbarState();
}

class _MainNavbarState extends State<MainNavbar> {
  bool _isMobileMenuOpen = false;

  final List<NavLink> _navLinks = [
    NavLink(route: '/pricing', label: 'Become a Member'),
    NavLink(route: '/library', label: 'My Library', requiresAuth: true),
    NavLink(route: '/cart', label: 'Cart'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      // Exact styling matching React: sticky top-0 z-50 backdrop-blur-xl bg-white/80 border-b border-gray-200/50
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // px-6 py-4
            child: Row(
              children: [
                // Left side - Logo and navigation
                Expanded(
                  child: Row(
                    children: [
                      // Logo
                      _buildLogo(),
                      
                      const SizedBox(width: 32), // space-x-8
                      
                      // Desktop navigation
                      if (MediaQuery.of(context).size.width >= 768) // md:flex
                        _buildDesktopNavigation(),
                    ],
                  ),
                ),
                
                // Right side - Actions
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return GestureDetector(
      onTap: () {
        // Navigate to home
      },
      child: Container(
        height: 40,
        child: Row(
          children: [
            // Replace with your actual logo
            Container(
              width: 32,
              height: 32,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.brand500, AppTheme.brand700],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Knowvas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopNavigation() {
    return Row(
      children: _navLinks.map((link) {
        if (link.requiresAuth && !widget.isAuthenticated) {
          return const SizedBox.shrink();
        }

        final isActive = widget.currentRoute == link.route;

        return Padding(
          padding: const EdgeInsets.only(right: 24), // space-x-6
          child: GestureDetector(
            onTap: () {
              // Handle navigation
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // px-3 py-1
              decoration: BoxDecoration(
                color: isActive ? AppTheme.brand100 : Colors.transparent,
                borderRadius: BorderRadius.circular(20), // rounded-full
              ),
              child: Text(
                link.label,
                style: TextStyle(
                  fontSize: 14, // text-sm
                  fontWeight: FontWeight.w500, // font-medium
                  color: isActive 
                      ? AppTheme.brand700 
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return Row(
        children: [
          // Mobile cart button
          _buildIconButton(
            icon: Icons.shopping_cart_outlined,
            onPressed: widget.onCartPressed,
          ),
          
          const SizedBox(width: 8),
          
          // Mobile search button
          _buildIconButton(
            icon: Icons.search,
            onPressed: widget.onSearchPressed,
          ),
          
          const SizedBox(width: 8),
          
          // Mobile profile button (if authenticated)
          if (widget.isAuthenticated)
            _buildIconButton(
              icon: Icons.person_outline,
              onPressed: widget.onProfilePressed,
            ),
          
          const SizedBox(width: 8),
          
          // Mobile menu button
          _buildIconButton(
            icon: Icons.menu,
            onPressed: () {
              setState(() {
                _isMobileMenuOpen = true;
              });
              _showMobileMenu();
            },
          ),
        ],
      );
    }

    // Desktop actions
    return Row(
      children: [
        // Cart button
        _buildIconButton(
          icon: Icons.shopping_cart_outlined,
          onPressed: widget.onCartPressed,
        ),
        
        const SizedBox(width: 16),
        
        // Search button
        _buildIconButton(
          icon: Icons.search,
          onPressed: widget.onSearchPressed,
        ),
        
        const SizedBox(width: 16),
        
        if (widget.isAuthenticated) ...[
          // Profile button
          _buildIconButton(
            icon: Icons.person_outline,
            onPressed: widget.onProfilePressed,
          ),
        ] else ...[
          // Sign in button
          TextButton(
            onPressed: widget.onSignInPressed,
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('Sign in'),
          ),
          
          const SizedBox(width: 8),
          
          // Get Started button - exact styling from React
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.brand600, AppTheme.brand700],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandPrimary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: widget.onSignUpPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        foregroundColor: Colors.grey[600],
        backgroundColor: Colors.transparent,
      ),
      constraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
    );
  }

  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMobileMenu(),
    );
  }

  Widget _buildMobileMenu() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLogo(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Navigation links
          ..._navLinks.map((link) {
            if (link.requiresAuth && !widget.isAuthenticated) {
              return const SizedBox.shrink();
            }

            final isActive = widget.currentRoute == link.route;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // Handle navigation
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.brand100 : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    link.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isActive 
                          ? AppTheme.brand700 
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          
          const Spacer(),
          
          // Auth buttons for mobile
          if (!widget.isAuthenticated) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSignInPressed?.call();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Sign in'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.brand600, AppTheme.brand700],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandPrimary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onSignUpPressed?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NavLink {
  final String route;
  final String label;
  final bool requiresAuth;

  const NavLink({
    required this.route,
    required this.label,
    this.requiresAuth = false,
  });
}