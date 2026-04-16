/// Unified API Constants for Knowvas Flutter Client
/// 
/// This file contains updated API endpoints that use the unified authentication system.
/// These endpoints support JWT token authentication and replace the old /api/mobile/v1/ routes.
/// 
/// Migration: Replace the old api_constants.dart with this file after testing.

class ApiConstants {
  // Base configuration
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  // ============================================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================================
  
  /// Login endpoint - supports JWT authentication
  /// Request body must include: { "email": "...", "password": "...", "use_jwt": true }
  /// Returns: { "access_token": "...", "refresh_token": "...", "user": {...} }
  static const String login = '/api/auth/login';
  
  /// Signup endpoint - creates account and sends verification code
  /// Request body: { "firstname": "...", "lastname": "...", "email": "...", "password": "..." }
  /// Returns: { "message": "...", "email": "..." }
  static const String signup = '/api/auth/signup';
  
  /// Email verification endpoint - verifies code and creates account
  /// Request body must include: { "email": "...", "code": "...", "use_jwt": true }
  /// Returns: { "access_token": "...", "refresh_token": "...", "user": {...} }
  static const String verifyEmail = '/api/auth/verify-email';
  
  /// Resend verification code
  /// Request body: { "email": "..." }
  static const String resendVerification = '/api/auth/resend-verification-email';
  
  /// Refresh access token
  /// Request body: { "refresh_token": "..." }
  /// Returns: { "access_token": "...", "refresh_token": "..." }
  static const String refresh = '/api/auth/refresh';
  
  /// Logout endpoint
  static const String logout = '/api/auth/signout';
  
  /// Forgot password - sends reset code
  /// Request body: { "email": "..." }
  static const String forgotPassword = '/api/auth/forgot-password';
  
  /// Reset password with code
  /// Request body: { "token": "...", "new_password": "..." }
  static const String resetPassword = '/api/auth/reset-password';
  
  /// Get current user profile
  /// Requires: Authorization header with Bearer token
  static const String profile = '/api/auth/me';
  
  /// Complete user profile (DOB, gender, city)
  /// Request body: { "dateOfBirth": "...", "gender": "...", "city": "..." }
  static const String completeProfile = '/api/auth/complete-profile';

  // ============================================================================
  // USER ENDPOINTS
  // ============================================================================
  
  /// Get user's library (purchased and subscribed content)
  static const String library = '/api/user/library';
  
  /// Get user's wishlist
  static const String wishlist = '/api/user/wishlist';
  
  /// Add to wishlist
  /// Request body: { "resource_id": 123 }
  static const String addToWishlist = '/api/user/wishlist/add';
  
  /// Remove from wishlist
  static const String removeFromWishlist = '/api/user/wishlist/remove';
  
  /// Get user's reading history
  static const String readingHistory = '/api/user/reading-history';
  
  /// Get user's devices
  static const String devices = '/api/user/devices';
  
  /// Update user profile
  static const String updateProfile = '/api/user/profile';
  
  /// Get user's homepage content (personalized)
  static const String homepage = '/api/user/homepage-content';

  // ============================================================================
  // CONTENT ENDPOINTS
  // ============================================================================
  
  /// Get content by ID
  /// Path: /api/content/{id}
  static String contentById(int id) => '/api/content/$id';
  
  /// Get content manifest (for books)
  /// Path: /api/contents/books/{id}/manifest.json
  static String contentManifest(int id) => '/api/contents/books/$id/manifest.json';
  
  /// Get content PDF
  /// Path: /api/contents/{id}/pdf/proxy
  static String contentPdf(int id) => '/api/contents/$id/pdf/proxy';
  
  /// Get content preview PDF
  /// Path: /api/contents/{id}/preview/pdf
  static String contentPreviewPdf(int id) => '/api/contents/$id/preview/pdf';
  
  /// Check content access
  /// Path: /api/contents/{id}/check-access
  static String checkContentAccess(int id) => '/api/contents/$id/check-access';

  // ============================================================================
  // DISCOVER ENDPOINTS
  // ============================================================================
  
  /// Search content
  /// Query params: ?q=search_term&type=book&page=1&limit=20
  static const String search = '/api/discover/search';
  
  /// Get discover page content (featured, trending, etc.)
  static const String discover = '/api/discover';
  
  /// Get content by category
  /// Path: /api/discover/category/{category_name}
  static String discoverByCategory(String category) => '/api/discover/category/$category';
  
  /// Get trending content
  static const String trending = '/api/discover/trending';
  
  /// Get new releases
  static const String newReleases = '/api/discover/new-releases';

  // ============================================================================
  // CART ENDPOINTS
  // ============================================================================
  
  /// Get user's cart
  static const String cart = '/api/cart';
  
