import 'package:flutter/material.dart';
import 'package:flutter_jvtd_http_example/api/api.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '聚通达工时',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class WorkingHoursEntity {
  final String name;
  final String taskId;
  final String token;
  final int tHours;
  final String tDes;

  WorkingHoursEntity({@required this.name, @required this.taskId, @required this.token, this.tHours = 10, this.tDes = ''});
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WorkingHoursApi _workingHoursApi;
  List<WorkingHoursEntity> _userList;
  DateTime _startTime;
  DateTime _endTime;

  @override
  Widget build(BuildContext context) {
    _initData(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('聚通达项目管理工时'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return _buildItem(_userList[index]);
        },
        itemCount: _userList.length,
      ),
    );
  }

  void _initData(BuildContext context) {
    _startTime = DateTime(2020, 9, 1);
    _endTime = DateTime(2020, 10, 1);
    String _clTaskId = 'm6vz8x6gz8';
    String _clToken =
        'NTMtNC1DV0FeX14tMlFtcjBKVDhvaCtFMTgzN1BlL0U3emd4TnprMVpHVTJaVGN3WVdOaE1ETXpNRFE1TnpJME1tSmxNVGxpTW1aaE5qVmxOelJqWkRGak1XTmtOakUxWXpFMlpXVTBNMlppTldaaU9UVTNZakZDa09yTVY5cjZMaG9kUmJNblYxWFZFRzlWTjlsaUxPVmMraGQ2QzZSTk1BPT0=';
    String _zjfTaskId = 'xv7zxyrrdy';
    String _zjfToken =
        'MzgtNC1DV0FeX14tZGswV0s3eG83QitzTDZYZzVwMEY0emRrTVRZNU9XVTJOVE15TkRZMVpEUXdOVFJrWVdZNU5XVTNaRE16TkRnM01qbGtZbVV3T0RWallqRTNOelpoWkRJME5EWmtObVJsT1RaallqWTFOVGx0TmVKeitGOGgvVlBMWVJ2MWV0MDkrVGppbVF6V0RjRUs0RHJ5Y0k4RCtBPT0=';
    String _zyzTaskId = 'kjbdpbpndr';
    String _zyzToken =
        'MTA3LTQtQ1dBXl9eLTZyc0dSK01lcUtOTXRhTy8zL1hkeXpoaFlqWTJPRFV3T1Rnd016TXpaak15TWpneU1EZzRNbVV3TjJNNVkyTTFNVGRtTldKa1pqTTNZMk00T1RVellUTXdaVE5qWTJVNE1XUXpORGRrTldJUWU0YkQrTjJuSFg3ZnlNd3BCcFVCREphVC9jU0dwaUtlbm82QzZoNHJsdz09';
    String _zydTaskId = 'ak9zar44dy';
    String _zydToken =
        'MzktNC1DV0FeX14ta0RhczkwQ0ZiL3FNK3Q3Y0Rua0pTekU0TlRKaU16aGxOalE0TVRGbE4yVm1aREUzTjJOaU1qUmpaREkxWVdabFptSXpZekF4TVdGa1lUTmpOV1poWkdRNU16Z3hZbVJoTmpaa09UTXpPV1loWUVVWmdISHlweVdJTjJxaUtWd3QvOUEwc0cySGdZaUt4cExwMWwyeDV3PT0=';
    String _gjmTaskId = 'q54znge4dg';
    String _gjmToken =
        'MzctNC1DV0FeX14tQXpoWjlBTXZ4V1V0UldRTGdFMitobUV4TVROaE5UUmhZMlUzT0daaU5qRXhaak16WlRCaVpXSmpNVEU1TmpJNU9HRTFZall4WkRObE56TXhNVEE0TURkak9ESmhNV1l4TW1VNE5EQXhPVERzZlNhRTRrOTh4TkxHQWs1djByT3VsSlN0L3JsS1hLako2VEZjSm9rVXVBPT0=';
    _userList = [
      WorkingHoursEntity(
        name: '陈磊',
        taskId: _clTaskId,
        token: _clToken,
      ),
      WorkingHoursEntity(name: '张健夫', taskId: _zjfTaskId, token: _zjfToken),
      WorkingHoursEntity(
        name: '葛建民',
        taskId: _gjmTaskId,
        token: _gjmToken,
      ),
      WorkingHoursEntity(
        name: '赵远东',
        taskId: _zydTaskId,
        token: _zydToken,
      ),
      WorkingHoursEntity(
        name: '祝又忠',
        taskId: _zyzTaskId,
        token: _zyzToken,
      ),
    ];
  }

  Widget _buildItem(WorkingHoursEntity workingHoursEntity) {
    return GestureDetector(
      onTap: () {
        _workingHours(workingHoursEntity);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: BoxConstraints.expand(height: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(100)),
        child: Text(
          workingHoursEntity.name,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  void _workingHours(WorkingHoursEntity workingHoursEntity) {
    String taskId = workingHoursEntity.taskId;
    int tHours = workingHoursEntity.tHours;
    String token = workingHoursEntity.token;

    DateTime start = _startTime;
    DateTime end = _endTime;
    _workingHoursApi = WorkingHoursApi(token);

    DateTime now = start;
    int e = end.compareTo(now);
    print(e);

    while (end.compareTo(now) == 1) {
      String time = '${now.year}-${now.month}-${now.day}';
      String weekday = '星期${now.weekday}';
      if (now.weekday != 6 && now.weekday != 7) {
        print('今天是$time,$weekday');
        _workingHoursApi.start(params: {'t_date': time, 'task_id': taskId, 't_hours': tHours, 'des': ''});
      } else {
        print('今天是$time,$weekday');
        print('今天放假了');
      }
      now = now.add(Duration(days: 1));
    }
  }
}
