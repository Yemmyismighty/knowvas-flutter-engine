// Security settings models

class DeviceInfo {
  final int id;
  final String deviceName;
  final String deviceType;
  final String location;
  final String lastActive;
  final bool isCurrent;

  DeviceInfo({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.location,
    required this.lastActive,
    required this.isCurrent,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'],
      deviceName: json['device_name'] ?? json['deviceName'] ?? 'Unknown Device',
      deviceType: json['device_type'] ?? json['deviceType'] ?? 'Unknown',
      location: json['location'] ?? 'Unknown Location',
      lastActive: json['last_active'] ?? json['lastActive'] ?? 'Unknown',
      isCurrent: json['is_current'] ?? json['isCurrent'] ?? false,
    );
  }
}

class MfaStatus {
  final bool mfaEnabled;
  final String? mfaMethod;
  final String? lastUpdated;

  MfaStatus({
    required this.mfaEnabled,
    this.mfaMethod,
    this.lastUpdated,
  });

  factory MfaStatus.fromJson(Map<String, dynamic> json) {
    return MfaStatus(
      mfaEnabled: json['mfa_enabled'] ?? json['mfaEnabled'] ?? false,
      mfaMethod: json['mfa_method'] ?? json['mfaMethod'],
      lastUpdated: json['last_updated'] ?? json['lastUpdated'],
    );
  }
}

class PasswordChangeRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  PasswordChangeRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}
