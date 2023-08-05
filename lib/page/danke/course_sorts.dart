// import 'package:flutter/material.dart';
// import 'course_model.dart';
//
// class CourseList extends StatefulWidget {
//   @override
//   _CourseListState createState() => _CourseListState();
// }
//
// class _CourseListState extends State<CourseList> {
//   String selectedDepartment = 'All'; // 默认显示全部
//
//   List<Course> filteredCourses = courses;
//
//   void _filterCourses(String department) {
//     if (department == 'All') {
//       setState(() {
//         filteredCourses = courses;
//       });
//     } else {
//       setState(() {
//         filteredCourses =
//             courses.where((course) => course.department == department).toList();
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     List<String> departments = [
//       'All',
//       'Department 1',
//       'Department 2',
//       'Department 3'
//     ];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Course List'),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Container(
//             padding: EdgeInsets.all(16.0),
//             child: DropdownButton<String>(
//               value: selectedDepartment,
//               onChanged: (String? newValue) {
//                 setState(() {
//                   selectedDepartment = newValue!;
//                 });
//                 _filterCourses(selectedDepartment);
//               },
//               items: departments.map<DropdownMenuItem<String>>((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredCourses.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   title: Text(filteredCourses[index].name),
//                   subtitle: Text(filteredCourses[index].department),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
