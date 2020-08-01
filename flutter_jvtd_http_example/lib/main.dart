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
              '分页接口',
              textAlign: TextAlign.center,
            ),
            onTap: () {
//              _getImageCode();
//              _getImageCode();
              for (int i = 0; i < 10; i++) {
                _getImageCode();
              }
            },
          )
        ],
      ),
    );
  }

  _getImageCode() {
    _getCaptchaImageApi?.cancel();
    if (_getCaptchaImageApi == null) _getCaptchaImageApi = GetCaptchaImageApi();
    _getCaptchaImageApi.start(params: {"data": {}, "requestId": '123'}).then((res) {

    });
  }
}
