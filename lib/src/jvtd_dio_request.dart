import 'dart:async';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

import 'package:dio/dio.dart' as dio;

import 'jvtd_http_print.dart';
import 'jvtd_http_utils.dart' as httpUtils;
import 'jvtd_http_config.dart' as work;

/// 发起请求
///
/// dio实现
Future<httpUtils.Response> request(String tag, httpUtils.Options options) async {
  final dioOptions = _onConfigOptions(tag, options);

  dio.Response dioResponse;

  bool success = false;

  try {
    switch (options.method) {
      case httpUtils.HttpMethod.download:
        httpLog(tag, "下载地址:${options.downloadPath}");
        dioResponse =
            await work.dio.download(options.url, options.downloadPath, data: options.params, cancelToken: options.cancelToken.data, options: dioOptions, onReceiveProgress: options.onProgress);
        break;
      case httpUtils.HttpMethod.get:
        dioResponse = await work.dio.get(
          options.url,
          queryParameters: options.params,
          cancelToken: options.cancelToken.data,
          options: dioOptions,
        );
        break;
      case httpUtils.HttpMethod.upload:
        dioResponse = await work.dio.request(
          options.url,
          data: await _onConvertToDio(options.params),
          cancelToken: options.cancelToken.data,
          options: dioOptions,
          onSendProgress: options.onProgress,
        );
        break;
      default:
        dioResponse = await work.dio.request(
          options.url,
          data: options.params,
          cancelToken: options.cancelToken.data,
          options: dioOptions,
          onSendProgress: options.onProgress,
        );
        break;
    }

    success = true;
  } on dio.DioError catch (e) {
    httpLog(tag, "http 错误", e.type);
    dioResponse = e.response;
    success = false;
  } catch (e) {
    httpLog(tag, "http 其他错误", e);
  }

  return _onParseResponse(tag, success, dioResponse);
}

/// 用于[httpUtils.HttpMethod.upload]请求类型的数据转换
///
/// [src]原始参数，返回处理后的符合dio接口的参数
Future<dio.FormData> _onConvertToDio(Map<String, dynamic> src) async {
  onConvert(value) async {
    if (value is File) {
      value = httpUtils.UploadFileInfo(value.path);
    }

    if (value is httpUtils.UploadFileInfo) {
      return dio.MultipartFile.fromFile(
        value.filePath,
        filename: value.fileName,
        contentType: MediaType.parse(value.mimeType),
      );
    }

    return value;
  }

  final params = Map<String, dynamic>();

  for (final entry in src.entries) {
    if (entry.value is List) {
      params[entry.key] = await Stream.fromFutures((entry.value as List).map(onConvert)).toList();
    } else {
      params[entry.key] = await onConvert(entry.value);
    }
  }

  return dio.FormData.fromMap(params);
}

/// 生成dio专用配置
dio.Options _onConfigOptions(String tag, httpUtils.Options options) {
  final dioOptions = dio.Options();

  switch (options.method) {
    case httpUtils.HttpMethod.get:
    case httpUtils.HttpMethod.download:
      dioOptions.method = "GET";
      break;
    case httpUtils.HttpMethod.post:
    case httpUtils.HttpMethod.upload:
      dioOptions.method = "POST";
      break;
    case httpUtils.HttpMethod.put:
      dioOptions.method = "PUT";
      break;
    case httpUtils.HttpMethod.head:
      dioOptions.method = "HEAD";
      break;
    case httpUtils.HttpMethod.delete:
      dioOptions.method = "DELETE";
      break;
  }

  if (options.responseType != null) {
    switch (options.responseType) {
      case httpUtils.ResponseType.json:
        dioOptions.responseType = dio.ResponseType.json;
        break;
      case httpUtils.ResponseType.stream:
        dioOptions.responseType = dio.ResponseType.stream;
        break;
      case httpUtils.ResponseType.plain:
        dioOptions.responseType = dio.ResponseType.plain;
        break;
      case httpUtils.ResponseType.bytes:
        dioOptions.responseType = dio.ResponseType.bytes;
        break;
    }
  }

  if (options.headers != null) {
    dioOptions.headers.addAll(options.headers);
  }

  dioOptions.contentType = options.contentType;
  dioOptions.receiveTimeout = options.readTimeout;
  dioOptions.sendTimeout = options.sendTimeout;

  if (options.cancelToken.data is! dio.CancelToken) {
    httpUtils.CancelToken cancelToken = options.cancelToken;

    cancelToken.data = dio.CancelToken();

    cancelToken.stream.listen((_) {
      if (cancelToken.data is dio.CancelToken) {
        httpLog(tag, "http 取消");
        cancelToken.data.cancel();
        cancelToken.data = null;
      }
    });
  }

  return dioOptions;
}

/// 处理dio Response为work的Response
httpUtils.Response _onParseResponse(String tag, bool success, dio.Response dioResponse) {
  if (dioResponse != null) {
    return httpUtils.Response(
      success: success,
      statusCode: dioResponse.statusCode,
      headers: dioResponse.headers?.map,
      data: dioResponse.request?.responseType == dio.ResponseType.stream ? dioResponse.data.stream : dioResponse.data,
    );
  } else {
    return httpUtils.Response();
  }
}
