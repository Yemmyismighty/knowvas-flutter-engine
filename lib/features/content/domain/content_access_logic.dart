/// Access control logic for content based on user subscription and content type
class ContentAccessLogic {
  /// Determine content access state
  static ContentAccessState determineAccess({
    required dynamic user,
    required ContentAccessInfo content,
  }) {
    if (content.isEmpty) {
      return ContentAccessState(
        canRead: false,
        canPurchase: false,
        canSubscribe: false,
        buttonState: ButtonState.loginRequired,
        buttonText: 'Sign In to Read',
        shouldShowAddToCart: false,
        shouldShowUnlimitedAccessButton: false,
      );
    }

    // Determine content type for reader requirements
    final isPdfBasedContent = ['comic', 'magazine', 'newspaper']
            .contains(content.type.toLowerCase()) ||
        (content.type.toLowerCase() == 'book' &&
            content.fileType?.toLowerCase() == 'pdf');
    final isAudiobook = content.type.toLowerCase() == 'audiobook';
    final isEpubBook = content.type.toLowerCase() == 'book' &&
        content.fileType?.toLowerCase() != 'pdf';

    // ===== UNAUTHENTICATED USERS =====
    if (user == null) {
      // Only free EPUB books are accessible without authentication
      if (content.isFree && isEpubBook) {
        return ContentAccessState(
          canRead: true,
          canPurchase: false,
          canSubscribe: false,
          buttonState: ButtonState.read,
          buttonText: 'Read Free',
          shouldShowAddToCart: false,
          shouldShowUnlimitedAccessButton: false,
        );
      }

      if (!content.isFree && !content.isPremiumOnly) {
        return ContentAccessState(
          canRead: false,
          canPurchase: false,
          canSubscribe: false,
          buttonState: ButtonState.loginRequired,
          buttonText: 'Sign in to continue',
          shouldShowAddToCart: true,
          shouldShowUnlimitedAccessButton: false,
        );
      }

      // Everything else requires sign-in
      return ContentAccessState(
        canRead: false,
        canPurchase: false,
        canSubscribe: false,
        buttonState: ButtonState.loginRequired,
        buttonText: 'Sign in to continue',
        shouldShowAddToCart: false,
        shouldShowUnlimitedAccessButton: false,
      );
    }

    // ===== AUTHENTICATED USERS =====
    final withinFreeLimit = content.withinFreeLimit ?? true;
    final withinNonFreeLimit = content.withinNonFreeLimit ?? true;
    final subscriptionTier = content.userSubscriptionTier ?? 'Freebie';
    final price = content.price;
    final isPurchaseOnly = content.isPurchaseOnly;
    final isPremiumOnly = content.isPremiumOnly;

    // ===== CASE 1: FREE CONTENT =====
    if (content.isFree) {
      if (withinFreeLimit) {
        return ContentAccessState(
          canRead: true,
          canPurchase: false,
          canSubscribe: false,
          buttonState: ButtonState.read,
          buttonText: 'Read Free',
          shouldShowAddToCart: false,
          shouldShowUnlimitedAccessButton: false,
        );
      } else {
        // Free limit exceeded
        return ContentAccessState(
          canRead: false,
          canPurchase: false,
          canSubscribe: subscriptionTier == 'Freebie',
          buttonState: subscriptionTier == 'Freebie'
              ? ButtonState.subscribe
              : ButtonState.upgrade,
          buttonText: subscriptionTier == 'Freebie'
              ? 'Subscribe for Unlimited'
              : 'Upgrade Plan',
          shouldShowAddToCart: false,
          shouldShowUnlimitedAccessButton: false,
        );
      }
    }

    // ===== CASE 2: ALREADY PURCHASED =====
    if (content.isPurchased) {
      return ContentAccessState(
        canRead: true,
        canPurchase: false,
        canSubscribe: false,
        buttonState: ButtonState.read,
        buttonText: isAudiobook ? 'Listen Now' : 'Read Now',
        shouldShowAddToCart: false,
        shouldShowUnlimitedAccessButton: false,
      );
    }

    // ===== CASE 3: PURCHASE-ONLY CONTENT =====
    if (isPurchaseOnly && price > 0) {
      return ContentAccessState(
        canRead: false,
        canPurchase: true,
        canSubscribe: false,
        buttonState: ButtonState.purchase,
        buttonText: 'Buy Now - \$${price.toStringAsFixed(2)}',
        shouldShowAddToCart: true,
        shouldShowUnlimitedAccessButton: false,
      );
    }

    // ===== CASE 4: PREMIUM-ONLY CONTENT (subscription only, no purchase) =====
    if (isPremiumOnly && price == 0) {
      if (withinNonFreeLimit) {
        return ContentAccessState(
          canRead: true,
          canPurchase: false,
          canSubscribe: false,
          buttonState: ButtonState.read,
          buttonText: isAudiobook ? 'Listen Now' : 'Read Now',
          shouldShowAddToCart: false,
          shouldShowUnlimitedAccessButton: false,
        );
      } else {
        // Premium limit exceeded
        return ContentAccessState(
          canRead: false,
          canPurchase: false,
          canSubscribe: subscriptionTier == 'Freebie',
          buttonState: subscriptionTier == 'Freebie'
              ? ButtonState.subscribe
              : ButtonState.upgrade,
          buttonText: subscriptionTier == 'Freebie'
              ? 'Subscribe for Access'
              : 'Upgrade Plan',
          shouldShowAddToCart: false,
          shouldShowUnlimitedAccessButton: false,
        );
      }
    }

    // ===== CASE 5: HYBRID CONTENT (can purchase OR access via subscription) =====
    if (price > 0 && !isPurchaseOnly) {
      if (withinNonFreeLimit) {
        // User has subscription access
        return ContentAccessState(
          canRead: true,
          canPurchase: false,
          canSubscribe: false,
          buttonState: ButtonState.read,
          buttonText: isAudiobook ? 'Listen Now' : 'Read Now',
          shouldShowAddToCart: false,
          shouldShowUnlimitedAccessButton: false,
        );
      } else {
        // User doesn't have subscription access - show "Buy Now" + "Get Unlimited Access"
        return ContentAccessState(
          canRead: false,
          canPurchase: true,
          canSubscribe: false,
          buttonState: ButtonState.purchase,
          buttonText: 'Buy Now - \$${price.toStringAsFixed(2)}',
          shouldShowAddToCart: true,
          shouldShowUnlimitedAccessButton: true,
        );
      }
    }

    // ===== DEFAULT FALLBACK =====
    return ContentAccessState(
      canRead: false,
      canPurchase: false,
      canSubscribe: false,
      buttonState: ButtonState.loginRequired,
      buttonText: 'Sign In',
      shouldShowAddToCart: false,
      shouldShowUnlimitedAccessButton: false,
    );
  }
}

