import '../../domain/models/member.dart';
import '../services/json_storage_service.dart';
import '../../domain/repositories/i_member_repository.dart';

class MemberRepository implements IMemberRepository {
  final JsonStorageService _storageService = JsonStorageService('members.json');

  @override
  Future<Member?> login(String username, String phoneNumber) async {
    final List<Member> members = await getAllMembers();
    try {
      return members.firstWhere(
        (m) => m.username == username && m.phoneNumber == phoneNumber,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Member>> getAllMembers() async {
    final data = await _storageService.readJson();
    if (data == null || data is! List) {
      return [];
    }
    return data.map((item) => Member.fromJson(item)).toList();
  }

  @override
  Future<void> saveMember(Member member) async {
    final List<Member> members = await getAllMembers();
    final index = members.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      members[index] = member;
    } else {
      members.add(member);
    }
    await _storageService.writeJson(members.map((m) => m.toJson()).toList());
  }

  // Method to seed a test user if the file is empty
  Future<void> seedMockUser() async {
    final existing = await getAllMembers();
    if (existing.isEmpty) {
      final mockMember = Member(
        id: '1',
        username: 'admin',
        phoneNumber: '0600000000',
        fullName: 'Admin Panther',
        registrationDate: DateTime.now(),
      );
      await saveMember(mockMember);
    }
  }
}
