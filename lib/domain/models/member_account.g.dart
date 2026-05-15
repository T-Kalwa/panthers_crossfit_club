// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemberAccountAdapter extends TypeAdapter<MemberAccount> {
  @override
  final int typeId = 1;

  @override
  MemberAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemberAccount(
      matricule: fields[0] as String,
      noms: fields[1] as String,
      telephone: fields[2] as String,
      role: fields[3] as String,
      activite: fields[4] as String,
      dureeForfait: fields[5] as String,
      avecCoach: fields[6] as bool,
      montantPaye: fields[7] as double,
      dateDebut: fields[8] as DateTime,
      dateFin: fields[9] as DateTime,
      isActive: fields[10] as bool,
      methodePaiement: fields[11] as String?,
      inscritPar: fields[12] as String?,
      profileImageUrl: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MemberAccount obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.matricule)
      ..writeByte(1)
      ..write(obj.noms)
      ..writeByte(2)
      ..write(obj.telephone)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.activite)
      ..writeByte(5)
      ..write(obj.dureeForfait)
      ..writeByte(6)
      ..write(obj.avecCoach)
      ..writeByte(7)
      ..write(obj.montantPaye)
      ..writeByte(8)
      ..write(obj.dateDebut)
      ..writeByte(9)
      ..write(obj.dateFin)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.methodePaiement)
      ..writeByte(12)
      ..write(obj.inscritPar)
      ..writeByte(13)
      ..write(obj.profileImageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
