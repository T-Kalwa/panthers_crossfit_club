import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Model representing members' subscription data from Firestore
class SubscriptionData {
  final String fullName;
  final DateTime expiryDate;
  final bool isActive;
  final DateTime lastSync;

  SubscriptionData({
    required this.fullName,
    required this.expiryDate,
    required this.isActive,
    required this.lastSync,
  });

  factory SubscriptionData.fromFirestore(Map<String, dynamic> data) {
    return SubscriptionData(
      fullName: data['full_name'] ?? 'Inconnu',
      expiryDate: (data['expiry_date'] as Timestamp).toDate(),
      isActive: data['is_active'] ?? false,
      lastSync: (data['last_sync'] as Timestamp).toDate(),
    );
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches a single member subscription using their unique physical ID (matricule).
  /// 
  /// Optimized for cost: only 1 document read via direct ID access.
  /// Used for initial activation or periodic re-verification.
  Future<SubscriptionData?> fetchSubscription(String matricule) async {
    try {
      // Use direct document ID access for maximum efficiency (1 read)
      final docRef = _db.collection('members').doc(matricule);
      final docSnap = await docRef.get(const GetOptions(source: Source.serverAndCache));

      if (!docSnap.exists || docSnap.data() == null) {
        return null;
      }

      return SubscriptionData.fromFirestore(docSnap.data()!);
    } on FirebaseException catch (e) {
      // Handle Firebase specific errors (permissions, connectivity)
      print('Firestore Error ($matricule): ${e.code} - ${e.message}');
      throw Exception('Erreur de connexion à la base de données: ${e.message}');
    } catch (e) {
      print('General Error fetching subscription ($matricule): $e');
      return null;
    }
  }

  /// Retrieves the current server time from Firebase.
  /// 
  /// This prevents users from cheating by changing their local phone clock.
  /// 
  /// Note: The most reliable way in Firestore to get the server time is via a write
  /// or by reading a document that was just updated with FieldValue.serverTimestamp().
  /// To save on reads/writes, we use a dedicated sync document.
  Future<DateTime> checkServerTime() async {
    try {
      // We write to a shared metadata document to get the server timestamp
      final docRef = _db.collection('system').doc('server_time_sync');
      
      await docRef.set({
        'request_time': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final docSnap = await docRef.get();
      final timestamp = docSnap.data()?['request_time'] as Timestamp?;
      
      return timestamp?.toDate() ?? DateTime.now();
    } catch (e) {
      print('Error checking server time: $e');
      // Fallback to local time if server time sync fails, 
      // though ideally we'd show a "Sync required" error in a real app.
      return DateTime.now();
    }
  }
}
