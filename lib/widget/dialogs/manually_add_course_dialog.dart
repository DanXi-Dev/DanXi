import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/widget/dialogs/manually_add_course_dialog_sub.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../provider/settings_provider.dart';
import '../../util/platform_universal.dart';

class ManuallyAddCourseDialog extends StatefulWidget {
  ManuallyAddCourseDialog(this.courseAvailableList, {Key? key})
      : super(key: key);

  TextEditingController courseNameController = TextEditingController();

  TextEditingController courseIdController = TextEditingController();

  TextEditingController courseRoomIdController = TextEditingController();

  TextEditingController courseTeacherNameController = TextEditingController();

  List<int> courseAvailableList;

  @override
  State<ManuallyAddCourseDialog> createState() =>
      _ManuallyAddCourseDialogState();
}

class _ManuallyAddCourseDialogState extends State<ManuallyAddCourseDialog> {
  Course newCourse = Course()..times = [];
  int selectedWeekDay = 0;
  List<bool> selectedSlots = List.generate(15, (index) => false);
  List<Widget> selectedCourseTimeInfo = [];

  Course newCourseListGenerator(
      TextEditingController courseNameController,
      TextEditingController courseIdController,
      TextEditingController courseRoomNameController,
      TextEditingController courseTeacherNameController,
      List<int> courseAvailableList,
      Course newCourse) {
    newCourse.courseName = courseNameController.text ?? "Unknown Course";
    newCourse.courseId = courseIdController.text;
    newCourse.roomId = "999999";
    newCourse.teacherNames = courseTeacherNameController.text.split(" ");
    newCourse.availableWeeks = courseAvailableList;
    newCourse.roomName = courseRoomNameController.text;
    newCourse.teacherIds = [""];

    return newCourse;
  }

  void onButtonPressed() async {
    List<CourseTime>? courseTime = await showPlatformDialog<List<CourseTime>>(
        context: context,
        builder: (context) =>
            AddCourseDialogSub(selectedWeekDay, selectedSlots));
    if (courseTime != null) {
      newCourse.times?.addAll(courseTime);
      selectedCourseTimeInfo.add(
        ListTile(
            title: Text(
          "${Constant.WeekDays[courseTime[0].weekDay]} ${slotsOfADayGenerator(courseTime)}",
          style: TextStyle(color: Color(Colors.black54.value)),
        )),
      );
      setState(() {});
    }
  }

  String slotsOfADayGenerator(List<CourseTime> courseTime) {
    List<String>? outCome = [];
    for (var element in courseTime) {
      outCome.add((element.slot + 1).toString());
    }
    return outCome.join(",") ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: Text(S.of(context).add_courses),
      content: Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: widget.courseNameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                    labelText: S.of(context).course_name,
                    icon: PlatformX.isMaterial(context)
                        ? const Icon(Icons.book)
                        : const Icon(CupertinoIcons.book)),
                autofocus: true,
              ),
              if (!PlatformX.isMaterial(context)) const SizedBox(height: 2),
              TextField(
                controller: widget.courseIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: S.of(context).course_id,
                    icon: PlatformX.isMaterial(context)
                        ? const Icon(Icons.numbers)
                        : const Icon(CupertinoIcons.number)),
                autofocus: true,
              ),
              if (!PlatformX.isMaterial(context)) const SizedBox(height: 2),
              TextField(
                controller: widget.courseRoomIdController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                    labelText: S.of(context).course_room_name,
                    icon: PlatformX.isMaterial(context)
                        ? const Icon(Icons.location_city)
                        : const Icon(CupertinoIcons.location_fill)),
                autofocus: true,
              ),
              if (!PlatformX.isMaterial(context)) const SizedBox(height: 2),
              TextField(
                controller: widget.courseTeacherNameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                    labelText: S.of(context).course_teacher_name,
                    icon: PlatformX.isMaterial(context)
                        ? const Icon(Icons.people)
                        : const Icon(CupertinoIcons.person_2_fill)),
                autofocus: true,
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
                  labelStyle: TextStyle(color: Color(Colors.black54.value)),
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
                                setState(
                                    () => widget.courseAvailableList.add(e));
                              }
                            },
                            child: CircleAvatar(
                              key: ObjectKey(e),
                              radius: 15.0,
                              backgroundColor: Color(context
                                  .read<SettingsProvider>()
                                  .primarySwatch_V2),
                              child: widget.courseAvailableList.contains(e)
                                  ? const Icon(Icons.done)
                                  : Text(
                                      "${e}",
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
                  labelStyle: TextStyle(color: Color(Colors.black54.value)),
                ),
                autofocus: false,
              ),
              Column(
                children: selectedCourseTimeInfo,
              ),
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
      ),
      actions: [
        PlatformDialogAction(
            child: Text(S.of(context).cancel),
            onPressed: () => {Navigator.pop(context)}),
        PlatformDialogAction(
            child: Text(S.of(context).ok),
            onPressed: () => Navigator.pop(
                context,
                newCourseListGenerator(
                    widget.courseNameController,
                    widget.courseIdController,
                    widget.courseRoomIdController,
                    widget.courseTeacherNameController,
                    widget.courseAvailableList,
                    newCourse))),
      ],
    );
  }
}
