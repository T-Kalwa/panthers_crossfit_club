import '../models/member.dart';

abstract class IMemberRepository {
  Future<Member?> login(String username, String phoneNumber);
  Future<List<Member>> getAllMembers();
  Future<void> saveMember(Member member);
  Future<Member?> loginByQrData(String qrData);
}
