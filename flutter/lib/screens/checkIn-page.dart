import 'dart:convert';

import 'package:attendance_app/constants.dart';
import 'package:attendance_app/screens/authPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {

  Location location = new Location();
  bool? _serviceEnabled;
  PermissionStatus? _permissionStatus;
  LocationData? _locationData;
  bool _checkingIn = false;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _records2 = [];


  final apikey = 'http://172.20.10.4:3000/checkin';
  final apikey2 = 'http://172.20.10.4:3000';

  //final token2 = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsImlhdCI6MTcyMjYwMDgyNSwiZXhwIjoxNzIyNjA0NDI1fQ.wBJnTpvA_5J1aPM9zr7DXAmPoK5bDdo4qxEntcMG0SE';
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
    });

    if(response.statusCode == 200){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in successful')),
      );
    }else{
      print('response status: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed')),
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

  String formatTime(String timeString) {
    DateTime dateTime = DateTime.parse(timeString);
    return '${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
  }
  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return '${dateTime.day}:${dateTime.month}:${dateTime.year}';
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchRecords();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Check-In'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 100,
          ),
          Center(
            child: _checkingIn ? CircularProgressIndicator() : ElevatedButton(
                onPressed: _checkIn,
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blueAccent, // Text color
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0), // Padding
                    shape: CircleBorder(),
                    minimumSize: Size(150, 150),
                  elevation: 10,
                ),
                child: Text('Check In',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),)
            ),
          ),
          SizedBox(
            height: 50,
          ),
          Expanded(
              child: _records.isEmpty
                  ? Center(child: Text('No records found'),)
                  : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black,width: 1)
                                    ),
                                    child: Table(
                                      border: TableBorder.all(color: Colors.black, width: 1), // Border for each cell
                                      columnWidths: {
                                        0: FixedColumnWidth(100.0),
                                        1: FixedColumnWidth(150.0),
                                        2: FixedColumnWidth(100.0),
                                        3: FixedColumnWidth(100.0),
                                        4: FixedColumnWidth(80.0),
                                      },
                                      children: [
                                        // Header row
                                        TableRow(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300], // Header background color
                                          ),
                                          children: [
                                            TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('UserID'))),
                                            TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('CheckIn Time'))),
                                            TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Latitude'))),
                                            TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Longitude'))),
                                            TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('InOffice'))),
                                          ],
                                        ),
                                        // Data rows
                                        for (var record in _records)
                                          TableRow(
                                            children: [
                                              TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text(record['user_id'].toString()))),
                                              TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text(record['check_in_time']))),
                                              TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text(record['latitude'].toString()))),
                                              TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text(record['longitude'].toString()))),
                                              TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text(record['radius_check'] == 1 ? 'Yes' : 'No'))),
                                            ],
                                          ),
                                      ],
                                    ),
                                    // child: DataTable(
                                    //   columnSpacing: 16.0,
                                    //   columns: [
                                    // DataColumn(label: Container(child: Text('UserID',textAlign: TextAlign.center,))),
                                    // DataColumn(label: Container(child: Text('CheckIn Time',textAlign: TextAlign.center,))),
                                    // DataColumn(label: Container(child: Text('Latitude',textAlign: TextAlign.center,))),
                                    // DataColumn(label: Container(child: Text('Longitude',textAlign: TextAlign.center,))),
                                    // DataColumn(label: Container(child: Text('InOffice',textAlign: TextAlign.center,))),
                                    //
                                    // ],
                                    // rows: _records
                                    //     .map((record) => DataRow(cells: [
                                    //                               DataCell(Container(child: Text(record['id'].toString()))),
                                    //                               DataCell(Container(child: Text(record['check_in_time']))),
                                    //                               DataCell(Container(child: Text(record['latitude'].toString()))),
                                    //                               DataCell(Container(child: Text(record['longitude'].toString()))),
                                    //                               DataCell(Container(child: Text(record['radius_check']==1 ? 'Yes' : 'No'))),
                                    //                             ])).toList(),
                                    // ),
                                  ),
                                ),
                    )
           ),
          // Expanded(child: ListView.builder(
          //   itemCount: _records.length,
          //     itemBuilder: (context,index){
          //       final record = _records[index];
          //       return ListTile(
          //         title: Text('Check-In Time: ${record['check_in_time']}'),
          //         subtitle: Text(
          //           'Location: ${record['latitude']}, ${record['longitude']}\n In Office: ${record['radius_check']}',
          //         ),
          //       );
          //     }
          //     )
          // ),
        ],
      ),
    );
  }
}

