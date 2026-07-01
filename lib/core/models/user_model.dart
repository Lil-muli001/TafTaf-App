enum UserRole { owner, client }

class UserModel {
  final String id;
  final String username;
  final String email;
  final String phone;
  final UserRole role;
  final String? profilePic;
  final String? coverPhoto;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePic,
    this.coverPhoto,
    required this.createdAt,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isClient => role == UserRole.client;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] == 'owner' ? UserRole.owner : UserRole.client,
      profilePic: json['profilePic'] as String?,
      coverPhoto: json['coverPhoto'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'phone': phone,
        'role': role == UserRole.owner ? 'owner' : 'client',
        'profilePic': profilePic,
        'coverPhoto': coverPhoto,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    UserRole? role,
    String? profilePic,
    String? coverPhoto,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profilePic: profilePic ?? this.profilePic,
      coverPhoto: coverPhoto ?? this.coverPhoto,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
