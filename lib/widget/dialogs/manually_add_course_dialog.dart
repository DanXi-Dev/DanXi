import 'package:collection/collection.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

class ManuallyAddCourseDialog extends StatefulWidget {
  const ManuallyAddCourseDialog(
    this.courseAvailableList, {
    super.key,
    this.initialCourse,
  });

  final List<int> courseAvailableList;
  final Course? initialCourse;

  @override
  State<ManuallyAddCourseDialog> createState() =>
      _ManuallyAddCourseDialogState();
}

class _ManuallyAddCourseDialogState extends State<ManuallyAddCourseDialog> {
  late Course newCourse;

  late TextEditingController courseNameController;
  late TextEditingController courseIdController;
  late TextEditingController courseRoomNameController;
  late TextEditingController courseTeacherNameController;

  @override
  void initState() {
    super.initState();

    newCourse = widget.initialCourse?.copyWith() ?? Course();
    newCourse.times = newCourse.times?.toSet().sorted() ?? List.empty();

    courseNameController = TextEditingController(text: newCourse.courseName);
    courseIdController = TextEditingController(text: newCourse.courseId);
    courseRoomNameController = TextEditingController(text: newCourse.roomName);
    courseTeacherNameController = TextEditingController(
      text: newCourse.teacherNames?.join(" "),
    );

    final availableWeeks = newCourse.availableWeeks;
    if (availableWeeks != null) {
      widget.courseAvailableList.clear();
      widget.courseAvailableList.addAll(availableWeeks);
    }
  }

  Course newCourseListGenerator(
      TextEditingController courseNameController,
      TextEditingController courseIdController,
      TextEditingController courseRoomNameController,
      TextEditingController courseTeacherNameController,
      List<int> courseAvailableList,
      Course newCourse) {
    newCourse.courseName = courseNameController.text;
    newCourse.courseId = courseIdController.text;
    newCourse.roomId = Course.MANUALLY_ADDED_ROOM_ID;
    newCourse.teacherNames = courseTeacherNameController.text
        .splitByWhitespace();
    newCourse.availableWeeks = courseAvailableList;
    newCourse.roomName = courseRoomNameController.text;

    return newCourse;
  }

  void onButtonPressed() async {
    final courseTimes = await showPlatformDialog<List<CourseTime>>(
      context: context,
      builder: (context) => const _SelectSlotsDialog(),
    );
    if (courseTimes != null) {
      setState(() {
        newCourse.times = (newCourse.times! + courseTimes).toSet().sorted();
      });
    }
  }

  String slotsOfADayGenerator(List<CourseTime> courseTime) {
    return courseTime.map((element) => element.slot + 1).join(",");
  }

