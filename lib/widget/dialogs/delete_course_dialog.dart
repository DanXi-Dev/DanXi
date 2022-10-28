import 'package:dan_xi/model/time_table.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../generated/l10n.dart';

class DeleteCourseDialog extends StatefulWidget {
  DeleteCourseDialog(this.manuallyAddedCourseList, {Key? key})
      : super(key: key);

  List<Course> manuallyAddedCourseList;

  @override
  State<DeleteCourseDialog> createState() => _DeleteCourseDialogState();
}

class _DeleteCourseDialogState extends State<DeleteCourseDialog> {
  List<String> toBeDeleted = [];

  List<Widget> generateCourseList() {
    List<Widget> courseList = widget.manuallyAddedCourseList
        .map((e) => Row(
              children: [
                Checkbox(
                    value: toBeDeleted.contains(e.courseName),
                    onChanged: (bool? value) {
                      bool selected = value ?? false;
                      setState(() {
                        selected
                            ? toBeDeleted.add(e.courseName!)
                            : toBeDeleted.remove(e.courseName!);
                      });
                    }),
                Expanded(
                    child: ListTile(
                  title: Text(e.courseName!),
                  subtitle: Text(e.courseId!),
                ))
              ],
            ))
        .toList();
    return courseList;
  }

  @override
  Widget build(BuildContext context) {
    generateCourseList();
    return PlatformAlertDialog(
      title: Text(S.of(context).delete),
      content: SingleChildScrollView(
          child: Column(
        children: generateCourseList(),
      )),
      actions: [
        PlatformDialogAction(
            child: Text(S.of(context).cancel),
            onPressed: () => {Navigator.pop(context)}),
        PlatformDialogAction(
            child: Text(S.of(context).confirm),
            onPressed: () {
              widget.manuallyAddedCourseList.removeWhere(
                  (element) => toBeDeleted.contains(element.courseName));
              Navigator.pop(context, widget.manuallyAddedCourseList);
            })
      ],
    );
  }
}
