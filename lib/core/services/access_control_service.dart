import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class UserAccessState {
  final String uid;
  final String role;
  final String status;

  const UserAccessState({
    required this.uid,
    required this.role,
    required this.status,
  });

  String get normalizedRole => role.trim().toLowerCase();
  String get normalizedStatus => status.trim().toLowerCase();
  bool get isActive => normalizedStatus == 'active';
  bool get isDisabled => normalizedStatus == 'disabled';
  bool get isIT => normalizedRole == 'it';
  bool get canAccessITRoutes => isIT && isActive;
  bool get isAdmin => normalizedRole == 'admin';
  bool get canAccessAdminRoutes => isAdmin && isActive;

  factory UserAccessState.fromUserModel(UserModel model) {
    return UserAccessState(
      uid: model.uid,
      role: model.role,
      status: model.status,
    );
  }
}

class AccessControlService {
  AccessControlService({UserService? userService, FirebaseAuth? auth})
    : _userService = userService ?? UserService(),
      _auth = auth ?? FirebaseAuth.instance;

  final UserService _userService;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  Stream<UserAccessState?> watchUserAccessByUid(String uid) {
    if (uid.trim().isEmpty) return Stream.value(null);
    return _userService.watchUserById(uid).map((user) {
      if (user == null) return null;
      final access = UserAccessState.fromUserModel(user);
      debugPrint(
        'AccessControlService uid=${access.uid} role=${access.role} status=${access.status}',
      );
      return access;
    });
  }

  Stream<UserAccessState?> watchCurrentUserAccess() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return watchUserAccessByUid(uid);
  }

  Future<UserAccessState?> getCurrentUserAccess() async {
    final user = await _userService.getCurrentUserDataOnce();
    if (user == null) return null;
    return UserAccessState.fromUserModel(user);
  }

  Future<bool> canCurrentUserAccessAdminRoutes() async {
    final access = await getCurrentUserAccess();
    return access?.canAccessAdminRoutes ?? false;
  }
}
