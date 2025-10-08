// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedDataAdapter extends TypeAdapter<CachedData> {
  @override
  final int typeId = 0;

  @override
  CachedData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedData(
      id: fields[0] as String,
      data: (fields[1] as Map).cast<String, dynamic>(),
      cachedAt: fields[2] as DateTime,
      isDirty: fields[3] as bool,
      lastSyncedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.cachedAt)
      ..writeByte(3)
      ..write(obj.isDirty)
      ..writeByte(4)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncOperationAdapter extends TypeAdapter<SyncOperation> {
  @override
  final int typeId = 1;

  @override
  SyncOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncOperation(
      id: fields[0] as String,
      type: fields[1] as String,
      collection: fields[2] as String,
      data: (fields[3] as Map).cast<String, dynamic>(),
      timestamp: fields[4] as DateTime,
      retryCount: fields[5] as int,
      error: fields[6] as String?,
      userId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.collection)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.error)
      ..writeByte(7)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
