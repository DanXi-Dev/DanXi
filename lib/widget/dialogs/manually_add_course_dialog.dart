import 'package:collection/collection.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/platform_universal.dart';
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
    newCourse.times ??= [];

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

  static final _blanksRegex = RegExp(r"\s+");

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
    newCourse.teacherNames = courseTeacherNameController.text.trim().split(
      _blanksRegex,
    );
    newCourse.availableWeeks = courseAvailableList;
    newCourse.roomName = courseRoomNameController.text;

    return newCourse;
  }

  void onButtonPressed() async {
    List<CourseTime>? courseTime = await showPlatformDialog<List<CourseTime>>(
        context: context, builder: (context) => const AddCourseDialogSub());
    if (courseTime != null) {
      setState(() {
        newCourse.times = (newCourse.times!.toSet()..addAll(courseTime))
            .sorted();
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
                children: List.generate(18, (index) => index + 1)
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
                    .toList(),
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
            onPressed: () => {Navigator.pop(context)}),
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
    newCourse.times!.removeWhere((time) => time.weekDay == weekDay);
  }
}

/// Slots selector for the course.
class AddCourseDialogSub extends StatefulWidget {
  const AddCourseDialogSub({super.key});

  @override
  State<AddCourseDialogSub> createState() => _AddCourseDialogSubState();
}

class _AddCourseDialogSubState extends State<AddCourseDialogSub> {
  int selectedWeekDay = 0;
  final selectedSlots = List.filled(
    TimeTable.kCourseSlotStartTime.length,
    false,
  );
  List<CourseTime>? newCourseTime;

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
              children: List.generate(7, (index) => index)
                  .map((e) => GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedWeekDay = e;
                          });
                        },
                        child: CircleAvatar(
                          radius: 24.0,
                          backgroundColor: Color(
                              context.read<SettingsProvider>().primarySwatch),
                          foregroundColor: Colors.white,
                          child: e == selectedWeekDay
                              ? Icon(PlatformX.isMaterial(context)
                                  ? Icons.done
                                  : CupertinoIcons.checkmark_alt)
                              : Text(
                                  Constant.weekDay(e),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900),
                                ),
                        ),
                      ))
                  .toList()),
          const SizedBox(height: 20),
          Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(14, (index) => index)
                  .map((e) => GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSlots[e] = !selectedSlots[e];
                          });
                        },
                        child: CircleAvatar(
                          radius: 24.0,
                          backgroundColor: Color(
                              context.read<SettingsProvider>().primarySwatch),
                          foregroundColor: Colors.white,
                          child: selectedSlots[e] == true
                              ? Icon(PlatformX.isMaterial(context)
                                  ? Icons.done
                                  : CupertinoIcons.checkmark_alt)
                              : Text(
                                  (e + 1).toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900),
                                ),
                        ),
                      ))
                  .toList()),
        ],
      ),
      actions: [
        PlatformDialogAction(
            child: Text(S.of(context).cancel),
            onPressed: () => Navigator.pop(context)),
        PlatformDialogAction(
            child: Text(S.of(context).add),
            onPressed: () {
              Navigator.pop(context,
                  newCourseTimeGenerator(selectedWeekDay, selectedSlots));
            }),
      ],
    );
  }
}
