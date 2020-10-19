import 'package:dio/dio.dart';

/// 用于[HttpMethod.upload]请求类型的数据转换
///
/// [src]原始参数，返回处理后的符合dio接口的参数
Future<FormData> convertToDio(Map<String, dynamic> src) =>
    throw UnsupportedError('');
