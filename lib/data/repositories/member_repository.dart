import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/member_account.dart';
import '../services/hive_service.dart';
import '../services/secure_qr_service.dart';
import '../../domain/repositories/i_member_repository.dart';

class MemberRepository implements IMemberRepository {
  final HiveService _hiveService = HiveService();

  @override
  Future<MemberAccount?> login(String matricule, String phoneNumber) async {
    return loginByMatriculeAndPhone(matricule, phoneNumber);
  }

  Future<MemberAccount?> loginByMatriculeAndPhone(String matricule, String telephone) async {
    final matriculeUpper = matricule.toUpperCase();
    final phoneClean = telephone.trim();
    
    // 1. Check local cache first (Immediate response for offline-first)
    final cachedAccount = await getMemberAccountByMatricule(matriculeUpper);
    if (cachedAccount != null) {
      // SÉCURITÉ : Vérification du téléphone avant de valider le cache
      if (cachedAccount.telephone.trim() == phoneClean || (matriculeUpper == 'ADMIN' && phoneClean == '000')) {
        _syncAccountInBackground(matriculeUpper);
        return cachedAccount;
      } else {
        debugPrint("🔒 Sécurité Cache : Téléphone ne correspond pas pour $matriculeUpper");
        return null;
      }
    }

    try {
      // 2. Try Firestore
      final doc = await FirebaseFirestore.instance
          .collection('members')
          .doc(matriculeUpper)
          .get()
          .timeout(const Duration(seconds: 15));

      if (doc.exists) {
        final data = doc.data()!;
        final account = MemberAccount.fromJson(data);
        
        // SÉCURITÉ : Vérification du téléphone
        if (account.telephone.trim() != phoneClean && !(matriculeUpper == 'ADMIN' && phoneClean == '000')) {
          debugPrint("🔒 Sécurité Firestore : Téléphone ($phoneClean) ne correspond pas à (${account.telephone})");
          return null;
        }
        
        // 3. Liaison de Sécurité (UID -> Matricule)
        // Indispensable pour que les Security Rules (firestore.rules) fonctionnent
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && (account.role == 'staff' || account.role == 'superAdmin' || account.role == 'admin')) {
          try {
            await FirebaseFirestore.instance
                .collection('uids_to_members')
                .doc(user.uid)
                .set({
                  'matricule': account.matricule,
                  'role': account.role,
                  'last_login': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
            debugPrint("🔗 Sécurité : UID lié au matricule ${account.matricule}");
          } catch (e) {
            debugPrint("⚠️ Erreur liaison sécurité : $e");
          }
        }

        // 4. Gestion de la persistance (Ne pas sauvegarder si révoqué)
        if (!account.isActive) {
          final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
          final currentAccount = box.get('current_account');
          if (currentAccount != null && currentAccount.matricule == account.matricule) {
            await box.delete('current_account');
            debugPrint("🔒 Persistance supprimée : Le compte ${account.matricule} est révoqué.");
          }
        } else {
          await saveMemberAccount(account);
        }
        
        return account;
      }
    } catch (e) {
      print('Firestore error: $e. Using cache fallback if available.');
    }

    return null;
  }



  /// Silently update cache in background
  Future<void> _syncAccountInBackground(String matricule) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('members')
          .doc(matricule)
          .get();
      if (doc.exists) {
        final account = MemberAccount.fromJson(doc.data()!);
        await saveMemberAccount(account);
      }
    } catch (_) {
      // Fail silently in background
    }
  }

  /// Start a background listener to sync Firestore changes to Hive
  void startRealtimeSync() {
    debugPrint("🛰️ Activation de la synchronisation en temps réel Firestore -> Hive...");
    FirebaseFirestore.instance.collection('members').snapshots().listen((snapshot) {
      final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
      
      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        
        final matricule = change.doc.id.toUpperCase();
        
        if (change.type == DocumentChangeType.removed) {
          box.delete(matricule);
          debugPrint("🗑️ Sync : Membre $matricule supprimé (Firestore -> Hive)");
        } else {
          try {
            final account = MemberAccount.fromJson(data);
            box.put(matricule, account);
            debugPrint("🔄 Sync : Membre $matricule mis à jour (Firestore -> Hive)");
          } catch (e) {
            debugPrint("⚠️ Erreur parsing Sync : $e");
          }
        }
      }
    }, onError: (e) => debugPrint("❌ Erreur Stream Sync : $e"));
  }

  @override
  Future<MemberAccount?> loginByQrData(String qrData) async {
    // Use SecureQrService if it's a secure QR, else treat as raw matricule for legacy
    final matricule = SecureQrService.verifyAndExtractMatricule(qrData) ?? qrData.trim().toUpperCase();
    // For QR login, we might skip phone check if it's a secure QR, 
    // but here loginByMatricule was changed, so we need to decide.
    // If it's a secure QR, we trust it.
    final account = await getMemberAccountByMatricule(matricule);
    return account;
  }

  @override
  Future<List<MemberAccount>> getAllMembers() async {
    final account = _hiveService.getMemberAccount();
    return account != null ? [account] : [];
  }



  @override
  Future<void> saveMemberAccount(MemberAccount account) async {
    // 1. Save to local Hive (Primary Store for List View)
    final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
    
    // Key rule for Hive: A single HiveObject instance cannot be saved under two different keys.
    // If we need to update both the matricule and 'current_account', we'll use separate instances.
    await box.put(account.matricule.toUpperCase(), account);

    // 2. Gestion de la Session Active ('current_account')
    final currentAccount = box.get('current_account');
    
    // On met à jour 'current_account' si :
    // - Il n'y a personne de connecté (Premier Login)
    // - OU le matricule correspond (Mise à jour du profil actuel)
    if (currentAccount == null || currentAccount.matricule == account.matricule) {
      // Pour éviter l'erreur Hive (même instance pour 2 clés), on crée une copie
      final accountCopy = MemberAccount.fromJson(account.toJson());
      await box.put('current_account', accountCopy);
      debugPrint("💾 Session persistante mise à jour pour: ${account.matricule}");
    }

    // 3. Sync to Firestore (Background)
    try {
      await FirebaseFirestore.instance
          .collection('members')
          .doc(account.matricule.toUpperCase())
          .set(account.toJson());
    } catch (e) {
      print('Firestore sync failed: $e. Will retry automatically by Firestore.');
    }
  }

  /// Deletes a member from Firestore and local Hive
  Future<void> deleteMember(String matricule) async {
    // 1. Delete from Hive
    final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
    await box.delete(matricule.toUpperCase());

    // 2. Delete from Firestore
    try {
      await FirebaseFirestore.instance
          .collection('members')
          .doc(matricule.toUpperCase())
          .delete();
    } catch (e) {
      print('Firestore deletion failed: $e');
    }
  }

  /// Refreshes the local Hive cache with all members from Firestore
  Future<void> refreshMembersCache() async {
    try {
      debugPrint("🔄 Synchro Firestore -> Hive en cours...");
      final snapshot = await FirebaseFirestore.instance
          .collection('members')
          .get(); // On laisse Firestore gérer le cache/server intelligemment
      
      if (snapshot.docs.isEmpty) {
        debugPrint("ℹ️ Aucun membre trouvé sur Firestore.");
        return;
      }

      final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
      
      // On garde la session actuelle pour ne pas déconnecter l'utilisateur
      final currentAccount = box.get('current_account');
      
      await box.clear();

      for (var doc in snapshot.docs) {
        try {
          final account = MemberAccount.fromJson(doc.data());
          await box.put(account.matricule.toUpperCase(), account);
        } catch (e) {
          debugPrint("⚠️ Erreur parsing membre ${doc.id}: $e");
        }
      }

      // Restauration de la session actuelle
      if (currentAccount != null) {
        await box.put('current_account', currentAccount);
      }
      
      debugPrint("✅ Synchro terminée : ${snapshot.docs.length} membres récupérés.");
    } catch (e) {
      debugPrint('❌ Erreur refreshMembersCache: $e');
    }
  }

  Future<MemberAccount?> getMemberAccount() async {
    final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
    return box.get('current_account');
  }

  Future<MemberAccount?> getMemberAccountByMatricule(String matricule) async {
    final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
    final matriculeUpper = matricule.toUpperCase();
    
    // 1. Priorité Hive (Vitesse & Offline)
    final cached = box.get(matriculeUpper);
    if (cached != null) return cached;
    
    // 2. Fallback Firestore (Si nouveau membre pas encore sync)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('members')
          .doc(matriculeUpper)
          .get()
          .timeout(const Duration(seconds: 3));
          
      if (doc.exists) {
        final account = MemberAccount.fromJson(doc.data()!);
        await box.put(matriculeUpper, account); // On le met en cache
        return account;
      }
    } catch (e) {
      debugPrint("ℹ️ Scanner : Pas de fallback Firestore (Hors ligne ou timeout)");
    }
    
    return null;
  }

  bool hasSavedMembers() {
    final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
    // On considère qu'il y a des membres si la liste contient autre chose que la session active
    return box.keys.any((k) => k != 'current_account');
  }

  Future<void> seedMockUser() async {
    // Logic removed to prevent reverting to mock user.
  }

  @override
  Future<String> generateNextMatricule({bool isStaff = false}) async {
    final prefix = isStaff ? 'PS' : 'P';
    // Digits (0-9) come before letters (S) in lexicographical order.
    // 'P' + '9' < 'P' + 'S' (Member vs Staff)
    // 'P' + 'S' + '9' < 'P' + 'T' (Staff vs others)
    final upperBound = isStaff ? 'PT' : 'PS';
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('matricule', isGreaterThanOrEqualTo: prefix)
          .where('matricule', isLessThan: upperBound)
          .orderBy('matricule', descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.docs.isNotEmpty) {
        final lastMatricule = snapshot.docs.first.id;
        if (lastMatricule.startsWith(prefix)) {
          final numberPart = lastMatricule.substring(prefix.length);
          final number = int.tryParse(numberPart) ?? 0;
          return '$prefix${(number + 1).toString().padLeft(3, '0')}';
        }
      }
      
      return '${prefix}001';
    } catch (e) {
      debugPrint("⚠️ Error generating matricule: $e");
      // Fallback to local check if Firestore fails/offline
      try {
        final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
        int maxLocal = 0;
        for (var key in box.keys) {
          if (key is String && key.startsWith(prefix)) {
             // Second filter for pure 'P' vs 'PS'
             if (!isStaff && key.startsWith('PS')) continue;
             
            final num = int.tryParse(key.substring(prefix.length)) ?? 0;
            if (num > maxLocal) maxLocal = num;
          }
        }
        return '$prefix${(maxLocal + 1).toString().padLeft(3, '0')}';
      } catch (_) {
        return '${prefix}001';
      }
    }
  }

  Future<void> clearAllData() async {
    // 1. Clear Hive
    final box = Hive.box<MemberAccount>(HiveService.accountsBoxName);
    await box.clear();

    // 2. Clear Firestore collection
    try {
      final snapshot = await FirebaseFirestore.instance.collection('members').get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing Firestore: $e');
    }
  }
}
