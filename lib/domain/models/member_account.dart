import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../logic/panthers_pricing.dart';

part 'member_account.g.dart';

@HiveType(typeId: 1)
class MemberAccount extends HiveObject {
  @HiveField(0)
  final String matricule;

  @HiveField(1)
  final String noms;

  @HiveField(2)
  final String telephone;

  @HiveField(3)
  final String role; // membre, staff, superAdmin

  @HiveField(4)
  final String activite;

  @HiveField(5)
  final String dureeForfait;

  @HiveField(6)
  final bool avecCoach;

  @HiveField(7)
  final double montantPaye;

  @HiveField(8)
  final DateTime dateDebut;

  @HiveField(9)
  final DateTime dateFin;

  @HiveField(10)
  final bool isActive;

  @HiveField(11)
  final String? methodePaiement; // Airtel, Orange, Cash, etc.

  @HiveField(12)
  final String? inscritPar; // Matricule du staff qui a fait l'inscription

  @HiveField(13)
  final String? profileImageUrl;

  @HiveField(14)
  final List<int>? reachedGoals; // Ex: [1, 3, 5] pour Lun, Mer, Ven

  @HiveField(15)
  final DateTime? lastGoalReset;

  MemberAccount({
    required this.matricule,
    required this.noms,
    required this.telephone,
    required this.role,
    required this.activite,
    required this.dureeForfait,
    this.avecCoach = false,
    required this.montantPaye,
    required this.dateDebut,
    required this.dateFin,
    this.isActive = true,
    this.methodePaiement,
    this.inscritPar,
    this.profileImageUrl,
    this.reachedGoals,
    this.lastGoalReset,
  });

  // Factory to create a member with automated pricing logic
  factory MemberAccount.fromPricing({
    required String matricule,
    required String noms,
    required String telephone,
    required String role,
    required String activite,
    required String dureeForfait,
    required bool avecCoach,
    required DateTime dateDebut,
    String? methodePaiement,
    String? inscritPar,
    String? profileImageUrl,
  }) {
    final pricing = PanthersPricing.getPlanDetails(activite, dureeForfait, avecCoach);
    final dateFin = PanthersPricing.calculateExpiryDate(dateDebut, pricing.days);
    
    return MemberAccount(
      matricule: matricule,
      noms: noms,
      telephone: telephone,
      role: role,
      activite: activite,
      dureeForfait: dureeForfait,
      avecCoach: avecCoach,
      montantPaye: pricing.price,
      dateDebut: dateDebut,
      dateFin: dateFin,
      isActive: true,
      methodePaiement: methodePaiement,
      inscritPar: inscritPar,
      profileImageUrl: profileImageUrl,
      reachedGoals: [],
      lastGoalReset: DateTime.now(),
    );
  }

  // Calculate if the subscription is expired
  bool get isExpired => DateTime.now().isAfter(dateFin);

  // Business Logic: Days remaining
  int get daysRemaining {
    final diff = dateFin.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  // Progress for UI
  double get expiryProgress {
    final totalDuration = dateFin.difference(dateDebut).inDays;
    if (totalDuration <= 0) return 0.0;
    final remaining = daysRemaining;
    return (remaining / totalDuration).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'matricule': matricule,
        'noms': noms,
        'telephone': telephone,
        'role': role,
        'activite': activite,
        'dureeForfait': dureeForfait,
        'avecCoach': avecCoach,
        'montantPaye': montantPaye,
        'dateDebut': dateDebut.toIso8601String(),
        'dateFin': dateFin.toIso8601String(),
        'isActive': isActive,
        'methodePaiement': methodePaiement,
        'inscritPar': inscritPar,
        'profileImageUrl': profileImageUrl,
        'reachedGoals': reachedGoals,
        'lastGoalReset': lastGoalReset?.toIso8601String(),
      };

  factory MemberAccount.fromJson(Map<String, dynamic> json) {
    try {
      return MemberAccount(
        matricule: json['matricule']?.toString() ?? '',
        noms: json['noms']?.toString() ?? 'Inconnu',
        telephone: json['telephone']?.toString() ?? '',
        role: json['role']?.toString() ?? 'membre',
        activite: json['activite']?.toString() ?? 'NON DÉFINI',
        dureeForfait: json['dureeForfait']?.toString() ?? '',
        avecCoach: json['avecCoach'] == true,
        montantPaye: _parseNum(json['montantPaye']),
        dateDebut: _parseDate(json['dateDebut']),
        dateFin: _parseDate(json['dateFin']),
        isActive: json['isActive'] != false,
        methodePaiement: json['methodePaiement']?.toString(),
        inscritPar: json['inscritPar']?.toString(),
        profileImageUrl: json['profileImageUrl']?.toString(),
        reachedGoals: (json['reachedGoals'] as List?)?.map((e) => e as int).toList() ?? [],
        lastGoalReset: json['lastGoalReset'] != null ? DateTime.tryParse(json['lastGoalReset']) : null,
      );
    } catch (e) {
      debugPrint("❌ Erreur parsing MemberAccount: $e");
      rethrow;
    }
  }

  static double _parseNum(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    // Support pour Firebase Timestamp si le format change plus tard
    try {
      if (v.runtimeType.toString().contains('Timestamp')) {
        return v.toDate();
      }
    } catch (_) {}
    return DateTime.now();
  }

  MemberAccount copyWith({
    String? matricule,
    String? noms,
    String? telephone,
    String? role,
    String? activite,
    String? dureeForfait,
    bool? avecCoach,
    double? montantPaye,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? isActive,
    String? methodePaiement,
    String? inscritPar,
    String? profileImageUrl,
    List<int>? reachedGoals,
    DateTime? lastGoalReset,
  }) {
    return MemberAccount(
      matricule: matricule ?? this.matricule,
      noms: noms ?? this.noms,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      activite: activite ?? this.activite,
      dureeForfait: dureeForfait ?? this.dureeForfait,
      avecCoach: avecCoach ?? this.avecCoach,
      montantPaye: montantPaye ?? this.montantPaye,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      isActive: isActive ?? this.isActive,
      methodePaiement: methodePaiement ?? this.methodePaiement,
      inscritPar: inscritPar ?? this.inscritPar,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      reachedGoals: reachedGoals ?? this.reachedGoals,
      lastGoalReset: lastGoalReset ?? this.lastGoalReset,
    );
  }
}
