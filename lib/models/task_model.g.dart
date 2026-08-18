// GENERATED CODE - hand-authored equivalent of `build_runner` output.
//
// Normally this file is produced by running:
//   flutter pub run build_runner build --delete-conflicting-outputs
// It is committed here so the project compiles immediately without
// requiring a codegen step. If you add/change @HiveField entries in
// task_model.dart, either re-run build_runner or update this file to match.

part of 'task_model.dart';

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      userId: fields[1] as String?,
      title: fields[2] as String,
      description: fields[3] as String?,
      category: fields[4] as String,
      priority: fields[5] as String,
      status: fields[6] as String,
      deadline: fields[7] as DateTime,
      suggestedStart: fields[8] as DateTime?,
      estimatedMinutes: fields[9] as int,
      actualMinutes: fields[10] as int?,
      courseCode: fields[11] as String?,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      completedAt: fields[14] as DateTime?,
      isSynced: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.deadline)
      ..writeByte(8)
      ..write(obj.suggestedStart)
      ..writeByte(9)
      ..write(obj.estimatedMinutes)
      ..writeByte(10)
      ..write(obj.actualMinutes)
      ..writeByte(11)
      ..write(obj.courseCode)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.completedAt)
      ..writeByte(15)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
