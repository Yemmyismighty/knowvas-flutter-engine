// Billing/subscription settings models

class SubscriptionUsage {
  final int booksReadThisMonth;
  final int? bookLimitFree;
  final int? bookLimitNonFree;
  final int downloadsThisMonth;
  final int? downloadsLimit;
  final double storageUsedGB;
  final double? storageLimitGB;
  final int devicesConnected;
  final int deviceLimit;

  SubscriptionUsage({
    required this.booksReadThisMonth,
    this.bookLimitFree,
    this.bookLimitNonFree,
    required this.downloadsThisMonth,
    this.downloadsLimit,
    required this.storageUsedGB,
    this.storageLimitGB,
    required this.devicesConnected,
    required this.deviceLimit,
  });

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) {
    return SubscriptionUsage(
      booksReadThisMonth: json['books_read_this_month'] ?? json['booksReadThisMonth'] ?? 0,
      bookLimitFree: json['book_limit_free'] ?? json['bookLimitFree'],
      bookLimitNonFree: json['book_limit_non_free'] ?? json['bookLimitNonFree'],
      downloadsThisMonth: json['downloads_this_month'] ?? json['downloadsThisMonth'] ?? 0,
      downloadsLimit: json['downloads_limit'] ?? json['downloadsLimit'],
      storageUsedGB: (json['storage_used_gb'] ?? json['storageUsedGB'] ?? 0).toDouble(),
      storageLimitGB: json['storage_limit_gb'] != null 
          ? (json['storage_limit_gb']).toDouble() 
          : (json['storageLimitGB'] != null ? (json['storageLimitGB']).toDouble() : null),
      devicesConnected: json['devices_connected'] ?? json['devicesConnected'] ?? 0,
      deviceLimit: json['device_limit'] ?? json['deviceLimit'] ?? 1,
    );
  }

  String getBookLimitDisplay() {
    if (bookLimitFree == null && bookLimitNonFree == null) {
      return 'Unlimited';
    }
    if (bookLimitFree != null && bookLimitNonFree != null) {
      return '${bookLimitFree! + bookLimitNonFree!} books/month';
    }
    return 'Limited';
  }

  String getDownloadsLimitDisplay() {
    if (downloadsLimit == null) return 'Unlimited';
    return '$downloadsLimit/month';
  }

  String getStorageLimitDisplay() {
    if (storageLimitGB == null) return 'Unlimited';
    return '${storageLimitGB!.toStringAsFixed(1)} GB';
  }

  double? getBooksProgress() {
    if (bookLimitFree == null && bookLimitNonFree == null) return null;
    final total = (bookLimitFree ?? 0) + (bookLimitNonFree ?? 0);
    if (total == 0) return 0;
    return booksReadThisMonth / total;
  }

  double? getDownloadsProgress() {
    if (downloadsLimit == null) return null;
    if (downloadsLimit == 0) return 0;
    return downloadsThisMonth / downloadsLimit!;
  }

  double? getStorageProgress() {
    if (storageLimitGB == null) return null;
    if (storageLimitGB == 0) return 0;
    return storageUsedGB / storageLimitGB!;
  }
}

class CurrentSubscriptionInfo {
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

  CurrentSubscriptionInfo({
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
  });

  factory CurrentSubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return CurrentSubscriptionInfo(
      id: json['id'],
      tierName: json['tier_name'] ?? json['tierName'],
      tierLevel: json['tier_level'] ?? json['tierLevel'],
      planCode: json['plan_code'] ?? json['planCode'],
      price: json['price']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'active',
      startDate: json['start_date'] ?? json['startDate'],
      endDate: json['end_date'] ?? json['endDate'],
      renewalFlag: json['renewal_flag'] ?? json['renewalFlag'] ?? 'auto',
      benefits: List<String>.from(json['benefits'] ?? []),
    );
  }

  bool get isFreebie => tierName.toLowerCase() == 'freebie';
  bool get isActive => status.toLowerCase() == 'active';
}
