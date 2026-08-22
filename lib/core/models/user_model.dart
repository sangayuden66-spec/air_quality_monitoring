import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final bool notificationsEnabled;
  final int defaultAqiThreshold;
  final String role; // user | admin
  final String status; // active | disabled
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.notificationsEnabled = true,
    this.defaultAqiThreshold = 100,
    this.role = 'user',
    this.status = 'active',
    this.createdAt,
    this.lastActiveAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'notificationsEnabled': notificationsEnabled,
      'defaultAqiThreshold': defaultAqiThreshold,
      'role': role,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastActiveAt': lastActiveAt != null
          ? Timestamp.fromDate(lastActiveAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final rawRole = map['role'];
    final rawStatus = map['status'];
    final role = rawRole is String && rawRole.trim().isNotEmpty
        ? rawRole.trim().toLowerCase()
        : 'user';
    final status = rawStatus is String && rawStatus.trim().isNotEmpty
        ? rawStatus.trim().toLowerCase()
        : 'active';

    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      defaultAqiThreshold: map['defaultAqiThreshold'] ?? 100,
      role: role,
      status: status,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (map['lastActiveAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
