// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vessel_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VesselProfileAdapter extends TypeAdapter<VesselProfile> {
  @override
  final int typeId = 3;

  @override
  VesselProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VesselProfile(
      name: fields[0] as String,
      length: fields[1] as double,
      isPowered: fields[2] as bool,
      registration: fields[3] as String,
      engineHp: fields[4] as int,
      windIncreaseThreshold: fields[5] as double,
      swellIncreaseThreshold: fields[6] as double,
      notificationsEnabled: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VesselProfile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.length)
      ..writeByte(2)
      ..write(obj.isPowered)
      ..writeByte(3)
      ..write(obj.registration)
      ..writeByte(4)
      ..write(obj.engineHp)
      ..writeByte(5)
      ..write(obj.windIncreaseThreshold)
      ..writeByte(6)
      ..write(obj.swellIncreaseThreshold)
      ..writeByte(7)
      ..write(obj.notificationsEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VesselProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
