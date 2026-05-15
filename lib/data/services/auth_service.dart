import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../../domain/models/user_role.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key';

  /// --- HIVE ENCRYPTION ---
  /// Initialise ou récupère la clé de chiffrement AES-256 stockée de manière sécurisée.
  static Future<Uint8List> getOrCreateEncryptionKey() async {
    final containsKey = await _storage.containsKey(key: _keyName);
    
    if (!containsKey) {
      // Génération d'une nouvelle clé sécurisée (32 octets / 256 bits pour AES)
      final key = Hive.generateSecureKey();
      await _storage.write(key: _keyName, value: base64UrlEncode(key));
      return Uint8List.fromList(key);
    } else {
      // Récupération de la clé existante
      final base64Key = await _storage.read(key: _keyName);
      return base64Url.decode(base64Key!);
    }
  }

  /// --- RBAC (Contrôle d'Accès basé sur les Rôles) ---
  
  /// L'utilisateur peut-il gérer d'autres utilisateurs / matricules ?
  static bool canManageUsers(UserRole role) {
    return role == UserRole.superAdmin;
  }

  /// L'utilisateur peut-il scanner des QR codes à l'entrée ?
  static bool canScanQR(UserRole role) {
    return role == UserRole.staff || role == UserRole.superAdmin;
  }

  /// L'utilisateur peut-il accéder aux données financières et rapports ?
  static bool canAccessFinancials(UserRole role) {
    return role == UserRole.superAdmin; // I'll keep financials to superAdmin/admin via string mapping
  }

  /// Convertit une String de rôle brute en UserRole enum
  static UserRole stringToRole(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'staff':
        return UserRole.staff;
      case 'admin':
      case 'superadmin':
        return UserRole.superAdmin;
      default:
        return UserRole.membre;
    }
  }
}
