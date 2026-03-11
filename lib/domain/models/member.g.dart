// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemberAdapter extends TypeAdapter<Member> {
  @override
  final int typeId = 0;

  @override
  Member read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Member(
      matricule: fields[0] as String,
      nomComplet: fields[1] as String,
      dateFin: fields[2] as DateTime,
      activite: fields[3] as String,
      avecCoach: fields[4] as bool,
      phoneNumber: fields[5] as String?,
      profileImageUrl: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Member obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.matricule)
      ..writeByte(1)
      ..write(obj.nomComplet)
      ..writeByte(2)
      ..write(obj.dateFin)
      ..writeByte(3)
      ..write(obj.activite)
      ..writeByte(4)
      ..write(obj.avecCoach)
      ..writeByte(5)
      ..write(obj.phoneNumber)
      ..writeByte(6)
      ..write(obj.profileImageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
