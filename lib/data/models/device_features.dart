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

class CashDropConfig {
  const CashDropConfig({
    required this.featureEnabled,
    required this.kycSelfieRequired,
    required this.kycSelfieMode,
    required this.selfieCountdownEnabled,
    required this.selfieCountdownSeconds,
  });

  factory CashDropConfig.fromJson(Map<String, dynamic> json) => CashDropConfig(
    featureEnabled: json['featureEnabled'] == true,
    kycSelfieRequired: json['kycSelfieRequired'] == true,
    kycSelfieMode: json['kycSelfieMode']?.toString() ?? 'static',
    selfieCountdownEnabled: json['selfieCountdownEnabled'] != false,
    selfieCountdownSeconds:
        (json['selfieCountdownSeconds'] as num?)?.toInt() ?? 5,
  );

  final bool featureEnabled;
  final bool kycSelfieRequired;
  final String kycSelfieMode;
  final bool selfieCountdownEnabled;
  final int selfieCountdownSeconds;
}

class CashDropStatus {
  const CashDropStatus({
    required this.enabled,
    required this.status,
    this.featureEnabled = true,
    this.id,
    this.profileImageUrl,
  });

  factory CashDropStatus.fromJson(Map<String, dynamic> json) => CashDropStatus(
    featureEnabled: json['featureEnabled'] != false,
    enabled:
        json['featureEnabled'] != false &&
        (json['enabled'] == true || json['status'] == 'active'),
    status: (json['status'] ?? 'disabled').toString(),
    id: (json['CashDropId'] ?? json['cashDropId'])?.toString(),
    profileImageUrl: json['profileImageUrl']?.toString(),
  );

  final bool featureEnabled;
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
