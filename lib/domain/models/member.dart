class Member {
  final String id;
  final String username;
  final String phoneNumber;
  final String fullName;
  final DateTime registrationDate;
  final bool isActive;
  final String? qrCodeData;
  final String? profileImageUrl;

  Member({
    required this.id,
    required this.username,
    required this.phoneNumber,
    required this.fullName,
    required this.registrationDate,
    this.isActive = true,
    this.qrCodeData,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'registrationDate': registrationDate.toIso8601String(),
      'isActive': isActive,
      'qrCodeData': qrCodeData,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      username: json['username'],
      phoneNumber: json['phoneNumber'],
      fullName: json['fullName'],
      registrationDate: DateTime.parse(json['registrationDate']),
      isActive: json['isActive'] ?? true,
      qrCodeData: json['qrCodeData'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Member copyWith({
    String? id,
    String? username,
    String? phoneNumber,
    String? fullName,
    DateTime? registrationDate,
    bool? isActive,
    String? qrCodeData,
    String? profileImageUrl,
  }) {
    return Member(
      id: id ?? this.id,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      registrationDate: registrationDate ?? this.registrationDate,
      isActive: isActive ?? this.isActive,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
