import 'package:dio/dio.dart';

/// [http]debug模式
bool debug = true;

/// 全局使用的[Dio]请求对象
Dio dio = Dio(
  BaseOptions(
    connectTimeout: 30000,
    receiveTimeout: 30000,
    contentType: "application/x-www-form-urlencoded",
    responseType: ResponseType.plain,
  ),
);