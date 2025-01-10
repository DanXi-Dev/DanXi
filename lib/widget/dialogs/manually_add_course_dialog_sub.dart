import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

import '../../common/constant.dart';
import '../../generated/l10n.dart';
import '../../model/time_table.dart';
import '../../provider/settings_provider.dart';
import '../../util/platform_universal.dart';

class AddCourseDialogSub extends StatefulWidget {
  const AddCourseDialogSub({super.key});

  @override
  State<AddCourseDialogSub> createState() => _AddCourseDialogSubState();
}

class _AddCourseDialogSubState extends State<AddCourseDialogSub> {
  int selectedWeekDay = 0;
  List<bool> selectedSlots = List.generate(15, (index) => false);
  List<CourseTime>? newCourseTime;

  List<CourseTime>? newCourseTimeGenerator(
      int selectedWeekDay, List<bool> selectedSlots) {
    List<CourseTime>? newCourseTime = [];
    int index = 0;
    for (var element in selectedSlots) {
      if (element == true) {
        newCourseTime.add(CourseTime(selectedWeekDay, index));
      }
      index++;
    }
    return newCourseTime;
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
                                  Constant.WeekDays[e],
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
