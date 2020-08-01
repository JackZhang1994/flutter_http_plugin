import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:jvtd_http/jvtd_http.dart';
import 'package:meta/meta.dart';

void main() {
  GetCaptchaImageApi api;
  api = GetCaptchaImageApi();
  api.start(params: {"data":{}}).then((res){
    print(res);
  });
//  api = GetCaptchaImageApi();
//  api.start(params: {"data":{}}).then((res){
//    print(res);
//  });
}
/// 获取图形验证码1
class GetCaptchaImageApi extends OaBaseApi<String> {
  GetCaptchaImageApi() : super();

  @override
  bool isToken() => false;

  @override
  String apiMethod(params) {
    return 'bp2/bp/auth/getImgCode';
  }

  @override
  String onExtractResult(resultData, HttpData<String> data) {
    return resultData;
  }
}
abstract class OaBaseApi<D> extends BopBaseApi<D> {
  OaBaseApi() : super();

  @override
  String apiUrl() {
    return 'https://bop201.jvtd.cn:234/bop/api/';
  }
}

const String RESPONSE_SUCCESS = '0000';

abstract class BopBaseApi<D> extends SimpleApi<D> {

  BopBaseApi();

  /// 是否需要token
  bool isToken() {
    return true;
  }

  String userToken() {
    return null;
  }

  @override
  bool isHttpSuccess() {
    return false;
  }

  //返回实体的key
  @override
  String responseResult() {
    return "data";
  }

  /// 接口base地址
  @protected
  String apiUrl();

  /// 接口全路径
  @override
  String onUrl(dynamic params) => apiUrl() + apiMethod(params);

  /// 填写接口方法
  @protected
  String apiMethod(dynamic params);

  /// 接口传参统一化处理
  /// params为传入参数
  /// data为接口最后参数
  @override
  void onFillParams(Map<String, dynamic> data, Map<String, dynamic> params) {
    data.addAll(params);
  }

  //返回的状态的
  @override
  onResponseCode(response) {
    if (response is String) {
      response = jsonDecode(response);
    }
    return response['code'];
  }

  /// 接口正确的状态码判断
  @override
  bool onResponseResult(response) {
    if (response is String) {
      response = jsonDecode(response);
    }
    String codeStr = onResponseCode(response);
    return codeStr == RESPONSE_SUCCESS;
  }

  @override
  D onRequestFailed(response, HttpData<D> data) {
    if (response is String) {
      response = jsonDecode(response);
    }
    //token过期处理
//    if (onResponseCode(response) == BopBase.tokenExpiredCode) {
//      BopApplication.eventBus.fire(TokenExpiredEvent());
//    }
    return super.onRequestFailed(response, data);
  }

  /// 接口错误信息返回
  @override
  String onRequestFailedMessage(response, HttpData<D> data) {
    if (response is String) {
      response = jsonDecode(response);
    }
    return response['msg'];
  }

  /// 接口正确信息返回
  @override
  String onRequestSuccessMessage(response, HttpData<D> data) {
    if (response is String) {
      response = jsonDecode(response);
    }
    return response['msg'];
  }

  /// 接口参数错误信息
  @override
  String onParamsError(dynamic params) {
    return '接口参数错误';
  }

  /// 接口解析异常信息
  @override
  String onParseFailed(HttpData<D> data) {
    return '数据解析失败';
  }

  /// 无网络信息
  @override
  String onNetworkError(HttpData<D> data) {
    return '暂无网络连接，请链接网络后重试';
  }

  /// 网络异常信息
  @override
  String onNetworkRequestFailed(HttpData<D> data) {
    try {
      return onRequestFailedMessage(json.decode(data.response.data), data);
    } catch (e) {
      return '网络异常，请稍后重试';
    }
  }

  /// 接口请求方式 默认post
  @override
  HttpMethod get httpMethod => HttpMethod.post;

  @override
  Map<String, dynamic> onHeaders(dynamic params) {
    Map<String, dynamic> data = Map();
    if (isToken()) {
      data['loginToken'] = userToken();
    }
    return data;
  }

  /// 接口解析方式  默认json
  @override
  void onConfigOptions(Options options, dynamic params) {
    options.contentType = 'application/json; charset=utf-8';
  }
}
