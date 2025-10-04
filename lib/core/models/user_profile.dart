class UserProfile {
  final int? id;
  final String fullName;
  final String? phone;
  final String? address;
  final String? logoPath; // Path to profile photo/logo
  final String? businessName;
  final String? tradingActivity;
  final DateTime createdDate;
  final DateTime? updatedDate;

  UserProfile({
    this.id,
    required this.fullName,
    this.phone,
    this.address,
    this.logoPath,
    this.businessName,
    this.tradingActivity,
    required this.createdDate,
    this.updatedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'logoPath': logoPath,
      'businessName': businessName,
      'tradingActivity': tradingActivity,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'updatedDate': updatedDate?.millisecondsSinceEpoch,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      fullName: map['fullName'] ?? '',
      phone: map['phone'],
      address: map['address'],
      logoPath: map['logoPath'],
      businessName: map['businessName'],
      tradingActivity: map['tradingActivity'],
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate']),
      updatedDate: map['updatedDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedDate'])
          : null,
    );
  }

  UserProfile copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? address,
    String? logoPath,
    String? businessName,
    String? tradingActivity,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
      businessName: businessName ?? this.businessName,
      tradingActivity: tradingActivity ?? this.tradingActivity,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  @override
  String toString() {
    return 'UserProfile{id: $id, fullName: $fullName, phone: $phone, businessName: $businessName, tradingActivity: $tradingActivity}';
  }
}