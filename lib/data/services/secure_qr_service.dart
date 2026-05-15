import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecureQrService {
  /// Génère une chaîne de données pour le QR Code incluant le matricule et un timestamp.
  /// Format : matricule|timestamp|signature
  static String generateSecureQrData(String matricule) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final rawData = '$matricule|$timestamp';
    
    // Ajout d'une signature simple pour éviter la falsification manuelle du texte
    final signature = _generateSignature(rawData);
    
    return '$rawData|$signature';
  }

  /// Vérifie si les données du QR Code sont valides et récentes (ex: moins de 60 secondes).
  static String? verifyAndExtractMatricule(String qrData) {
    try {
      final parts = qrData.split('|');
      if (parts.length != 3) return null;

      final matricule = parts[0];
      final timestampStr = parts[1];
      final signature = parts[2];

      // 1. Vérifier la signature
      final expectedSignature = _generateSignature('$matricule|$timestampStr');
      if (signature != expectedSignature) return null;

      // 2. Vérifier la fraîcheur (Anti-Capture d'écran)
      final timestamp = int.parse(timestampStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      final diffSeconds = (now - timestamp) / 1000;

      // Un QR Code expire après 60 secondes pour forcer l'usage de l'App en direct
      if (diffSeconds > 60 || diffSeconds < -60) {
        return null;
      }

      return matricule;
    } catch (e) {
      return null;
    }
  }

  static String _generateSignature(String data) {
    // Dans une vraie App, utilisez un Secret Key partagé côté serveur
    const secret = 'PANTHERS_SECRET_SALT_2026';
    final bytes = utf8.encode(data + secret);
    return sha256.convert(bytes).toString().substring(0, 8);
  }
}
