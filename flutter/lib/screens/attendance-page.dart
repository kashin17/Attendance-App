import 'dart:async';
import 'dart:convert';

import 'package:attendance_app/constants.dart';
import 'package:attendance_app/screens/authPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';


class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {

  Location location = new Location();
  var location1 = '';
  var location2 = '';
  bool? _serviceEnabled;
  PermissionStatus? _permissionStatus;
  LocationData? _locationData;
  bool _checkingIn = false;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _records2 = [];

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  Map<String, List<Map<String,dynamic>>> _monthlyRecords = {};


  final apikey = 'http://172.20.10.4:3000/checkin';
  final apikey2 = 'http://172.20.10.4:3000';

  Future<void> _fetchRecords() async{
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('${apikey2}/records/1'),
      headers: <String,String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    if(response.statusCode == 200){
      setState(() {
        _records = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    }else{
      throw Exception('Failed to load records.');
    }
  }

  Future<void> _fetchTodayRecords() async{
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('${apikey2}/todayrecords/1'),
      headers: <String,String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    if(response.statusCode == 200){
      setState(() {
        _records2 = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    }else{
      throw Exception('Failed to load records.');
    }
  }

  Future<void> _fetchMonthlyRecords() async{
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if(token == null){
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('${apikey2}/monthlyrecords/1/$_selectedYear/$_selectedMonth'),
      headers: <String,String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if(response.statusCode == 200){
      final List<dynamic> rawRecords = jsonDecode(response.body);
      final Map<String, List<Map<String,dynamic>>> organizedRecords = {};

      for (var record in rawRecords){
        final date = record['date'];
        final time = record['time'];
        final radiusCheck = record['radius_check'];

        if(organizedRecords[date] == null){
          organizedRecords[date] = [];
        }
        organizedRecords[date]!.add({
          'time': time,
          'radius_check': radiusCheck,
        });
      }
      setState(() {
        _monthlyRecords = organizedRecords;
      });
    }else{
      throw Exception('Failed to load records');
    }
  }

  Future<void> _checkIn() async {
    setState(() {
      _checkingIn = true;
    });

    _locationData = await location.getLocation();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('Token from SharedPreferences: $token');

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.post(
      Uri.parse(apikey),
      headers: <String,String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String,dynamic>{
        //'userId' : 1,
        'latitude': _locationData!.latitude,
        'longitude': _locationData!.longitude,

      }),
    );
    setState(() {
      _checkingIn = false;
      _fetchRecords();
      _fetchTodayRecords();
    });

    if(response.statusCode == 200){
      ScaffoldMessenger.of(context).showSnackBar(
        //SnackBar(content: Text('Check-in successful')),
          SnackBar(content: Text(location as String)),
      );
    }else{
      print('response status: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        //SnackBar(content: Text('Check-in failed')),
        SnackBar(content: Text(location as String)),

      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => AuthPage()),
    );
  }

  // String formatTime(String timeString) {
  //   DateTime dateTime = DateTime.parse(timeString);
  //   return '${dateTime.hour}:${dateTime.minute}';
  // }
  String formatTime(String dateTimeString) {
    try {
      // Define the input format
      //DateFormat inputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      DateFormat inputFormat = DateFormat("yyyy-MM-ddTHH:mm:ss.SSSZ");

      // Parse the input string to a DateTime object
     // DateTime dateTime = inputFormat.parse(dateTimeString);
     // DateTime dateTime = inputFormat.parseUtc(dateTimeString);
      // Parse the input string to a DateTime object (UTC)
      DateTime dateTimeUtc = inputFormat.parseUtc(dateTimeString);

      // Convert the DateTime object to local time
      DateTime dateTimeLocal = dateTimeUtc.toLocal();

      // Define the output format as 'HH:mm'
      DateFormat outputFormat = DateFormat('HH:mm');

      // Format the DateTime object to a string in 'HH:mm' format
      return outputFormat.format(dateTimeLocal);
    } catch (e) {
      // Handle any parsing or formatting errors
      return 'Invalid date/time format';
    }
  }

  String formatToTime(String TimeString) {
    try {
      // Define the input format
      DateFormat inputFormat = DateFormat('HH:mm:ss');

      // Parse the input string to a DateTime object
      DateTime dateTime = inputFormat.parse(TimeString);

      // Define the output format as 'HH:mm'
      DateFormat outputFormat = DateFormat('HH:mm');

      // Format the DateTime object to a string in 'HH:mm' format
      return outputFormat.format(dateTime);
    } catch (e) {
      // Handle any parsing or formatting errors
      return 'Invalid date/time format';
    }
  }


  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return '(${dateTime.day}-${dateTime.month}-${dateTime.year})';
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchRecords();
    _fetchTodayRecords();
    _fetchMonthlyRecords();
_getlocation();

  }
_getlocation() async {
  _locationData = await location.getLocation();

  location1 = _locationData!.latitude.toString();
  location2 = _locationData!.longitude.toString();
  print(_locationData!.longitude.toString());
}
  void _filterMonth(int? month){
    setState(() {
      _selectedMonth = month!;
      _fetchMonthlyRecords();
    });
  }

  void _filterYear(int? year){
    setState(() {
      _selectedYear = year!;
      _fetchMonthlyRecords();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance App',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emp No. : 111111X', style: TextStyle(color: Colors.white,fontSize: 16),
                  ),
                  SizedBox(height: 4,),
                  Text('Name : Kashin Arora',
                    style: TextStyle(color: Colors.white,fontSize: 16),
                  ),
                  SizedBox(height: 4,),
                  Text('Mobile No. : 9999999999',style: TextStyle(color: Colors.white,fontSize: 16),)
                ],
              ),
            ),
            SizedBox(height: 20,),
        
        
            Center(
              child: _checkingIn ? CircularProgressIndicator() :GestureDetector(
                onTap: _checkIn,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.grey , Colors.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Punch',style: TextStyle(color: Colors.white , fontSize: 24,fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Center(child: Text('( Click On Punch Button for Marking your Attendance )')),
            SizedBox(height: 30,),
        
        
        
        
            DefaultTabController(length: 2,
                child: Column(
                  children: [
                    TabBar(labelColor: Colors.teal,unselectedLabelColor: Colors.grey,indicatorColor: Colors.teal,
                      tabs: [Tab(text: 'TODAY',),Tab(text: 'MONTHLY',)],
                    ),
                    SizedBox(height: 20,),
                    Container(
                      child: Column(
                        children: [
                          Text("Today's Attendance",style: TextStyle(fontWeight: FontWeight.bold),),
                          Text('',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.grey.shade700),),
                        ],
                      ),
                    ),
                    Container(
                      height: 450,
                      child: TabBarView(
                        children: [

                          _buildTodayAttendanceTable(),

                          _buildMonthlyAttendanceTable(),
                        ],
                      ),
                    ),
                  ],
                )
            )
          ],
        ),
      ),
    );
  }


  Widget _buildTodayAttendanceTable(){


    return Padding(padding: EdgeInsets.all(16),
      child: Table(
        border: TableBorder.all(color: Colors.teal),
        children: [
          TableRow(
            children: [
              //_buildTableHeader('DATE'),
              _buildTableHeader('P1'),
              _buildTableHeader('P2'),
              _buildTableHeader('P3'),
              _buildTableHeader('P4'),
              _buildTableHeader('P5'),
              _buildTableHeader('P6'),
            ],
          ),

          TableRow(

            children: List.generate(6, (index) {

              if(index < _records2.length){
                return _buildTableCell(formatTime(_records2[index]['check_in_time']), _records2[index]['radius_check']);
              }else{
                return _buildTableCell('',2);
                }
    }),

              //_buildTableCell('26-7-2023'),
              // for (var record in _records2)
              //   _buildTableCell(formatTime(record['check_in_time'])),
              // for (int i = 0; i < _records2.length && i < 6; i++)
              //   _buildTableCell(formatTime(_records2[i]['check_in_time'])),
              // _buildTableCell('17:34'),
              // for(int i = _records2.length; i<6;i++)
              //   _buildTableCell(''),

              // _buildTableCell(''),
              // _buildTableCell(''),
              // _buildTableCell(''),

          ),
        ],
      ),
    );

  }

  Widget _buildMonthlyAttendanceTable(){

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: _selectedMonth,
                onChanged: _filterMonth,
                items: List.generate(12, (index) {
                  final month = index + 1;
                  return DropdownMenuItem<int>(
                    value: month,
                    child: Text(DateFormat('MMMM').format(DateTime(0,month))),
                  );
                },
              ),
              ),
              SizedBox(width: 16,),
              DropdownButton<int>(
                value: _selectedYear,
                onChanged: _filterYear,
                items: List.generate(5, (index){
                  final year = DateTime.now().year - 2 + index;
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                } ),
              ),
            ],
          ),
          SizedBox(height: 16,),
          Padding(padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: Table(
                border: TableBorder.all(color: Colors.teal),
                //columnWidths: {0: FractionColumnWidth(0.2)},
                columnWidths: {
                  0: FixedColumnWidth(100),
                  1: FixedColumnWidth(60),
                  2: FixedColumnWidth(60),
                  3: FixedColumnWidth(60),
                  4: FixedColumnWidth(60),
                  5: FixedColumnWidth(60),
                  6:FixedColumnWidth(60),
                },
                children: [
                  TableRow(
                    children: [
                      _buildTableHeader('DATE'),
                      _buildTableHeader('P1'),
                      _buildTableHeader('P2'),
                      _buildTableHeader('P3'),
                      _buildTableHeader('P4'),
                      _buildTableHeader('P5'),
                      _buildTableHeader('P6'),
                    ],
                  ),
                  ..._monthlyRecords.entries.map((entry){
                    final date = entry.key;
                    final records = entry.value;

                    return TableRow(
                      children: [
                        _buildTableCell(formatDate(date), 3),
                        ...List.generate(6, (index) {
                          final record = index < records.length ? records[index] : null;
                          return _buildTableCell(
                            record != null ? formatToTime(record['time']) : '',
                              record != null ? record['radius_check'] : 3,

                              // index < times.length ? formatToTime(times[index]):'', 0
                          );
                        }),
                      ],
                    );

                  }).toList(),
                  // for(var record in _monthlyRecords)
                  // TableRow(
                  //   children: [
                  //     _buildTableCell('', 3),
                  //     _buildTableCell('', 3),
                  //     _buildTableCell('', 3),
                  //     _buildTableCell('', 3),
                  //     _buildTableCell('', 3),
                  //     _buildTableCell('', 3),
                  //     _buildTableCell('', 3),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
          )
        ],
      ),
    );

    //return Center(child: Text('Monthly',style: TextStyle(fontSize: 16,),));
  }


  Widget _buildTableHeader(String text){
    return Padding(padding: EdgeInsets.all(8),
        child: Center(
          child: Text(
            text,   style: TextStyle(fontWeight: FontWeight.bold,),
          ),
        ),
    );

  }


  Widget _buildTableCell(String text , int inOffice){
    return Container(
      color: inOffice == 1 ? Colors.green : inOffice == 0 ? Colors. yellow.shade800 : Colors.grey,
      padding: EdgeInsets.all(8),
      child: Center(
        child: Text(text , style: TextStyle(color: Colors.white),),
      ),
    );
  }
}
