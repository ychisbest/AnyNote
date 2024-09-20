// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_api_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteItemAdapter extends TypeAdapter<NoteItem> {
  @override
  final int typeId = 0;

  @override
  NoteItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteItem(
      id: fields[0] as int?,
      isTopMost: fields[1] as bool,
      content: fields[2] as String?,
      createTime: fields[3] as DateTime,
      lastUpdateTime: fields[4] as DateTime?,
      archiveTime: fields[5] as DateTime?,
      isArchived: fields[6] as bool,
      color: fields[7] as int?,
      index: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NoteItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isTopMost)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.createTime)
      ..writeByte(4)
      ..write(obj.lastUpdateTime)
      ..writeByte(5)
      ..write(obj.archiveTime)
      ..writeByte(6)
      ..write(obj.isArchived)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
