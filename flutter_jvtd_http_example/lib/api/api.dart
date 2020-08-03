export 'get_code_api.dart';

import 'dart:convert';

import 'package:jvtd_http/jvtd_http.dart';

import 'base_api.dart';

class WorkingHoursApi extends OaBaseApi{
  final String token;

  WorkingHoursApi(this.token);

  @override
  String apiUrl() {
    return 'https://itemapi.weiyingjia.org/';
  }

  @override
  onResponseCode(response) {
    if (response is String) {
      response = jsonDecode(response);
    }
    return response['code'].toString();
  }

  /// 接口正确的状态码判断
  @override
  bool onResponseResult(response) {
    if (response is String) {
      response = jsonDecode(response);
    }
    String codeStr = onResponseCode(response);
    return codeStr == '200';
  }

  @override
  Map<String, dynamic> onHeaders(dynamic params) {
    Map<String, dynamic> data = Map();
    if (isToken()) {
      data['Token'] = userToken();
    }
    return data;
  }

  @override
  String userToken() {
    return token;
  }

  @override
  String apiMethod(params) {
    return 'task-hours/add';
  }

  @override
  onExtractResult(resultData, HttpData data) {
    return resultData;
  }
}