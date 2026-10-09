class RegistrationSession {
  const RegistrationSession({
    required this.phoneNumber,
    this.registrationToken,
    this.otpReference,
    this.kycReference,
    this.otpVerified = false,
    this.bvnVerified = false,
  });

  final String phoneNumber;
  final String? registrationToken;
  final String? otpReference;
  final String? kycReference;
  final bool otpVerified;
  final bool bvnVerified;

  RegistrationSession copyWith({
    String? phoneNumber,
    String? registrationToken,
    String? otpReference,
    String? kycReference,
    bool? otpVerified,
    bool? bvnVerified,
  }) => RegistrationSession(
    phoneNumber: phoneNumber ?? this.phoneNumber,
    registrationToken: registrationToken ?? this.registrationToken,
    otpReference: otpReference ?? this.otpReference,
    kycReference: kycReference ?? this.kycReference,
    otpVerified: otpVerified ?? this.otpVerified,
    bvnVerified: bvnVerified ?? this.bvnVerified,
  );
}

class RegistrationStart {
  const RegistrationStart({
    required this.registrationToken,
    required this.phoneNumber,
    required this.requiresOtp,
  });

  factory RegistrationStart.fromJson(Map<String, dynamic> json) =>
      RegistrationStart(
        registrationToken: json['registrationToken'].toString(),
        phoneNumber: json['phoneNumber'].toString(),
        requiresOtp: json['requiresOtp'] == true,
      );

  final String registrationToken;
  final String phoneNumber;
  final bool requiresOtp;
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
  });

  factory BvnVerification.fromJson(Map<String, dynamic> json) =>
      BvnVerification(
        kycReference: json['kycReference'].toString(),
        bvnVerified: json['bvnVerified'] == true,
      );

  final String kycReference;
  final bool bvnVerified;
}
