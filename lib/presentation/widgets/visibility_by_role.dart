import 'package:flutter/material.dart';
import '../../domain/models/user_role.dart';

class VisibilityByRole extends StatelessWidget {
  final Widget child;
  final UserRole currentRole;
  final List<UserRole> allowedRoles;
  final Widget? fallback;

  const VisibilityByRole({
    super.key,
    required this.child,
    required this.currentRole,
    required this.allowedRoles,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (allowedRoles.contains(currentRole)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

/// Helper function to check permission easily in UI logic
bool hasPermission(UserRole role, List<UserRole> allowed) {
  return allowed.contains(role);
}
