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
  });

  final String phoneNumber;
  final String? registrationToken;
  final String? otpReference;
  final String? kycReference;
  final bool otpVerified;
  final bool bvnVerified;
  final bool selfieCountdownEnabled;
  final int selfieCountdownSeconds;

  RegistrationSession copyWith({
    String? phoneNumber,
    String? registrationToken,
    String? otpReference,
    String? kycReference,
    bool? otpVerified,
    bool? bvnVerified,
    bool? selfieCountdownEnabled,
    int? selfieCountdownSeconds,
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
