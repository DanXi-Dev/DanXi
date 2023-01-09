import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../common/constant.dart';
import '../../model/time_table.dart';
import '../../provider/settings_provider.dart';

class AddCourseDialogSub extends StatefulWidget {
  AddCourseDialogSub(this.selectedWeekDay, this.selectedSlots, {Key? key})
      : super(key: key);

  int selectedWeekDay;
  List<bool> selectedSlots;

  @override
  State<AddCourseDialogSub> createState() => _AddCourseDialogSubState();
}

class _AddCourseDialogSubState extends State<AddCourseDialogSub> {
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
                            widget.selectedWeekDay = e;
                          });
                        },
                        child: CircleAvatar(
                          radius: 24.0,
                          backgroundColor: Color(
                              context.read<SettingsProvider>().primarySwatch_V2),
                          child: e == widget.selectedWeekDay
                              ? const Icon(Icons.done)
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
                            widget.selectedSlots[e] = !widget.selectedSlots[e];
                          });
                        },
                        child: CircleAvatar(
                          radius: 24.0,
                          backgroundColor: Color(
                              context.read<SettingsProvider>().primarySwatch_V2),
                          child: widget.selectedSlots[e] == true
                              ? const Icon(Icons.done)
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
              Navigator.pop(
                  context,
                  newCourseTimeGenerator(
                      widget.selectedWeekDay, widget.selectedSlots));
            }),
      ],
    );
  }
}
