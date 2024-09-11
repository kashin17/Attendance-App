import 'package:attendance_app/screens/attendance-PreviewTest.dart';
import 'package:attendance_app/screens/attendance-page.dart';
import 'package:attendance_app/screens/authPage.dart';
import 'package:attendance_app/screens/checkIn-page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: Scaffold(
      //   appBar: AppBar(
      //     title: Text('Attendance App',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
      //     backgroundColor: Colors.teal,
      //     centerTitle: true,
      //   ),
      //   body:
      // home: AttendancePreview(),
       home:   FutureBuilder(
        future: _isAuthenticated(),
        builder: (context,snapshot){
        if(snapshot.connectionState == ConnectionState.waiting){
          return CircularProgressIndicator();
        }else if (snapshot.data == true){
          return AttendancePage();
        }else{
          return AuthPage();
        }
      },
      ),

      // home: FutureBuilder(
      //   future: _isAuthenticated(),
      //   builder: (context,snapshot){
      //     if(snapshot.connectionState == ConnectionState.waiting){
      //       return CircularProgressIndicator();
      //     }else if (snapshot.data == true){
      //       return CheckInPage();
      //     }else{
      //       return AuthPage();
      //     }
      //   },
      // ),
    );
  }
}


