// GENERATED CODE - hand-authored equivalent of `build_runner` output.
// See task_model.g.dart for regeneration notes.

part of 'exam_model.dart';

class ExamModelAdapter extends TypeAdapter<ExamModel> {
  @override
  final int typeId = 3;

  @override
  ExamModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExamModel(
      id: fields[0] as String,
      userId: fields[1] as String?,
      courseCode: fields[2] as String,
      courseName: fields[3] as String,
      examDate: fields[4] as DateTime,
      examTime: fields[5] as String?,
      venue: fields[6] as String?,
      notes: fields[7] as String?,
      isSynced: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExamModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.courseCode)
      ..writeByte(3)
      ..write(obj.courseName)
      ..writeByte(4)
      ..write(obj.examDate)
      ..writeByte(5)
      ..write(obj.examTime)
      ..writeByte(6)
      ..write(obj.venue)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