  /// Add item to cart
  /// Request body: { "resource_id": 123, "quantity": 1 }
  static const String cartAdd = '/api/cart/add';
  
  /// Remove item from cart
  /// Request body: { "resource_id": 123 }
  static const String cartRemove = '/api/cart/remove';
  
  /// Update cart item quantity
  /// Request body: { "resource_id": 123, "quantity": 2 }
  static const String cartUpdate = '/api/cart/update';
  
  /// Clear entire cart
  static const String cartClear = '/api/cart/clear';

  // ============================================================================
  // PURCHASE ENDPOINTS
  // ============================================================================
  
  /// Initialize purchase
  /// Request body: { "items": [...], "currency": "NGN" }
  static const String purchase = '/api/purchase/initialize';
  
  /// Verify purchase
  /// Path: /api/purchase/verify/{reference}
  static String verifyPurchase(String reference) => '/api/purchase/verify/$reference';
  
  /// Get purchase history
  static const String purchaseHistory = '/api/purchase/history';

  // ============================================================================
  // SUBSCRIPTION ENDPOINTS
  // ============================================================================
  
  /// Get available subscription plans
  static const String subscriptionPlans = '/api/subscription/plans';
  
  /// Subscribe to a plan
  /// Request body: { "plan_id": 123, "currency": "NGN" }
  static const String subscribe = '/api/subscription/subscribe';
  
  /// Get active subscription
  static const String activeSubscription = '/api/subscription/active';
  
  /// Cancel subscription
  static const String cancelSubscription = '/api/subscription/cancel';
  
  /// Get subscription history
  static const String subscriptionHistory = '/api/subscription/history';

  // ============================================================================
  // READING PROGRESS ENDPOINTS
  // ============================================================================
  
  /// Save reading progress
  /// Request body: { "resource_id": 123, "progress": 45.5, "current_page": 120 }
  static const String saveProgress = '/api/reading-progress/save';
  
  /// Get reading progress for a resource
  /// Path: /api/reading-progress/{resource_id}
  static String getProgress(int resourceId) => '/api/reading-progress/$resourceId';
  
  /// Save PDF reading progress
  /// Request body: { "resource_id": 123, "page_number": 45, "total_pages": 200 }
  static const String savePdfProgress = '/api/pdf-progress/save';
  
  /// Get PDF reading progress
  /// Path: /api/pdf-progress/{resource_id}
  static String getPdfProgress(int resourceId) => '/api/pdf-progress/$resourceId';

  // ============================================================================
  // AUTHOR ENDPOINTS
  // ============================================================================
  
  /// Get author by ID
  /// Path: /api/author/{id}
  static String authorById(int id) => '/api/author/$id';
  
  /// Get author's content
  /// Path: /api/author/{id}/content
  static String authorContent(int id) => '/api/author/$id/content';
  
  /// Follow/unfollow author
  /// Request body: { "author_id": 123 }
  static const String followAuthor = '/api/user/follow';

  // ============================================================================
  // REVIEW & RATING ENDPOINTS
  // ============================================================================
  
  /// Rate content
  /// Request body: { "resource_id": 123, "rating": 4.5 }
  static const String rateContent = '/api/content/rate';
  
  /// Review content
  /// Request body: { "resource_id": 123, "rating": 4.5, "review_text": "..." }
  static const String reviewContent = '/api/content/review';
  
  /// Get content reviews
  /// Path: /api/content/{id}/reviews
  static String contentReviews(int id) => '/api/content/$id/reviews';

  // ============================================================================
  // UTILITY ENDPOINTS
  // ============================================================================
  
  /// Health check
  static const String health = '/api/health';
  
  /// Get user's currency
  static const String currency = '/api/auth/currency';
  
  /// Get cities by country
  /// Path: /api/auth/cities/{country_code}
  static String cities(String countryCode) => '/api/auth/cities/$countryCode';
  
  /// Contact support
  /// Request body: { "name": "...", "email": "...", "message": "..." }
  static const String contact = '/api/contact';
  
  /// Newsletter subscription
  /// Request body: { "email": "..." }
  static const String newsletter = '/api/newsletter/subscribe';

  // ============================================================================
  // REQUEST CONFIGURATION
  // ============================================================================
  
  /// Default timeout for API requests (in seconds)
  static const int defaultTimeout = 30;
  
  /// Timeout for file downloads (in seconds)
  static const int downloadTimeout = 300;
  
  /// Timeout for file uploads (in seconds)
  static const int uploadTimeout = 120;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get full URL for an endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  /// Get authorization header with Bearer token
  static Map<String, String> getAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  /// Get standard headers without auth
  static Map<String, String> getStandardHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }
}
