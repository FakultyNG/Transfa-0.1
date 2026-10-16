class RegistrationSession {
  const RegistrationSession({
    required this.phoneNumber,
    this.registrationToken,
    this.otpReference,
    this.kycReference,
    this.otpVerified = false,
    this.bvnVerified = false,
    this.selfieCountdownEnabled = true,
    this.selfieCountdownSeconds = 5,
    this.selfieMode = 'static',
  });

  final String phoneNumber;
  final String? registrationToken;
  final String? otpReference;
  final String? kycReference;
  final bool otpVerified;
  final bool bvnVerified;
  final bool selfieCountdownEnabled;
  final int selfieCountdownSeconds;
  final String selfieMode;

  RegistrationSession copyWith({
    String? phoneNumber,
    String? registrationToken,
    String? otpReference,
    String? kycReference,
    bool? otpVerified,
    bool? bvnVerified,
    bool? selfieCountdownEnabled,
    int? selfieCountdownSeconds,
    String? selfieMode,
  }) => RegistrationSession(
    phoneNumber: phoneNumber ?? this.phoneNumber,
    registrationToken: registrationToken ?? this.registrationToken,
    otpReference: otpReference ?? this.otpReference,
    kycReference: kycReference ?? this.kycReference,
    otpVerified: otpVerified ?? this.otpVerified,
    bvnVerified: bvnVerified ?? this.bvnVerified,
    selfieCountdownEnabled:
        selfieCountdownEnabled ?? this.selfieCountdownEnabled,
    selfieCountdownSeconds:
        selfieCountdownSeconds ?? this.selfieCountdownSeconds,
    selfieMode: selfieMode ?? this.selfieMode,
  );
}

class RegistrationStart {
  const RegistrationStart({
    required this.registrationToken,
    required this.phoneNumber,
    required this.requiresOtp,
    required this.otpReference,
  });

  factory RegistrationStart.fromJson(Map<String, dynamic> json) =>
      RegistrationStart(
        registrationToken: json['registrationToken'].toString(),
        phoneNumber: json['phoneNumber'].toString(),
        requiresOtp: json['requiresOtp'] == true,
        otpReference: json['otpReference'].toString(),
      );

  final String registrationToken;
  final String phoneNumber;
  final bool requiresOtp;
  final String otpReference;
}

class OtpChallenge {
  const OtpChallenge({required this.phoneNumber, required this.otpReference});

  factory OtpChallenge.fromJson(Map<String, dynamic> json) => OtpChallenge(
    phoneNumber: json['phoneNumber'].toString(),
    otpReference: json['otpReference'].toString(),
  );

  final String phoneNumber;
  final String otpReference;
}

class FaceUnlockConfig {
  const FaceUnlockConfig({
    required this.enabled,
    required this.countdownEnabled,
    required this.countdownSeconds,
    required this.maxAttempts,
    required this.lockoutSeconds,
  });

  factory FaceUnlockConfig.fromJson(Map<String, dynamic> json) =>
      FaceUnlockConfig(
        enabled: json['enabled'] == true,
        countdownEnabled: json['countdownEnabled'] != false,
        countdownSeconds: (json['countdownSeconds'] as num?)?.toInt() ?? 5,
        maxAttempts: (json['maxAttempts'] as num?)?.toInt() ?? 3,
        lockoutSeconds: (json['lockoutSeconds'] as num?)?.toInt() ?? 3600,
      );

  final bool enabled;
  final bool countdownEnabled;
  final int countdownSeconds;
  final int maxAttempts;
  final int lockoutSeconds;
}

class BvnVerification {
  const BvnVerification({
    required this.kycReference,
    required this.bvnVerified,
    this.bvnMasked,
    this.firstName,
    this.middleName,
    this.lastName,
    this.country,
    this.dateOfBirth,
  });

  factory BvnVerification.fromJson(Map<String, dynamic> json) =>
      BvnVerification(
        kycReference: json['kycReference'].toString(),
        bvnVerified: json['bvnVerified'] == true,
        bvnMasked: _stringValue(json, 'bvnMasked', 'bvn_masked'),
        firstName: _stringValue(json, 'firstName', 'first_name'),
        middleName: _stringValue(json, 'middleName', 'middle_name'),
        lastName: _stringValue(json, 'lastName', 'last_name'),
        country: _stringValue(json, 'country', 'nationality'),
        dateOfBirth: _stringValue(json, 'dateOfBirth', 'date_of_birth'),
      );

  final String kycReference;
  final bool bvnVerified;
  final String? bvnMasked;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? country;
  final String? dateOfBirth;

  String get fullName => [firstName, middleName, lastName]
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(' ');

  static String? _stringValue(
    Map<String, dynamic> json,
    String camelCaseKey,
    String alternateKey,
  ) {
    final value = json[camelCaseKey] ?? json[alternateKey];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class SelfieVerification {
  const SelfieVerification({
    required this.kycStatus,
    required this.faceMatch,
    required this.confidenceScore,
    this.faceMatchStatus,
    this.faceMatchReason,
    this.livenessStatus,
    this.profileImageUrl,
  });

  factory SelfieVerification.fromJson(Map<String, dynamic> json) =>
      SelfieVerification(
        kycStatus: json['kycStatus']?.toString() ?? 'rejected',
        faceMatch: json['faceMatch'] == true,
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0,
        faceMatchStatus: _optionalString(json['faceMatchStatus']),
        faceMatchReason: _optionalString(json['faceMatchReason']),
        livenessStatus: _optionalString(json['livenessStatus']),
        profileImageUrl: _optionalString(json['profileImageUrl']),
      );

  final String kycStatus;
  final bool faceMatch;
  final double confidenceScore;
  final String? faceMatchStatus;
  final String? faceMatchReason;
  final String? livenessStatus;
  final String? profileImageUrl;

  bool get isVerified => faceMatch && kycStatus == 'verified';

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class LivenessSession {
  const LivenessSession({
    required this.id,
    required this.status,
    required this.url,
    this.expiresAt,
  });

  factory LivenessSession.fromJson(Map<String, dynamic> json) =>
      LivenessSession(
        id: json['livenessSessionId'].toString(),
        status: json['status'].toString(),
        url: json['url'].toString(),
        expiresAt: json['expiresAt']?.toString(),
      );

  final String id;
  final String status;
  final String url;
  final String? expiresAt;
}

class LivenessStatus {
  const LivenessStatus({
    required this.id,
    required this.status,
    required this.reasons,
    required this.usableForFaceMatch,
    this.score,
    this.expiresAt,
  });

  factory LivenessStatus.fromJson(Map<String, dynamic> json) => LivenessStatus(
    id: json['livenessSessionId'].toString(),
    status: json['status'].toString(),
    reasons: (json['reasons'] as List<dynamic>? ?? const [])
        .map((reason) => reason.toString())
        .toList(growable: false),
    usableForFaceMatch: json['usableForFaceMatch'] == true,
    score: (json['score'] as num?)?.toDouble(),
    expiresAt: json['expiresAt']?.toString(),
  );

  final String id;
  final String status;
  final List<String> reasons;
  final bool usableForFaceMatch;
  final double? score;
  final String? expiresAt;
}
