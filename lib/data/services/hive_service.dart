import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/member.dart';

class HiveService {
  static const String memberBoxName = 'member_box';
  static const String settingsBoxName = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MemberAdapter());
    await Hive.openBox<Member>(memberBoxName);
    await Hive.openBox(settingsBoxName);
  }

  Future<void> saveMember(Member member) async {
    final box = Hive.box<Member>(memberBoxName);
    await box.put('current_member', member);
  }

  Member? getMember() {
    final box = Hive.box<Member>(memberBoxName);
    return box.get('current_member');
  }

  Future<void> clear() async {
    final box = Hive.box<Member>(memberBoxName);
    await box.clear();
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
}
