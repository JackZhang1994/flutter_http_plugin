import 'package:flutter/material.dart';
import '../api/api.dart';

class ApiPage extends StatefulWidget {
  @override
  _ApiPageState createState() => _ApiPageState();
}

class _ApiPageState extends State<ApiPage> {
  LoginReqBean _loginReqBean;
  GetCodeApi _getCodeApi;
  GetCodeResBean _getCodeResBean;

  @override
  void initState() {
    super.initState();
    _loginReqBean = LoginReqBean(
      mobile: '18611785035',
      password: 'reanding123',
      userType: 'student',
      deviceName: '1111',
      uuid: '0000',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('普通接口'),
        centerTitle: true,
        actions: <Widget>[
          MaterialButton(
            onPressed: _getCode,
            child: Text('调用'),
            textColor: Colors.white,
            minWidth: 20,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Text('接口传入参数:'),
                  SizedBox(height: 8),
                  Text(_loginReqBean.toJson().toString()),
                  SizedBox(height: 16),
                  Text('接口接收参数:'),
                  SizedBox(height: 8),
                  _getCodeApi == null ? Text('请调用接口') : Text(_getCodeResBean != null ? _getCodeResBean.toJson().toString() : '接口调用失败'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  _getCode() {
    if (_getCodeApi == null) _getCodeApi = GetCodeApi();
    _getCodeApi.start(params: _loginReqBean.toJson()).then((value) {
      if (value.success) {
//        _getCodeResBean = value.result;
        print(value.result);
        setState(() {});
      } else {
        _getCodeResBean = null;
      }
    });
  }
}
