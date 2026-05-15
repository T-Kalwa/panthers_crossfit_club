import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:hive/hive.dart';

enum DemoUserRole { superAdmin, staff, scan, unknown }

class DemoAuthUser {
  final String matricule;
  final String nom;
  final String telephone;
  final String? email;
  final DemoUserRole role;

  const DemoAuthUser({
    required this.matricule,
    required this.nom,
    required this.telephone,
    this.email,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'matricule': matricule,
    'nom': nom,
    'telephone': telephone,
    'email': email,
    'role': role.name,
  };

  factory DemoAuthUser.fromJson(Map<String, dynamic> json) {
    return DemoAuthUser(
      matricule: json['matricule'] ?? '',
      nom: json['nom'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'],
      role: DemoUserRole.values.firstWhere((e) => e.name == json['role'], orElse: () => DemoUserRole.unknown),
    );
  }
}

class DemoAuthService {
  static final _db = FirebaseFirestore.instance;

  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Staff/Scan login — phone number only
  static Future<DemoAuthUser?> loginByPhone(String telephone) async {
    final phone = telephone.trim();
    if (phone.isEmpty) return null;

    try {
      final query = await _db.collection('members')
          .where('telephone', isEqualTo: phone)
          .where('role', whereIn: ['staff', 'scan'])
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final data = query.docs.first.data();
      final user = DemoAuthUser(
        matricule: data['matricule'] ?? '',
        nom: data['noms'] ?? '',
        telephone: data['telephone'] ?? '',
        email: data['email'],
        role: _parseRole(data['role']),
      );
      await saveSession(user);
      return user;
    } catch (e) {
      debugPrint('Login by phone error: $e');
      return null;
    }
  }

  /// Admin login — email + password (Firestore-based, no Firebase Auth needed)
  static Future<DemoAuthUser?> loginAdmin(String email, String password) async {
    final emailClean = email.trim().toLowerCase();
    if (emailClean.isEmpty || password.isEmpty) return null;

    try {
      final query = await _db.collection('members')
          .where('email', isEqualTo: emailClean)
          .where('role', isEqualTo: 'superAdmin')
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final data = query.docs.first.data();

      // Verify password
      final storedHash = data['passwordHash'] as String?;
      if (storedHash == null || storedHash != _hashPassword(password)) {
        return null;
      }

      final user = DemoAuthUser(
        matricule: data['matricule'] ?? '',
        nom: data['noms'] ?? '',
        telephone: data['telephone'] ?? '',
        email: data['email'],
        role: DemoUserRole.superAdmin,
      );
      await saveSession(user);
      return user;
    } catch (e) {
      debugPrint('Admin login error: $e');
      return null;
    }
  }

  static DemoUserRole _parseRole(String? role) {
    switch (role) {
      case 'superAdmin': return DemoUserRole.superAdmin;
      case 'staff': return DemoUserRole.staff;
      case 'scan': return DemoUserRole.scan;
      default: return DemoUserRole.unknown;
    }
  }

  // ─── SESSION MANAGEMENT ──────────────────────────────────────────
  static Future<void> saveSession(DemoAuthUser user) async {
    try {
      final box = await Hive.openBox('settings_box');
      await box.put('demo_auth_user', user.toJson());
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  static Future<DemoAuthUser?> loadSession() async {
    try {
      final box = await Hive.openBox('settings_box');
      final data = box.get('demo_auth_user');
      if (data != null && data is Map) {
        return DemoAuthUser.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      debugPrint('Error loading session: $e');
    }
    return null;
  }

  static Future<void> clearSession() async {
    try {
      final box = await Hive.openBox('settings_box');
      await box.delete('demo_auth_user');
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  /// Seed initial demo accounts in Firestore (no Firebase Auth)
  static Future<void> seedAccounts() async {
    try {
      await _seedAccount(
        matricule: 'ADMIN001',
        nom: 'Administrateur Panthers',
        telephone: '+243 000 000 000',
        email: 'admin@panthers.club',
        password: 'Admin1234',
        role: 'superAdmin',
      );
      await _seedAccount(
        matricule: 'PS001',
        nom: 'Staff Panthers',
        telephone: '+243 962 909 624',
        role: 'staff',
      );
      await _seedAccount(
        matricule: 'SCAN001',
        nom: 'Entrée Panthers',
        telephone: '+243 859 439 292',
        role: 'scan',
      );
      debugPrint('✅ Demo accounts seeded.');
    } catch (e) {
      debugPrint('❌ Error seeding accounts: $e');
    }
  }

  /// Create a new staff or scan account
  static Future<bool> createStaffAccount({
    required String nom,
    required String telephone,
    required String role, // 'staff' or 'scan'
    String? email,
    String? password,
  }) async {
    final prefix = role == 'scan' ? 'SCAN' : 'STAFF';
    final randomId = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final matricule = '$prefix-$randomId';

    try {
      await _seedAccount(
        matricule: matricule,
        nom: nom,
        telephone: telephone,
        role: role,
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      debugPrint('Error creating staff account: $e');
      return false;
    }
  }

  static Future<void> _seedAccount({
    required String matricule,
    required String nom,
    required String telephone,
    required String role,
    String? email,
    String? password,
  }) async {
    try {
      final existing = await _db.collection('members').doc(matricule).get();
      if (existing.exists) {
        debugPrint('ℹ️ $matricule already exists, skipping.');
        return;
      }

      final now = DateTime.now();
      final data = <String, dynamic>{
        'matricule': matricule,
        'noms': nom,
        'telephone': telephone,
        'role': role,
        'activite': 'ADMINISTRATION',
        'dureeForfait': 'illimité',
        'avecCoach': false,
        'montantPaye': 0,
        'dateDebut': now.toIso8601String(),
        'dateFin': now.add(const Duration(days: 3650)).toIso8601String(),
        'isActive': true,
      };

      if (email != null) data['email'] = email;
      if (password != null) data['passwordHash'] = _hashPassword(password);

      await _db.collection('members').doc(matricule).set(data);
      debugPrint('✅ Seeded: $matricule ($role)');
    } catch (e) {
      debugPrint('❌ Error seeding $matricule: $e');
    }
  }
}
