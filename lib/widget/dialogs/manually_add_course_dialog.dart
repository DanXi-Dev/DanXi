import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/dialogs/manually_add_course_dialog_sub.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

class ManuallyAddCourseDialog extends StatefulWidget {
  const ManuallyAddCourseDialog(this.courseAvailableList, {super.key});

  final List<int> courseAvailableList;

  @override
  State<ManuallyAddCourseDialog> createState() =>
      _ManuallyAddCourseDialogState();
}

class _ManuallyAddCourseDialogState extends State<ManuallyAddCourseDialog> {
  Course newCourse = Course()..times = [];
  List<Widget> selectedCourseTimeInfo = [];

  TextEditingController courseNameController = TextEditingController();
  TextEditingController courseIdController = TextEditingController();
  TextEditingController courseRoomIdController = TextEditingController();
  TextEditingController courseTeacherNameController = TextEditingController();

  Course newCourseListGenerator(
      TextEditingController courseNameController,
      TextEditingController courseIdController,
      TextEditingController courseRoomNameController,
      TextEditingController courseTeacherNameController,
      List<int> courseAvailableList,
      Course newCourse) {
    newCourse.courseName = courseNameController.text;
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
        context: context, builder: (context) => const AddCourseDialogSub());
    if (courseTime != null) {
      newCourse.times!.addAll(courseTime);
      selectedCourseTimeInfo.add(
        ListTile(
            title: Text(
                "${Constant.WeekDays[courseTime[0].weekDay]} ${slotsOfADayGenerator(courseTime)}")),
      );
      setState(() {});
    }
  }

  String slotsOfADayGenerator(List<CourseTime> courseTime) {
    List<String>? outCome = [];
    for (var element in courseTime) {
      outCome.add((element.slot + 1).toString());
    }
    return outCome.join(",");
  }

  @override
  void dispose() {
    courseNameController.dispose();
    courseIdController.dispose();
    courseRoomIdController.dispose();
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
              controller: courseRoomIdController,
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
                        courseRoomIdController,
                        courseTeacherNameController,
                        widget.courseAvailableList,
                        newCourse));
              }
            }),
      ],
    );
  }
}
