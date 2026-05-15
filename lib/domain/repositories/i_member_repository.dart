import '../models/member_account.dart';

abstract class IMemberRepository {
  Future<MemberAccount?> login(String username, String phoneNumber);
  Future<List<MemberAccount>> getAllMembers();
  Future<void> saveMemberAccount(MemberAccount account);
  Future<MemberAccount?> loginByQrData(String qrData);
  Future<String> generateNextMatricule({bool isStaff = false});
}