/// Button state enum
enum ButtonState {
  read,
  purchase,
  subscribe,
  upgrade,
  loginRequired,
}

/// Content access state
class ContentAccessState {
  final bool canRead;
  final bool canPurchase;
  final bool canSubscribe;
  final ButtonState buttonState;
  final String buttonText;
  final bool shouldShowAddToCart;
  final bool shouldShowUnlimitedAccessButton;

  ContentAccessState({
    required this.canRead,
    required this.canPurchase,
    required this.canSubscribe,
    required this.buttonState,
    required this.buttonText,
    required this.shouldShowAddToCart,
    required this.shouldShowUnlimitedAccessButton,
  });
}

/// Content access info
class ContentAccessInfo {
  final String type;
  final String? fileType;
  final bool isFree;
  final bool isPurchased;
  final bool isPremiumOnly;
  final bool isPurchaseOnly;
  final double price;
  final bool? withinFreeLimit;
  final bool? withinNonFreeLimit;
  final String? userSubscriptionTier;

  ContentAccessInfo({
    required this.type,
    this.fileType,
    required this.isFree,
    required this.isPurchased,
    required this.isPremiumOnly,
    required this.isPurchaseOnly,
    required this.price,
    this.withinFreeLimit,
    this.withinNonFreeLimit,
    this.userSubscriptionTier,
  });

  bool get isEmpty => type.isEmpty;
}
