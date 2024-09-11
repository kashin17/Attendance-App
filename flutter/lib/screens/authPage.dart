import 'dart:convert';

import 'package:attendance_app/screens/attendance-page.dart';
import 'package:attendance_app/screens/checkIn-page.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;

  final apikey = 'http://172.20.10.4:3000';

  Future<void> _authenticate() async{
    final url = _isLogin ? '$apikey/login' : '$apikey/register';
    final response = await http.post(
      Uri.parse(url),
      headers: <String,String>{
        'Content-Type' : 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String,String>{
        'username': _usernameController.text,
        'password' : _passwordController.text,
      }),
    );

    if(response.statusCode == 200){
      if(_isLogin){
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', jsonDecode(response.body)['token']);
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AttendancePage()),
        );
      }else{
        setState(() {
          _isLogin = true;
        });
      }
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login': 'Register',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: kTextFieldDecoration.copyWith(labelText: 'Username'),
            ),
            SizedBox(height: 15.0,),
            TextField(
              controller: _passwordController,
              decoration: kTextFieldDecoration.copyWith(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20,),
            ElevatedButton(
                onPressed: _authenticate,
                child: Text(_isLogin ? 'Login' : 'Register'),
            ),
            TextButton(onPressed: (){setState(() {
              _isLogin = !_isLogin;
            });}, child: Text(_isLogin ? 'Create an account' : 'Have an account? Login',
              ),
            )
          ],
        ),
      ),
    );
  }
}
