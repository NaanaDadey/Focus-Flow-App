// GENERATED CODE - hand-authored equivalent of `build_runner` output.
// See task_model.g.dart for regeneration notes.

part of 'timetable_entry_model.dart';

class TimetableEntryModelAdapter extends TypeAdapter<TimetableEntryModel> {
  @override
  final int typeId = 1;

  @override
  TimetableEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimetableEntryModel(
      id: fields[0] as String,
      userId: fields[1] as String?,
      courseCode: fields[2] as String,
      courseName: fields[3] as String,
      dayOfWeek: fields[4] as int,
      startTime: fields[5] as String,
      endTime: fields[6] as String,
      location: fields[7] as String?,
      colorHex: fields[8] as String,
      isSynced: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TimetableEntryModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.courseCode)
      ..writeByte(3)
      ..write(obj.courseName)
      ..writeByte(4)
      ..write(obj.dayOfWeek)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.colorHex)
      ..writeByte(9)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
