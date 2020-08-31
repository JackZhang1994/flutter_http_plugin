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
    _startTime = DateTime(2020, 8, 1);
    _endTime = DateTime(2020, 9, 1);
    String appTaskId = 'kjbzpr8azr';
    _userList = [
      WorkingHoursEntity(
        name: '陈磊',
        taskId: appTaskId,
        token:
            'NTMtNC1DV0FeX14tTjVmdU04RjNRTVlxaTdwZjU2RllZVEF6TkdKa05UaGlOV00wT1RSa00yVXlOakU0TXpsaU5UZGhNbUU1WXpZMU1HRmxaVEF5TURsa09UWTRaakkwTXpVMlpEUXlNRFV6TVdRNU5UY3dObU5QU1NrcUxHNVBtTVRJbzhlNUMrd2IwMVpJZnRudkttaHZIaEdQdlJqM2h3PT0=',
      ),
      WorkingHoursEntity(
        name: '张健夫',
        taskId: appTaskId,
        token:
            'MzgtNC1DV0FeX14tZ2YzSHhnUkFsR2x5ZEVEOXJ3K0IrRE5sTUROalpEWXpOelU1WXpJelpUSmtPRGs0WmpobFltRmpOVFJsTVRCbVlUaGtaalpoWkdJME5EazJOV1kwTlRnellqQmtOVEZrTWpVNU9UQTNOekVHNXlrb0oraXRDd0ltam5jZjUwUi84NTV3Z2plZllEaHhtWHh5MXU4S2t3PT0=',
      ),
      WorkingHoursEntity(
        name: '葛建民',
        taskId: appTaskId,
        token:
            'MzctNC1DV0FeX14tTDRMOXFybVo3MWRTZWpDbjl4TWd1elJqT0RJNVpHRmhOV05tWlROaU5UVmlOek5tWVdOaVltWTJaREZrTURjelkyTXpOV0l5TUdFek1ESmlOMlpsTmpCa1ltTmtPV000Tnpsak4yWTBaamp5WXE1SEw2MUVaeEF0NXVKTnVIMnk2eWRMNDE3RWVUcVU3S1N2UTVaWk13PT0=',
      ),
      WorkingHoursEntity(
        name: '赵远东',
        taskId: appTaskId,
        token:
            'MzktNC1DV0FeX14tM0FkazJ4cFpVdDlQMVltZ0k3RTRuV1ZtT0dJNVlqWTVaREpoTXpFNVlXWXhZVFk0T1RobU5UUTJOR1V5TkdZeE5tVTJPR0psTldVek16Sm1ZMlZsTm1WaVptVmlOMlprTVdVd1kyRXlOek5qRjh2dXJPRkhzOU03SjVvVUlXci9yeFpJWVRpTVpDejNqekRrRytzaGJBPT0=',
      ),
      WorkingHoursEntity(
        name: '祝又忠',
        taskId: appTaskId,
        token:
            'MTA3LTQtQ1dBXl9eLS90MldDWnJxZC9xdE1DaTJvUUwxcFRSbVpXSmxPVFpqTW1VM1ptVmtPVEppWmpOaE9XTTRZVFJsTXpWaFkyRmhaR05rTURoaVltSXlaakkzWldFMFpXWmlNRFk0TXpZNFpXTmhOV00zTnprV29FVjRLRUVGVkJBWUdqemhhK1JJQ2V5dFQvY1hpQUFUWXpJeEk1ZTFCUT09',
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
