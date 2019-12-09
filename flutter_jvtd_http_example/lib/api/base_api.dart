import 'package:jvtd_http/jvtd_http.dart';
import 'package:flutter/material.dart';
import 'dart:io';

//普通接口基类
abstract class BaseApi<D> extends SimpleApi<D> {
  final BuildContext context;

  BaseApi({this.context});

  @override
  String onUrl(dynamic params) => "http://readingapp.yunpaas.cn/reading-api/" + apiMethod(params);

  @protected
  String apiMethod(dynamic params);

  @override
  String responseResult() {
    return 'data';
  }

  @override
  void onFillParams(Map<String, dynamic> data, Map<String, dynamic> params) {
//    data["version"] = "V1.0";
//    data["data"] = params;
    data.addAll(params);
  }

  @override
  onResponseCode(response) {
    return response['code'];
  }

  @override
  bool onResponseResult(response) {
    return response['code'] == '200' || response['code'] == 200;
  }

  @override
  String onRequestFailedMessage(response, HttpData<D> data) {
    return response['msg'];
  }

  @override
  String onRequestSuccessMessage(response, HttpData<D> data) {
    return response['msg'];
  }

  @override
  String onParamsError(dynamic params) {
    return '接口参数错误';
  }

  @override
  String onParseFailed(HttpData<D> data) {
    return '数据解析失败';
  }

  @override
  String onNetworkError(HttpData<D> data) {
    return '暂无网络连接，请链接网络后重试';
  }

  @override
  String onNetworkRequestFailed(HttpData<D> data) {
    return '网络异常，请稍后重试';
  }

  @override
  HttpMethod get httpMethod => HttpMethod.post;

  @override
  Map<String, dynamic> onHeaders(dynamic params) {
    Map<String, dynamic> data = Map();
    return data;
  }

  @override
  void onConfigOptions(Options options, dynamic params) {
    options.contentType = 'application/json; charset=utf-8';
  }
}
