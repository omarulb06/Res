import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { client, owner, admin }

extension UserRoleX on UserRole {
  String get wire => name;
  String get label => switch (this) {
        UserRole.client => 'Client',
        UserRole.owner => 'Owner',
        UserRole.admin => 'Admin',
      };

  static UserRole parse(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'owner':
        return UserRole.owner;
      default:
        return UserRole.client;
    }
  }
}

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final UserRole role;
  final DateTime createdAt;
  final bool suspended;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    this.displayName,
    this.suspended = false,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isOwner => role == UserRole.owner;
  bool get isClient => role == UserRole.client;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role.wire,
        'createdAt': Timestamp.fromDate(createdAt),
        'suspended': suspended,
      };

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return AppUser(
      uid: id,
      email: (data['email'] ?? '') as String,
      displayName: data['displayName'] as String?,
      role: UserRoleX.parse(data['role'] as String?),
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
      suspended: (data['suspended'] ?? false) as bool,
    );
  }

  AppUser copyWith({UserRole? role, bool? suspended, String? displayName}) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt,
      suspended: suspended ?? this.suspended,
    );
  }
}
