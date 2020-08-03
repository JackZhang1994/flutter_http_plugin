import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_jvtd_http_example/api/api.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GetCaptchaImageApi _getCaptchaImageApi;
  WorkingHoursApi _workingHoursApi;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('网络框架接口Demo'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            title: Text(
              '普通接口',
              textAlign: TextAlign.center,
            ),
            onTap: () {
//              _index = 0;
//              Timer.periodic(Duration(milliseconds: 10), (t){
//                _index++;
//                if(_index  > 10){
//                  t?.cancel();
//                  return;
//                }
//                _getImageCode();
//              });
              _getImageCode();
            },
          ),
          ListTile(
            title: Text(
              '刷工时',
              textAlign: TextAlign.center,
            ),
            onTap: _workingHours,
          )
        ],
      ),
    );
  }

  _getImageCode() {
    _getCaptchaImageApi?.cancel();
    if (_getCaptchaImageApi == null) _getCaptchaImageApi = GetCaptchaImageApi();
    _getCaptchaImageApi.start(params: {"data": {}, "requestId": '123'}).then((res) {});
  }

  void _workingHours() {
    String taskId = 'm6vz8949d8';
    int tHours = 8;
    String token = 'MTA3LTQtQ1dBXl9eLWx2SHFiOTFnME55S2R1QSt6MmlEb3pjeE56TmhPVE14TXpnMU1EVmxZVGRrTkRZd1ptSmxaVEF4TlRoalpUa3lPR0ZsTm1Kak1qZGhZelEzWXpGbVpHUmxZVGRrT1dFNVpUaG1ZemxsWlRFdXZENTM0QkI5b0JMRG5weUdBWDM4bjVrL29TVlFtQXZFUkVhMzBnN1VOdz09';

    DateTime start = DateTime(2020, 4, 1);
    DateTime end = DateTime(2020, 7, 31);
    if (_workingHoursApi == null) _workingHoursApi = WorkingHoursApi(token);

    DateTime now = start;
    int e = end.compareTo(now);
    print(e);

    while (end.compareTo(now) == 1) {
      String time = '${now.year}-${now.month}-${now.day}';
      String weekday = '星期${now.weekday}';
      if (now.weekday != 6 && now.weekday != 7) {
        print('今天是$time,$weekday');
        _workingHoursApi.start(params: {
          't_date': time,
          'task_id': taskId,
          't_hours': tHours,
          'des':'',
        });
      } else {
        print('今天是$time,$weekday');
        print('今天放假了');
      }
      now = now.add(Duration(days: 1));
    }
  }
}
