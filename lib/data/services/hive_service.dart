import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/member_account.dart';
import '../../domain/models/user_role.dart';
import './auth_service.dart';

class HiveService {
  static const String accountsBoxName = 'member_account_box';
  static const String settingsBoxName = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Récupération de la clé de chiffrement sécurisée
    final encryptionKey = await AuthService.getOrCreateEncryptionKey();
    final cipher = HiveAesCipher(encryptionKey);
    
    Hive.registerAdapter(MemberAccountAdapter());
    Hive.registerAdapter(UserRoleAdapter());
    
    // Ouverture des boxes avec chiffrement AES-256
    await Hive.openBox<MemberAccount>(accountsBoxName, encryptionCipher: cipher);
    await Hive.openBox(settingsBoxName, encryptionCipher: cipher);
  }

  Future<void> clear() async {
    final accountsBox = Hive.box<MemberAccount>(accountsBoxName);
    await accountsBox.clear();
  }

  bool isLoggedIn() {
    final box = Hive.box<MemberAccount>(accountsBoxName);
    return box.containsKey('current_account');
  }

  MemberAccount? getMemberAccount() {
    final box = Hive.box<MemberAccount>(accountsBoxName);
    return box.get('current_account');
  }

  // Onboarding settings
  bool get hasSeenOnboarding {
    final box = Hive.box(settingsBoxName);
    return box.get('has_seen_onboarding', defaultValue: false);
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put('has_seen_onboarding', value);
  }

  bool get hasAcceptedCGU {
    final box = Hive.box(settingsBoxName);
    return box.get('has_accepted_cgu', defaultValue: false);
  }

  Future<void> setHasAcceptedCGU(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put('has_accepted_cgu', value);
  }

  // Weekly Fitness Tracker
  List<bool> getWeeklyTracker() {
    final box = Hive.box(settingsBoxName);
    final data = box.get('weekly_tracker');
    if (data == null) return List.generate(7, (_) => false);
    return List<bool>.from(data);
  }

  Future<void> saveWeeklyTracker(List<bool> tracker) async {
    final box = Hive.box(settingsBoxName);
    await box.put('weekly_tracker', tracker);
  }

  int getStoredWeekId() {
    final box = Hive.box(settingsBoxName);
    return box.get('stored_week_id', defaultValue: 0);
  }

  Future<void> saveWeekId(int weekId) async {
    final box = Hive.box(settingsBoxName);
    await box.put('stored_week_id', weekId);
  }

  bool get hasSeenDashboardTutorial {
    final box = Hive.box(settingsBoxName);
    return box.get('has_seen_dashboard_tutorial', defaultValue: false);
  }

  Future<void> setHasSeenDashboardTutorial(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put('has_seen_dashboard_tutorial', value);
  }
}