  @override
  void dispose() {
    courseNameController.dispose();
    courseIdController.dispose();
    courseRoomNameController.dispose();
    courseTeacherNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: Text(S.of(context).add_courses),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: courseNameController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                  labelText: S.of(context).course_name,
                  icon: PlatformX.isMaterial(context)
                      ? const Icon(Icons.book)
                      : const Icon(CupertinoIcons.book)),
              autofocus: false,
            ),
            if (!PlatformX.isMaterial(context)) const SizedBox(height: 2),
            TextField(
              controller: courseIdController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                  labelText: S.of(context).course_id,
                  icon: PlatformX.isMaterial(context)
                      ? const Icon(Icons.numbers)
                      : const Icon(CupertinoIcons.number)),
              autofocus: false,
            ),
            if (!PlatformX.isMaterial(context)) const SizedBox(height: 2),
            TextField(
              controller: courseRoomNameController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                  labelText: S.of(context).course_room_name,
                  icon: PlatformX.isMaterial(context)
                      ? const Icon(Icons.location_city)
                      : const Icon(CupertinoIcons.location_fill)),
              autofocus: false,
            ),
            if (!PlatformX.isMaterial(context)) const SizedBox(height: 2),
            TextField(
              controller: courseTeacherNameController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                  labelText: S.of(context).course_teacher_name,
                  icon: PlatformX.isMaterial(context)
                      ? const Icon(Icons.people)
                      : const Icon(CupertinoIcons.person_2_fill)),
              autofocus: false,
            ),
            if (!PlatformX.isMaterial(context)) const SizedBox(height: 20),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: S.of(context).course_available_week,
                icon: PlatformX.isMaterial(context)
                    ? const Icon(Icons.calendar_month_outlined)
                    : const Icon(CupertinoIcons.calendar),
                enabled: false,
              ),
              autofocus: false,
            ),
            ListTile(
              title: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(TimeTable.MAX_WEEK, (index) => index + 1)
                    .map((e) => GestureDetector(
                          onTap: () {
                            if (widget.courseAvailableList.contains(e)) {
                              setState(
                                  () => widget.courseAvailableList.remove(e));
                            } else {
                              setState(() => widget.courseAvailableList.add(e));
                            }
                          },
                          child: CircleAvatar(
                            key: ObjectKey(e),
                            radius: 15.0,
                            backgroundColor: Color(
                                context.read<SettingsProvider>().primarySwatch),
                            foregroundColor: Colors.white,
                            child: widget.courseAvailableList.contains(e)
                                ? Icon(PlatformX.isMaterial(context)
                                    ? Icons.done
                                    : CupertinoIcons.checkmark_alt)
                                : Text(
                                    "$e",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white),
                                  ),
                          ),
                      ))
                    .toList(growable: false),
              ),
            ),
            if (!PlatformX.isMaterial(context)) const SizedBox(height: 2),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: S.of(context).course_schedule,
                icon: PlatformX.isMaterial(context)
                    ? const Icon(Icons.access_time)
                    : const Icon(CupertinoIcons.time),
                enabled: false,
              ),
              autofocus: false,
            ),
            Column(children: _buildCourseTimeTiles(newCourse.times!)),
            PlatformX.isMaterial(context)
                ? ElevatedButton(
                    onPressed: onButtonPressed,
                    child: Text(S.of(context).add_class_time))
                : CupertinoButton(
                    onPressed: onButtonPressed,
                    child: Text(S.of(context).add_class_time)),
          ],
        ),
      ),
      actions: [
        PlatformDialogAction(
          child: Text(S.of(context).cancel),
          onPressed: () => Navigator.pop(context),
        ),
        PlatformDialogAction(
            child: Text(S.of(context).ok),
            onPressed: () {
              if (widget.courseAvailableList.isEmpty ||
                  newCourse.times!.isEmpty) {
                showPlatformDialog(
                    context: context,
                    builder: (BuildContext context) => PlatformAlertDialog(
                          title: Text(S.of(context).warning),
                          content: Text(S.of(context).invalid_course_info),
                          actions: [
                            PlatformDialogAction(
                              child: Text(S.of(context).ok),
                              onPressed: () => Navigator.pop(context),
                            )
                          ],
                        ));
              } else {
                Navigator.pop(
                    context,
                    newCourseListGenerator(
                        courseNameController,
                        courseIdController,
                        courseRoomNameController,
                        courseTeacherNameController,
                        widget.courseAvailableList,
                        newCourse));
              }
            }),
      ],
    );
  }

  List<Widget> _buildCourseTimeTiles(List<CourseTime> times) {
    return times
        .groupListsBy((time) => time.weekDay)
        .entries
        .map((entry) {
          final weekDay = entry.key;
          final times = entry.value;
          return Dismissible(
            key: ValueKey(weekDay),
            child: ListTile(
              title: Text(
                "${Constant.weekDay(weekDay)} ${slotsOfADayGenerator(times)}",
              ),
              trailing: IconButton(
                onPressed: () => setState(() => _removeCourseTimeTile(weekDay)),
                icon: Icon(
                  PlatformX.isMaterial(context)
                      ? Icons.delete_outline
                      : CupertinoIcons.delete,
                ),
              ),
            ),
            onDismissed: (_) => setState(() => _removeCourseTimeTile(weekDay)),
          );
        })
        .toList(growable: false);
  }

  void _removeCourseTimeTile(int weekDay) {
    newCourse.times = newCourse.times!
        .whereNot((time) => time.weekDay == weekDay)
        .toList(growable: false);
  }
}

/// Slots selector for the course.
class _SelectSlotsDialog extends StatefulWidget {
  const _SelectSlotsDialog();

  @override
  State<_SelectSlotsDialog> createState() => _SelectSlotsDialogState();
}

class _SelectSlotsDialogState extends State<_SelectSlotsDialog> {
  int selectedWeekDay = 0;
  final selectedSlots = List.filled(
    TimeTable.kCourseSlotStartTime.length,
    false,
  );

  List<CourseTime>? newCourseTimeGenerator(
    int selectedWeekDay,
    List<bool> selectedSlots,
  ) {
    return selectedSlots
        .mapIndexed(
          (index, selected) =>
              selected ? CourseTime(selectedWeekDay, index) : null,
        )
        .nonNulls
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      content: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              7,
              (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    selectedWeekDay = index;
                  });
                },
                child: CircleAvatar(
                  radius: 24.0,
                  backgroundColor: Color(
                    context.read<SettingsProvider>().primarySwatch,
                  ),
                  foregroundColor: Colors.white,
                  child: index == selectedWeekDay
                      ? Icon(
                          PlatformX.isMaterial(context)
                              ? Icons.done
                              : CupertinoIcons.checkmark_alt,
                        )
                      : Text(
                          Constant.weekDay(index),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
              growable: false,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: selectedSlots
                .mapIndexed(
                  (index, _) => GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSlots[index] = !selectedSlots[index];
                      });
                    },
                    child: CircleAvatar(
                      radius: 24.0,
                      backgroundColor: Color(
                        context.read<SettingsProvider>().primarySwatch,
                      ),
                      foregroundColor: Colors.white,
                      child: selectedSlots[index] == true
                          ? Icon(
                              PlatformX.isMaterial(context)
                                  ? Icons.done
                                  : CupertinoIcons.checkmark_alt,
                            )
                          : Text(
                              (index + 1).toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
      actions: [
        PlatformDialogAction(
          child: Text(S.of(context).cancel),
          onPressed: () => Navigator.pop(context),
        ),
        PlatformDialogAction(
          child: Text(S.of(context).add),
          onPressed: () {
            Navigator.pop(
              context,
              newCourseTimeGenerator(selectedWeekDay, selectedSlots),
            );
          },
        ),
      ],
    );
  }
}
