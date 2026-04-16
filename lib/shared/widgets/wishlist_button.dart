import 'package:flutter/material.dart';

/// Animated wishlist button matching web app design
/// Features: heart icon, bounce animation, sparkle particles, glow effect
class WishlistButton extends StatefulWidget {
  final bool isWishlisted;
  final VoidCallback onToggle;
  final bool isLoading;
  final double size;

  const WishlistButton({
    required this.isWishlisted,
    required this.onToggle,
    this.isLoading = false,
    this.size = 24,
    super.key,
  });

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _justToggled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WishlistButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger animation when wishlist status changes
    if (oldWidget.isWishlisted != widget.isWishlisted && widget.isWishlisted) {
      setState(() => _justToggled = true);
      _controller.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _justToggled = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onToggle,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _justToggled ? _scaleAnimation.value : 1.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect when wishlisted
                if (widget.isWishlisted && !_justToggled)
                  Container(
                    width: widget.size + 16,
                    height: widget.size + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.2),
                    ),
                  ),

                // Expanding circle animation
                if (_justToggled)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return Container(
                        width: (widget.size + 16) * (1 + value),
                        height: (widget.size + 16) * (1 + value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red.withOpacity(1 - value),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),

                // Sparkle particles
                if (_justToggled) ...[
                  _buildSparkle(0, -widget.size, 0),
                  _buildSparkle(widget.size, 0, 100),
                  _buildSparkle(0, widget.size, 200),
                  _buildSparkle(-widget.size, 0, 150),
                ],

                // Heart icon
                Icon(
                  widget.isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: widget.isWishlisted ? Colors.red : Colors.grey[600],
                  size: widget.size,
                ),

                // Loading indicator
                if (widget.isLoading)
                  SizedBox(
                    width: widget.size + 8,
                    height: widget.size + 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.red.withOpacity(0.5),
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

  Widget _buildSparkle(double dx, double dy, int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 - delayMs),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(dx * value, dy * value),
          child: Opacity(
            opacity: 1 - value,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
