import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../jvtd_http_utils.dart';

/// 用于[com.HttpMethod.upload]请求类型的数据转换
///
/// [src]原始参数，返回处理后的符合dio接口的参数
Future<FormData> convertToDio(Map<String, dynamic> src) async {
  Future<dynamic> onConvert(value) async {
    if (value is UploadFileInfo) {
      return MultipartFile(
        value.stream,
        value.length,
        filename: value.fileName,
        contentType: MediaType.parse(value.mimeType),
      );
    }

    return value;
  }

  final params = <String, dynamic>{};

  for (final entry in src.entries) {
    if (entry.value is List) {
      params[entry.key] =
          await Stream.fromFutures(entry.value.map<Future<dynamic>>(onConvert))
              .toList();
    } else {
      params[entry.key] = await onConvert(entry.value);
    }
  }

  return FormData.fromMap(params);
}
