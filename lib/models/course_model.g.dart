// GENERATED CODE - hand-authored equivalent of `build_runner` output.
// See task_model.g.dart for regeneration notes.

part of 'course_model.dart';

class CourseModelAdapter extends TypeAdapter<CourseModel> {
  @override
  final int typeId = 2;

  @override
  CourseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CourseModel(
      id: fields[0] as String,
      userId: fields[1] as String?,
      semesterId: fields[2] as String?,
      courseCode: fields[3] as String,
      courseName: fields[4] as String,
      creditHours: fields[5] as double,
      instructor: fields[6] as String?,
      isSynced: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CourseModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.semesterId)
      ..writeByte(3)
      ..write(obj.courseCode)
      ..writeByte(4)
      ..write(obj.courseName)
      ..writeByte(5)
      ..write(obj.creditHours)
      ..writeByte(6)
      ..write(obj.instructor)
      ..writeByte(7)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
