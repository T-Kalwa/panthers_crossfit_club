import 'package:hive/hive.dart';

part 'user_role.g.dart';

@HiveType(typeId: 2)
enum UserRole {
  @HiveField(0)
  membre,
  
  @HiveField(1)
  staff,
  
  @HiveField(2)
  superAdmin,
}
