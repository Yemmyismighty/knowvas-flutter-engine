// Subscription models matching the web app structure

class SubscriptionFeatures {
  final int deviceLimit;
  final int? bookLimitFree;
  final int? bookLimitNonFree;
  final bool adFree;
  final bool exclusiveComics;
  final bool earlyAccess;
  final bool offlineReading;
  final bool audiobooksAccess;

  SubscriptionFeatures({
    required this.deviceLimit,
    this.bookLimitFree,
    this.bookLimitNonFree,
    required this.adFree,
    required this.exclusiveComics,
    required this.earlyAccess,
    required this.offlineReading,
    required this.audiobooksAccess,
  });

  factory SubscriptionFeatures.fromJson(Map<String, dynamic> json) {
    return SubscriptionFeatures(
      deviceLimit: json['device_limit'] ?? 1,
      bookLimitFree: json['book_limit_free'],
      bookLimitNonFree: json['book_limit_non_free'],
      adFree: json['ad_free'] ?? false,
      exclusiveComics: json['exclusive_comics'] ?? false,
      earlyAccess: json['early_access'] ?? false,
      offlineReading: json['offline_reading'] ?? false,
      audiobooksAccess: json['audiobooks_access'] ?? false,
    );
  }
}

class SubscriptionPlan {
  final int id;
  final int tierId;
  final String tierName;
  final int tierLevel;
  final double price;
  final String currency;
  final String planCode;
  final String? countryCode;
  final List<String> benefits;
  final SubscriptionFeatures features;

  SubscriptionPlan({
    required this.id,
    required this.tierId,
    required this.tierName,
    required this.tierLevel,
    required this.price,
    required this.currency,
    required this.planCode,
    this.countryCode,
    required this.benefits,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      tierId: json['tier_id'],
      tierName: json['tier_name'],
      tierLevel: json['tier_level'],
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      planCode: json['plan_code'],
      countryCode: json['country_code'],
      benefits: List<String>.from(json['benefits'] ?? []),
      features: SubscriptionFeatures.fromJson(json['features'] ?? {}),
    );
  }
}

class CurrentSubscription {
  final int id;
  final String tierName;
  final int tierLevel;
  final String planCode;
  final double? price;
  final String currency;
  final String status;
  final String? startDate;
  final String? endDate;
  final String renewalFlag;
  final List<String> benefits;
  final SubscriptionFeatures features;
  final int? pendingUpgradePlanId;
  final int? pendingDowngradePlanId;

  CurrentSubscription({
    required this.id,
    required this.tierName,
    required this.tierLevel,
    required this.planCode,
    this.price,
    required this.currency,
    required this.status,
    this.startDate,
    this.endDate,
    required this.renewalFlag,
    required this.benefits,
    required this.features,
    this.pendingUpgradePlanId,
    this.pendingDowngradePlanId,
  });

  factory CurrentSubscription.fromJson(Map<String, dynamic> json) {
    return CurrentSubscription(
      id: json['id'],
      tierName: json['tier_name'],
      tierLevel: json['tier_level'],
      planCode: json['plan_code'],
      price: json['price']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      renewalFlag: json['renewal_flag'],
      benefits: List<String>.from(json['benefits'] ?? []),
      features: SubscriptionFeatures.fromJson(json['features'] ?? {}),
      pendingUpgradePlanId: json['pending_upgrade_plan_id'],
      pendingDowngradePlanId: json['pending_downgrade_plan_id'],
    );
  }
}

class SubscriptionInitiateResponse {
  final String authorizationUrl;
  final String action;
  final String? accessCode;
  final String? reference;

  SubscriptionInitiateResponse({
    required this.authorizationUrl,
    required this.action,
    this.accessCode,
    this.reference,
  });

  factory SubscriptionInitiateResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionInitiateResponse(
      authorizationUrl: json['authorization_url'],
      action: json['action'] ?? 'subscribe',
      accessCode: json['access_code'],
      reference: json['reference'],
    );
  }
}
