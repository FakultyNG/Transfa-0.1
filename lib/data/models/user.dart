class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final bool isVerified;
  final String? avatarUrl;
  final String? kycStatus;
  final String? walletStatus;
  final String? dateOfBirth;
  final String? gender;
  final String? country;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.isVerified,
    this.avatarUrl,
    this.kycStatus,
    this.walletStatus,
    this.dateOfBirth,
    this.gender,
    this.country,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'].toString(),
    fullName:
        (json['full_name'] ??
                json['fullName'] ??
                [
                  json['firstName'],
                  json['lastName'],
                ].where((part) => part != null).join(' '))
            .toString(),
    email: (json['email'] ?? '').toString(),
    phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
    isVerified:
        json['is_verified'] == true ||
        json['isVerified'] == true ||
        json['kycStatus'] == 'verified',
    avatarUrl:
        (json['profileImageUrl'] ?? json['avatar_url'] ?? json['avatarUrl'])
            ?.toString(),
    kycStatus: json['kycStatus']?.toString(),
    walletStatus: json['walletStatus']?.toString(),
    dateOfBirth: json['dateOfBirth']?.toString(),
    gender: json['gender']?.toString(),
    country: json['country']?.toString(),
  );

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    bool? isVerified,
    String? avatarUrl,
    String? kycStatus,
    String? walletStatus,
    String? dateOfBirth,
    String? gender,
    String? country,
  }) => AppUser(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    isVerified: isVerified ?? this.isVerified,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    kycStatus: kycStatus ?? this.kycStatus,
    walletStatus: walletStatus ?? this.walletStatus,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
    country: country ?? this.country,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'is_verified': isVerified,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (kycStatus != null) 'kycStatus': kycStatus,
    if (walletStatus != null) 'walletStatus': walletStatus,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
    if (gender != null) 'gender': gender,
    if (country != null) 'country': country,
  };
}
