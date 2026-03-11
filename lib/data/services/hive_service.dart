import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/member.dart';

class HiveService {
  static const String memberBoxName = 'member_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MemberAdapter());
    await Hive.openBox<Member>(memberBoxName);
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
}
