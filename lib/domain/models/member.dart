import 'package:hive/hive.dart';

part 'member.g.dart';

@HiveType(typeId: 0)
class Member extends HiveObject {
  @HiveField(0)
  final String matricule;
  
  @HiveField(1)
  final String nomComplet;
  
  @HiveField(2)
  final DateTime dateFin;
  
  @HiveField(3)
  final String activite;
  
  @HiveField(4)
  final bool avecCoach;
  
  @HiveField(5)
  final String? phoneNumber;
  
  @HiveField(6)
  final String? profileImageUrl;

  Member({
    required this.matricule,
    required this.nomComplet,
    required this.dateFin,
    required this.activite,
    this.avecCoach = false,
    this.phoneNumber,
    this.profileImageUrl,
  });

  // Business Logic
  int get daysRemaining {
    final diff = dateFin.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  double get expiryProgress {
    // Arbitrary 30-day window for the progress circle visibility if no start date
    // or we can just use a percentage if we had a registration date.
    // Let's assume a default subscription period of 90 days for the "filling" visual.
    const totalDays = 90; 
    final remaining = daysRemaining;
    return (remaining / totalDays).clamp(0.0, 1.0);
  }

  bool get isExpired => DateTime.now().isAfter(dateFin);

  Map<String, dynamic> toJson() => {
    'matricule': matricule,
    'nom_complet': nomComplet,
    'date_fin': dateFin.toIso8601String(),
    'activite': activite,
    'avec_coach': avecCoach,
    'phoneNumber': phoneNumber,
    'profileImageUrl': profileImageUrl,
  };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    matricule: json['matricule'],
    nomComplet: json['nom_complet'],
    dateFin: DateTime.parse(json['date_fin']),
    activite: json['activite'],
    avecCoach: json['avec_coach'] ?? false,
    phoneNumber: json['phoneNumber'],
    profileImageUrl: json['profileImageUrl'],
  );
}
