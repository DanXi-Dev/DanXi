// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_table.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeTable _$TimeTableFromJson(Map<String, dynamic> json) {
  return TimeTable()
    ..courses = (json['courses'] as List<dynamic>?)
        ?.map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList()
    ..startTime = json['startTime'] == null
        ? null
        : DateTime.parse(json['startTime'] as String);
}

Map<String, dynamic> _$TimeTableToJson(TimeTable instance) => <String, dynamic>{
      'courses': instance.courses,
      'startTime': instance.startTime?.toIso8601String(),
    };

Course _$CourseFromJson(Map<String, dynamic> json) {
  return Course()
    ..teacherIds =
        (json['teacherIds'] as List<dynamic>?)?.map((e) => e as String).toList()
    ..teacherNames = (json['teacherNames'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList()
    ..courseId = json['courseId'] as String?
    ..courseName = json['courseName'] as String?
    ..roomId = json['roomId'] as String?
    ..roomName = json['roomName'] as String?
    ..availableWeeks = (json['availableWeeks'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList()
    ..times = (json['times'] as List<dynamic>?)
        ?.map((e) => CourseTime.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
      'teacherIds': instance.teacherIds,
      'teacherNames': instance.teacherNames,
      'courseId': instance.courseId,
      'courseName': instance.courseName,
      'roomId': instance.roomId,
      'roomName': instance.roomName,
      'availableWeeks': instance.availableWeeks,
      'times': instance.times,
    };

CourseTime _$CourseTimeFromJson(Map<String, dynamic> json) {
  return CourseTime(
    json['weekDay'] as int,
    json['slot'] as int,
  );
}

Map<String, dynamic> _$CourseTimeToJson(CourseTime instance) =>
    <String, dynamic>{
      'weekDay': instance.weekDay,
      'slot': instance.slot,
    };
