/// API endpoint constants
class ApiConstants {
  ApiConstants._();

  // Base URL - should be configured via environment variables
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend.knowvas.com',
  );

  // Auth endpoints - Using unified API (supports both web and mobile)
  static const String login = '/api/auth/login';  // Unified endpoint with use_jwt flag
  static const String signup = '/api/auth/signup';  // Unified endpoint
  static const String verifyEmail = '/api/auth/verify-email';  // Email verification
  static const String resendVerification = '/api/auth/resend-verification-email';  // Resend code
  static const String refresh = '/api/auth/refresh';  // Token refresh
  static const String logout = '/api/auth/signout';  // Logout
  static const String forgotPassword = '/api/auth/forgot-password';  // Password reset request
  static const String resetPassword = '/api/auth/reset-password';  // Password reset with code
  static const String profile = '/api/auth/me';  // Get current user profile
  static const String completeProfile = '/api/auth/complete-profile';  // Complete profile (DOB, gender, city)
  static const String googleLogin = '/api/auth/google-login';  // Google OAuth login/signup
  static const String cities = '/api/auth/cities';  // Cities by country code

  // Content endpoints
  static const String content = '/api/contents';
  static const String search = '/api/discover/search';
  static const String discover = '/api/discover';
  static const String homepage = '/api/user/homepage-content';
  static const String feed = '/api/discover/feed';

  // Library endpoints
  static const String library = '/api/user/library';
  static const String collections = '/api/user/library/collections';

  // Download endpoints
  static const String downloadRequest = '/api/contents/download/request';

  // Engagement endpoints
  static const String engagementLog = '/api/engagement/log';

  // Cart endpoints
  static const String cart = '/api/cart/items';
  static const String cartAdd = '/api/cart/add';
  static const String cartRemove = '/api/cart/remove';
  static const String cartUpdate = '/api/cart/update';

  // Purchase endpoints
  static const String purchase = '/api/purchase/initiate-payment';

  // Subscription endpoints
  static const String subscriptionPlans = '/api/subscription/plans';
  static const String subscribe = '/api/subscription/subscribe';
  static const String activeSubscription = '/api/subscription/active';
  static const String cancelSubscription = '/api/subscription/cancel';

  // Author endpoints
  static const String authors = '/api/author';

  // Follow endpoints
  static const String follow = '/api/user/follow';
  static const String following = '/api/user/following';
  static const String followers = '/api/user/followers';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
