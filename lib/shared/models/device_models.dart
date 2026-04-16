class Device {
  final int id;
  final String deviceName;
  final String? createdAt;
  final String? lastUsed;
  final bool isCurrent;

  Device({
    required this.id,
    required this.deviceName,
    this.createdAt,
    this.lastUsed,
    required this.isCurrent,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? 0,
      deviceName: json['device_name'] ?? json['deviceName'] ?? 'Unknown Device',
      createdAt: json['created_at'] ?? json['createdAt'],
      lastUsed: json['last_used'] ?? json['lastUsed'],
      isCurrent: json['is_current'] ?? json['isCurrent'] ?? false,
    );
  }
}
