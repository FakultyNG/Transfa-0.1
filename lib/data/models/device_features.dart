class BiometricStatus {
  const BiometricStatus({required this.enabled, this.method, this.deviceId});

  factory BiometricStatus.fromJson(Map<String, dynamic> json) =>
      BiometricStatus(
        enabled: json['enabled'] == true,
        method: json['method']?.toString(),
        deviceId: json['deviceId']?.toString(),
      );

  final bool enabled;
  final String? method;
  final String? deviceId;
}

class CashDropStatus {
  const CashDropStatus({
    required this.enabled,
    required this.status,
    this.id,
    this.profileImageUrl,
  });

  factory CashDropStatus.fromJson(Map<String, dynamic> json) => CashDropStatus(
    enabled: json['enabled'] == true || json['status'] == 'active',
    status: (json['status'] ?? 'disabled').toString(),
    id: (json['CashDropId'] ?? json['cashDropId'])?.toString(),
    profileImageUrl: json['profileImageUrl']?.toString(),
  );

  final bool enabled;
  final String status;
  final String? id;
  final String? profileImageUrl;
}

class CashDropMatch {
  const CashDropMatch({
    required this.receiverId,
    required this.displayName,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.matchConfidence,
    this.profileImageUrl,
  });

  factory CashDropMatch.fromJson(Map<String, dynamic> json) => CashDropMatch(
    receiverId: json['receiverId'].toString(),
    displayName: json['displayName'].toString(),
    bankName: json['bankName'].toString(),
    accountNumber: json['accountNumber'].toString(),
    accountName: json['accountName'].toString(),
    matchConfidence: (json['matchConfidence'] as num?)?.toDouble() ?? 0,
    profileImageUrl: json['profileImageUrl']?.toString(),
  );

  final String receiverId;
  final String displayName;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final double matchConfidence;
  final String? profileImageUrl;
}
