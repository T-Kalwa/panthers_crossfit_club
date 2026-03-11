import '../../domain/models/member.dart';
import '../services/hive_service.dart';
import '../../domain/repositories/i_member_repository.dart';

class MemberRepository implements IMemberRepository {
  final HiveService _hiveService = HiveService();

  @override
  Future<Member?> login(String username, String phoneNumber) async {
    // Legacy support for phone login if needed, but the prompt emphasizes matricule.
    // For now, we'll implement loginByQrData as the primary entry point.
    return null; 
  }

  @override
  Future<Member?> loginByQrData(String qrData) async {
    // In a real app, we would fetch from Firestore here and cache to Hive.
    // For this POC, we'll check our mock user.
    if (qrData == 'P009') {
      final mock = _getMockJoseph();
      await _hiveService.saveMember(mock);
      return mock;
    }
    return null;
  }

  @override
  Future<List<Member>> getAllMembers() async {
    // Return the cached member or empty list
    final m = _hiveService.getMember();
    return m != null ? [m] : [];
  }

  @override
  Future<void> saveMember(Member member) async {
    await _hiveService.saveMember(member);
    // TODO: Sync to Firestore
  }

  Future<void> seedMockUser() async {
    final existing = _hiveService.getMember();
    if (existing == null) {
      final mock = _getMockJoseph();
      await _hiveService.saveMember(mock);
    }
  }

  Member _getMockJoseph() {
    return Member(
      matricule: 'P009',
      nomComplet: 'Joseph Benson',
      dateFin: DateTime.now().add(const Duration(days: 91)),
      activite: 'CROSSFIT',
      avecCoach: true,
      phoneNumber: '+33 6 12 34 56 78',
    );
  }
}
