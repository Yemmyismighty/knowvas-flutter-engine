import 'package:equatable/equatable.dart';

/// Subscription plan model
class SubscriptionPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final Map<String, double> monthlyPrice;
  final Map<String, double> annualPrice;
  final List<String> features;
  final int trialDays;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.features,
    this.trialDays = 0,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      monthlyPrice: (json['monthly_price'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      annualPrice: (json['annual_price'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      features: (json['features'] as List<dynamic>).map((e) => e.toString()).toList(),
      trialDays: json['trial_days'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthly_price': monthlyPrice,
      'annual_price': annualPrice,
      'features': features,
      'trial_days': trialDays,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        monthlyPrice,
        annualPrice,
        features,
        trialDays,
      ];
}

/// Active subscription model
class ActiveSubscription extends Equatable {
  final String id;
  final String planId;
  final String planName;
  final String status; // 'active', 'cancelled', 'expired', 'trial'
  final DateTime startDate;
  final DateTime renewalDate;
  final DateTime? cancelledAt;
  final bool autoRenew;
  final String billingCycle; // 'monthly', 'annual'

  const ActiveSubscription({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.renewalDate,
    this.cancelledAt,
    this.autoRenew = true,
    required this.billingCycle,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    return ActiveSubscription(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      planName: json['plan_name'] as String,
      status: json['status'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      renewalDate: DateTime.parse(json['renewal_date'] as String),
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'] as String)
          : null,
      autoRenew: json['auto_renew'] as bool? ?? true,
      billingCycle: json['billing_cycle'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'plan_name': planName,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'renewal_date': renewalDate.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'auto_renew': autoRenew,
      'billing_cycle': billingCycle,
    };
  }

  @override
  List<Object?> get props => [
        id,
        planId,
        planName,
        status,
        startDate,
        renewalDate,
        cancelledAt,
        autoRenew,
        billingCycle,
      ];
}
