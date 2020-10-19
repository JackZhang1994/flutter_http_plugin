import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;

import 'jvtd_http_print.dart';
import 'jvtd_http_utils.dart' as httpUtils;
import 'jvtd_http_config.dart' as work;

import 'convert/jvtd_http_convert.dart' if (dart.library.html) 'convert/jvtd_http_convert_web.dart' if (dart.library.io) 'convert/jvtd_http_convert_native.dart';

/// 发起请求
///
/// dio实现
Future<httpUtils.Response> request(String tag, httpUtils.Options options) async {
  final dioOptions = _onConfigOptions(tag, options);

  dio.Response dioResponse;
  dynamic dioError;

  httpUtils.HttpErrorType errorType;

  bool success = false;

  // 总接收字节数
  var receiveByteCount = 0;

  // 结果解析器
  final decoder = (responseBytes, options, responseBody) {
    receiveByteCount = responseBytes.length;
    return utf8.decode(responseBytes, allowMalformed: true);
  };

  dioOptions.responseDecoder = decoder;

  final isFormData = options.method == httpUtils.HttpMethod.upload || (options.contentType ?? work.dio.options.contentType) == httpUtils.formData;

  try {
    switch (options.method) {
      case httpUtils.HttpMethod.download:
        httpLog(tag, "下载地址:${options.downloadPath}");
        // 接收进度代理
        final onReceiveProgress = (int receive, int total) {
          receiveByteCount = receive;
          options.onReceiveProgress?.call(receive, total);
        };

        dioResponse = await work.dio.download(
          options.url,
          options.downloadPath,
          data: options.params,
          cancelToken: options.cancelToken.data,
          options: dioOptions,
          onReceiveProgress: onReceiveProgress,
        );
        break;
      case httpUtils.HttpMethod.get:
        dioResponse = await work.dio.get(
          options.url,
          queryParameters: options.params,
          cancelToken: options.cancelToken.data,
          options: dioOptions,
          onReceiveProgress: options.onReceiveProgress,
        );
        break;
      default:
        dioResponse = await work.dio.request(
          options.url,
          data: isFormData ? await convertToDio(options.params) : options.params,
          cancelToken: options.cancelToken.data,
          options: dioOptions,
          onSendProgress: options.onSendProgress,
          onReceiveProgress: options.onReceiveProgress,
        );
        break;
    }

    success = true;
  } on dio.DioError catch (e) {
    httpLog(tag, "http 错误", e.type);
    dioResponse = e.response;
    success = false;
    dioError = e.error;
    errorType = _onConvertErrorType(e.type);
  } catch (e) {
    httpLog(tag, "http 其他错误", e);
    errorType = httpUtils.HttpErrorType.other;
  }

  if (dioResponse != null) {
    return httpUtils.Response(
      success: success,
      statusCode: dioResponse.statusCode,
      headers: dioResponse.headers?.map,
      data: dioResponse.request?.responseType == dio.ResponseType.stream ? dioResponse.data.stream : dioResponse.data,
      errorType: errorType,
      dioError: dioError,
      receiveByteCount: receiveByteCount,
    );
  } else {
    return httpUtils.Response(errorType: errorType);
  }
}

/// 转换dio异常类型到work库异常类型
httpUtils.HttpErrorType _onConvertErrorType(dio.DioErrorType type) {
  switch (type) {
    case dio.DioErrorType.CONNECT_TIMEOUT:
      return httpUtils.HttpErrorType.connectTimeout;
    case dio.DioErrorType.SEND_TIMEOUT:
      return httpUtils.HttpErrorType.sendTimeout;
    case dio.DioErrorType.RECEIVE_TIMEOUT:
      return httpUtils.HttpErrorType.receiveTimeout;
    case dio.DioErrorType.RESPONSE:
      return httpUtils.HttpErrorType.response;
    case dio.DioErrorType.CANCEL:
      return httpUtils.HttpErrorType.cancel;
    default:
      return httpUtils.HttpErrorType.other;
  }
}

/// 生成dio专用配置
dio.Options _onConfigOptions(String tag, httpUtils.Options options) {
  final dioOptions = dio.RequestOptions();

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
  dioOptions.connectTimeout = options.connectTimeout;

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
