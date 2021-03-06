import 'dart:async';
import 'package:meta/meta.dart';

import 'jvtd_http_print.dart';
import 'jvtd_http_utils.dart';

enum ParamType {
  map,
  list,
}

/// [Api]返回的数据包装类
///
/// 包含响应的全部数据，[T]类型的业务数据实例，[success]表示成功失败，
/// [message]服务响应的消息，http响应码[httpCode]，请求传入的参数[params],
/// 服务正真有用的数据对象[result]。
class HttpData<T> {
  /// 本次服务成功失败标志
  bool _success = false;

  /// 服务响应消息
  String _message;

  /// http响应码
  int _httpCode = 0;

  // 接口返回状态码
  dynamic _statusCode;

  /// 任务传入参数列表
  dynamic _params;

  /// 用于网络请求使用的参数
  Options _options;

  /// 返回实体
  Response _response;

  /// 任务结果数据
  T _result;

  /// 任务取消标志
  bool _cancel = false;

  /// 在一次[Api]执行生命周期中传递的自定义数据
  ///
  /// 通常在[Api]的某个生命周期方法中创建，以便在另一个生命周期中使用。
  /// 此额外属性并不参与网络请求
  dynamic extra;

  /// 判断本次服务请求是否成功(用户接口协议约定的请求结果，并非http的请求结果，但是http请求失败时该值总是返回false)
  bool get success => _success;

  /// 获取本次请求返回的结果消息(用户接口协议中约定的消息或者根据规则生成的本地信息，并非http响应消息）
  String get message => _message;

  /// 获取本次http请求返回的响应码
  int get httpCode => _httpCode;

  /// 获取任务传入的参数列表
  dynamic get params => _params;

  /// 获取处理完成的最终结果数据(用户接口协议中定义的有效数据转化成的本地类)
  T get result => _result;

  /// 用于网络请求使用的参数
  Options get options => _options;

  Response get response => _response;

  /// 任务是否被取消
  bool get cancel => _cancel;

  // 获取接口状态码
  dynamic get statusCode => _statusCode;
}

/// 网络请求工具
const JvtdHttpUtils httpUtils = JvtdHttpUtils();

/// 任务流程的基本模型
///
/// [D]为关联的接口结果数据类型，[T]为接口响应包装类型[HttpData]
abstract class Api<D, T extends HttpData<D>> {
  /// 日志标签
  String _tag;

  /// 日志标签
  String get tag => _tag ?? _createTag();

  /// 创建日志标签
  String _createTag() {
    _tag = '$runtimeType@${hashCode.toRadixString(16)}';
    return _tag;
  }

  /// 任务取消状态标签
  bool _cancelMark = false;

  /// 取消请求工具
  final CancelToken _cancelToken = CancelToken();

  /// 启动的任务计数器
  int _counter = 0;

  /// 队尾的任务
  Future<T> _lastFuture;

  /// 启动任务
  ///
  /// * [params]为任务参数列表，[retry]为重试次数，[onProgress]为进度监听器，目前仅上传和下载任务有效。
  /// * 同一个[Api]可以多次启动任务，多次启动的任务会顺序执行。
  Future<T> start({
    dynamic params,
    int retry = 0,
    OnProgress onSendProgress,
    OnProgress onReceiveProgress,
  }) async {
    final counter = ++_counter;

    httpLog(tag, "No.$counter api 开始");

    final completer = Completer<T>();
    final lastFuture = _lastFuture;
    _lastFuture = completer.future;

    if (counter > 1) {
      await lastFuture;
    } else {
      _cancelMark = false;
    }

    // 创建数据模型
    final data = onCreateApiData();

    data._params = params == null ? Map() : params;

    // 是否继续执行
    var next = true;

    if (!_cancelMark) {
      // 执行前导任务
      next = await _onStart(data);
    }

    if (!_cancelMark && next) {
      // 构建http请求选项
      data._options = await _onCreateOptions(params, retry, onSendProgress, onReceiveProgress);
      // 执行核心任务
      await _onDo(data);
    }

    if (!_cancelMark) {
      // 执行后继任务
      await onStop(data);
    }

    if (!_cancelMark) {
      // 最后执行
      httpLog(tag, "api完成调用");
      try {
        final finish = onFinish(data);
        if (finish is Future<void>) {
          await finish;
        }
      } catch (e) {
        httpLog(tag, 'api完成调用失败', e);
      }
    }

    if (_cancelMark) {
      // 任务被取消
      httpLog(tag, "api取消调用");
      try {
        final canceled = onCanceled(data);
        if (canceled is Future<void>) {
          await canceled;
        }
      } catch (e) {
        httpLog(tag, 'api取消调用失败', e);
      }
    }

    httpLog(tag, "No.$counter 结束");

    data._cancel = _cancelMark;

    if (--_counter == 0) {
      _lastFuture = null;
    }

    completer.complete(data);

    return completer.future;
  }

  /// 创建数据模型对象的实例
  @protected
  T onCreateApiData();

  /// 任务启动前置方法
  ///
  /// [data]为任务将要返回的数据模型，返回true表示继续执行
  @protected
  @mustCallSuper
  Future<bool> _onStart(T data) async {
    // 校验参数
    final check = onCheckParams(data.params);
    final checkResult = (check is Future<bool>) ? await check : check;
    if (!checkResult) {
      // 数据异常
      httpLog(tag, "数据异常");
      // 执行异常回调
      final message = onParamsError(data.params);
      if (message is Future<String>) {
        data._message = await message;
      } else {
        data._message = message;
      }
      return false;
    }

    return true;
  }

  /// 构建请求选项参数
  Future<FutureOr<Options>> _onCreateOptions(
    dynamic params,
    int retry,
    OnProgress onSendProgress,
    OnProgress onReceiveProgress,
  ) async {
    httpLog(tag, "构建请求选项参数");

    dynamic data;
    if (paramType() == ParamType.map) {
      data = Map<String, dynamic>();
      params = Map<String, dynamic>.from(params);
      final preFillParams = onPreFillParams(data, params);
      if (preFillParams is Future<void>) {
        await preFillParams;
      }
      final fillParams = onFillParams(data, params);
      if (fillParams is Future<void>) {
        await fillParams;
      }
    } else {
      data = [];
      data.addAll(params);
    }

    final options = Options()
      ..retry = retry
      ..onSendProgress = onSendProgress
      ..onReceiveProgress = onReceiveProgress
      ..method = httpMethod
      ..url = onUrl(params);

    final headers = onHeaders(params);
    if (headers is Future<Map<String, dynamic>>) {
      options.headers = await headers;
    } else {
      options.headers = headers;
    }

    final postFillParams = onPostFillParams(data, params);
    if (postFillParams is Future) {
      options.params = await postFillParams ?? data;
    } else {
      options.params = postFillParams ?? data;
    }

    final configOptions = onConfigOptions(options, params);
    if (configOptions is Future<void>) {
      await configOptions;
    }

    options.cancelToken = _cancelToken;

    return options;
  }

  /// 核心任务执行
  ///
  /// 此处为真正启动http请求的方法
  Future<void> _onDo(T data) async {
    if (_cancelMark) {
      return;
    }

    final willRequest = onWillRequest(data);
    if (willRequest is Future<void>) {
      await willRequest;
    }

    if (_cancelMark) {
      return;
    }

    // 创建网络请求工具
    JvtdHttpUtils communication;
    final interceptCreateCommunication = onInterceptCreateHttpUtils(data);
    if (interceptCreateCommunication is Future<JvtdHttpUtils>) {
      communication = await interceptCreateCommunication ?? httpUtils;
    } else {
      communication = interceptCreateCommunication ?? httpUtils;
    }

    if (_cancelMark) {
      return;
    }

    data._response = await communication.request(tag, data.options);
    if (_cancelMark) {
      return;
    }

    _onParseResponse(data);
  }

  /// 任务完成后置方法
  @mustCallSuper
  @protected
  FutureOr<void> onStop(T data) {
    httpLog(tag, "api调用结束");
    if (!_cancelMark) {
      // 不同结果的后继执行
      if (data.success) {
        httpLog(tag, "api调用成功了");
        onSuccess(data);
      } else {
        httpLog(tag, "api调用失败了");
        onFailed(data);
      }
    }
  }

  /// 最后执行的一个方法
  ///
  /// 即设置请求结果和返回数据之后，并且在回调任务发送后才执行此函数
  @protected
  FutureOr<void> onFinish(T data) {}

  /// 任务被取消时调用
  @protected
  FutureOr<void> onCanceled(T data) {}

  /// 参数合法性检测
  ///
  /// * 用于检测传入参数[params]是否合法，需要子类重写检测规则。
  /// * 检测成功任务才会被正常执行，如果检测失败则[onParamsError]会被调用，
  /// 且后续网络请求任务不再执行，任务任然可以正常返回并执行生命周期[onFailed]，[onFinish]。
  /// * 参数合法返回true，非法返回false。
  @protected
  FutureOr<bool> onCheckParams(dynamic params) => true;

  /// 参数检测不合法时调用
  ///
  /// * [onCheckParams]返回false时被调用，且后续网络请求任务不再执行，
  /// 但是任务任然可以正常返回并执行生命周期[onFailed]，[onFinish]。
  /// * 返回错误消息内容，将会设置给[HttpData.message]
  @protected
  FutureOr<String> onParamsError(dynamic params) => null;

  /// 填充请求所需的前置参数
  ///
  /// * 适合填充项目中所有接口必须传递的固定参数（通过项目中实现的定制[Api]基类完成）
  /// * [data]为请求参数集（http请求要发送的参数），[params]为任务传入的参数列表
  @protected
  FutureOr<void> onPreFillParams(Map<String, dynamic> data, Map<String, dynamic> params) {}

  /// 填充请求所需的参数
  ///
  /// [data]为请求参数集（http请求要发送的参数），[params]为任务传入的参数列表
  @protected
  FutureOr<void> onFillParams(Map<String, dynamic> data, Map<String, dynamic> params);

  /// 填充请求所需的后置参数
  ///
  /// * 适合对参数进行签名（通过项目中实现的定制[Api]基类完成）
  /// * [data]为请求参数集（http请求要发送的参数），[params]为任务传入的参数列表
  /// * 如果需要使用其他数据类型作为请求参数，请返回新的数据集合对象，支持[Map]，[List]，[String]([ResponseType.plain])
  /// 不返回参数或返回null则继续使用[data]作为请求参数
  @protected
  FutureOr<dynamic> onPostFillParams(Map<String, dynamic> data, Map<String, dynamic> params) => null;

  /// 创建并填充请求头
  ///
  /// [params]为任务传入的参数
  @protected
  FutureOr<Map<String, dynamic>> onHeaders(dynamic params) => null;

  /// 拦截创建网络请求工具
  ///
  /// * 用于创建完全自定义实现的网络请求工具。
  @protected
  FutureOr<JvtdHttpUtils> onInterceptCreateHttpUtils(T data) => null;

  /// 即将执行网络请求前的回调
  ///
  /// 此处可以用于做数据统计，特殊变量创建等，如果调用[cancel]则会拦截接下来的网络请求
  @protected
  FutureOr<void> onWillRequest(T data) {}

  /// 自定义配置http请求选择项
  ///
  /// * [options]为请求将要使用的配置选项，[params]为任务参数
  /// 修改[options]的属性以定制http行为。
  /// * [options]包含[httpMethod]返回的请求方法，
  /// [onFillParams]填充的参数，
  /// [onUrl]返回的请求地址，
  /// [start]中传传递的[retry]和[onProgress]，
  /// [onHeaders]中创建的请求头，
  /// 以上属性都可以在这里被覆盖可以被覆盖。
  @protected
  FutureOr<void> onConfigOptions(Options options, dynamic params) {}

  /// 网络请求方法
  @protected
  HttpMethod get httpMethod => HttpMethod.get;

  /// 网络请求完整地址
  ///
  /// [params]任务传入的参数
  @protected
  String onUrl(dynamic params);

  /// 解析响应数据
  FutureOr<void> _onParseResponse(T data) async {
    httpLog(tag, "开始解析服务器返回数据");
    data._httpCode = data.response.statusCode;

    if (!isHttpSuccess()) {
      data.response.success = data._httpCode != 0; //用于睿丁异常抛出
    }

    if (data.response.success) {
      // 解析数据
      //noinspection unchecked
      if (await _onParse(data.response.data, data)) {
        // 解析成功
        httpLog(tag, "api接口调用完成，进入回调...");
        // 解析成功回调
        final parseSuccess = onParseSuccess(data);
        if (parseSuccess is Future<void>) {
          await parseSuccess;
        }
        if (data.success) {
          httpLog(tag, "接口调用正常");
        } else {
          httpLog(tag, "接口调用异常");
        }
      } else {
        // 解析失败
        httpLog(tag, "数据解析失败");
        // 解析失败回调
        data._success = false;
        data.response.errorType = HttpErrorType.parse;
        final parseFailed = onParseFailed(data);
        if (parseFailed is Future<String>) {
          data._message = await parseFailed;
        } else {
          data._message = parseFailed;
        }
      }
    } else if (data.response.errorType == HttpErrorType.response) {
      // 网络请求失败
      httpLog(tag, "网络请求失败");

      // 网络请求失败回调
      // 网络请求失败回调
      final networkRequestFailed = onNetworkRequestFailed(data);
      if (networkRequestFailed is Future<String>) {
        data._message = await networkRequestFailed;
      } else {
        data._message = networkRequestFailed;
      }
    } else {
      // 网络连接失败
      httpLog(tag, "网络连接失败");

      // 网络错误回调
      final networkError = onNetworkError(data);
      if (networkError is Future<String>) {
        data._message = await networkError;
      } else {
        data._message = networkError;
      }
    }
  }

  /// 解析响应体，返回解析结果
  FutureOr<bool> _onParse(responseBody, T data) async {
    httpLog(tag, "解析进行中...");
    final checkResponse = onCheckResponse(data);
    final checkResponseResult = (checkResponse is Future<bool>) ? await checkResponse : checkResponse;
    if (!checkResponseResult) {
      // 通信异常
      httpLog(tag, "校验返回实体异常");
      return false;
    }

    try {
      // 提取服务状态码
      data._statusCode = onResponseCode(responseBody);
      // 提取服务执行结果
      final responseResult = onResponseResult(responseBody);
      if (responseResult is Future<bool>) {
        data._success = await responseResult;
      } else {
        data._success = responseResult;
      }
      httpLog(tag, "分析接口请求结果： " + (data.success ? "成功" : "失败"));

      if (data.success) {
        // 服务请求成功回调
        httpLog(tag, "服务器返回成功，进入成功数据解析...");
        final responseSuccess = onResponseSuccess(responseBody, data);
        if (responseSuccess is Future<D>) {
          data._result = await responseSuccess;
        } else {
          data._result = responseSuccess;
        }

        // 提取服务返回的消息
        final requestSuccessMessage = onRequestSuccessMessage(responseBody, data);
        if (requestSuccessMessage is Future<String>) {
          data._message = await requestSuccessMessage;
        } else {
          data._message = requestSuccessMessage;
        }
      } else {
        // 服务请求失败回调
        httpLog(tag, "服务器返回失败，进入失败数据解析");
        final requestFailed = onRequestFailed(responseBody, data);
        if (requestFailed is Future<D>) {
          data._result = await requestFailed;
        } else {
          data._result = requestFailed;
        }

        // 提取服务返回的消息
        final requestFailedMessage = onRequestFailedMessage(responseBody, data);
        if (requestFailedMessage is Future<String>) {
          data._message = await requestFailedMessage;
        } else {
          data._message = requestFailedMessage;
        }
        data.response.errorType = HttpErrorType.task;
      }
      httpLog(tag, "服务器返回的信息:", data.message);
      return true;
    } catch (e, s) {
      data.response.errorType = HttpErrorType.task;
      final catchMessage = onCatchMessage(data, e);
      if (catchMessage is Future<String>) {
        data._message = await catchMessage;
      } else {
        data._message = await catchMessage;
      }
      httpLog(tag, "解析异常：", e);
      httpLog(tag, "错误堆栈：", s);
      return false;
    } finally {
      httpLog(tag, "解析结束");
    }
  }

  /// 服务器响应数据解析成功后调用
  ///
  /// 即在[_onParse]返回true时调用
  @protected
  FutureOr<void> onParseSuccess(T data) {}

  /// 网络请求成功，服务器响应数据解析失败后调用
  ///
  /// 即在[_onParse]返回false时调用，
  /// 返回响应数据解析失败时的消息，即[HttpData.message]字段
  @protected
  FutureOr<String> onParseFailed(T data) => null;

  /// 网络连接建立成功，但是请求失败时调用
  ///
  /// 即响应码不是200，返回网络请求失败时的消息，即[HttpData.message]字段
  @protected
  FutureOr<String> onNetworkRequestFailed(T data) => null;

  /// 网络连接建立失败时调用，即网络不可用
  ///
  /// 返回设置网络无效时的消息，即[HttpData.message]字段
  @protected
  FutureOr<String> onNetworkError(T data) => null;

  /// 检测响应结果是否符合预期（数据类型或是否包含特定字段），也可以做验签
  ///
  /// * 通常[response]类型是[onConfigOptions]中设置的[Options.responseType]决定的。
  /// * 在一般请求中默认为[ResponseType.json]则[response]为[Map]类型的json数据。
  /// * 下载请求中默认为[ResponseType.stream]则[response]为[Stream]。
  /// * 如果设置为[ResponseType.plain]则[response]为字符串。
  @protected
  FutureOr<bool> onCheckResponse(T data) => true;

  /// 提取服务执行结果
  ///
  /// * http响应成功，从接口响应的数据中提取本次业务请求真正的成功或失败结果。
  /// * 通常[response]类型是[onConfigOptions]中设置的[Options.responseType]决定的。
  /// * 在一般请求中默认为[ResponseType.json]则[response]为[Map]类型的json数据。
  /// * 下载请求中默认为[ResponseType.stream]则[response]为[Stream]。
  /// * 如果设置为[ResponseType.plain]则[response]为字符串。
  @protected
  FutureOr<bool> onResponseResult(response);

  /// 提取服务之星返回的正确状态码
  @protected
  FutureOr<dynamic> onResponseCode(response);

  /// 提取服务执行成功时返回的真正有用结果数据
  ///
  /// * 在服务请求成功后调用，即[onResponseResult]返回值为true时被调用，
  /// 用于生成请求成功后的任务返回真正结果数据对象[D]。
  /// * 通常[response]类型是[onConfigOptions]中设置的[Options.responseType]决定的。
  /// * 在一般请求中默认为[ResponseType.json]则[response]为[Map]类型的json数据。
  /// * 下载请求中默认为[ResponseType.stream]则[response]为[Stream]。
  /// * 如果设置为[ResponseType.plain]则[response]为字符串。
  @protected
  FutureOr<D> onResponseSuccess(response, T data);

  /// 提取或设置服务返回的成功结果消息
  ///
  /// * 在服务请求成功后调用，即[onResponseResult]返回值为true时被调用。
  /// * 通常[response]类型是[onConfigOptions]中设置的[Options.responseType]决定的。
  /// * 在一般请求中默认为[ResponseType.json]则[response]为[Map]类型的json数据。
  /// * 下载请求中默认为[ResponseType.stream]则[response]为[Stream]。
  /// * 如果设置为[ResponseType.plain]则[response]为字符串。
  @protected
  FutureOr<String> onRequestSuccessMessage(response, T data) => null;

  /// 提取或设置服务执行失败时的返回结果数据
  ///
  /// * 在服务请求失败后调用，即[onResponseResult]返回值为false时被调用，
  /// 用于生成请求失败后的任务返回真正结果数据对象[D]，可能是一个默认值。
  /// * 通常[response]类型是[onConfigOptions]中设置的[Options.responseType]决定的。
  /// * 在一般请求中默认为[ResponseType.json]则[response]为[Map]类型的json数据。
  /// * 下载请求中默认为[ResponseType.stream]则[response]为[Stream]。
  /// * 如果设置为[ResponseType.plain]则[response]为字符串。
  @protected
  FutureOr<D> onRequestFailed(response, T data) => null;

  /// 提取或设置服务返回的失败结果消息
  ///
  /// * 在服务请求失败后调用，即[onResponseResult]返回值为false时被调用。
  /// * 通常[response]类型是[onConfigOptions]中设置的[Options.responseType]决定的。
  /// * 在一般请求中默认为[ResponseType.json]则[response]为[Map]类型的json数据。
  /// * 下载请求中默认为[ResponseType.stream]则[response]为[Stream]。
  /// * 如果设置为[ResponseType.plain]则[response]为字符串。
  FutureOr<String> onRequestFailedMessage(response, T data) => null;

  /// 本地处理catch问题
  FutureOr<String> onCatchMessage(T data, dynamic e) => e.toString();

  /// 本次任务执行成功后执行
  ///
  /// 即设置请求结果和返回数据之后，并且在回调接口之前执行此函数，
  /// 该方法在[onFinish]之前被调用
  @protected
  FutureOr<void> onSuccess(T data) {}

  /// 本次任务执行失败后执行
  ///
  /// 即设置请求结果和返回数据之后，并且在回调接口之前执行此函数，
  /// 该方法在[onFinish]之前被调用
  @protected
  FutureOr<void> onFailed(T data) {}

  /// 传入参数类型
  ParamType paramType() {
    return ParamType.map;
  }

  // 是否基于http code
  bool isHttpSuccess() {
    return true;
  }

  /// 取消正在进行的任务
  ///
  /// 如果本任务被多次启动排队执行，则会一次性取消所有排队任务和正在执行的任务
  void cancel() {
    httpLog(tag, "取消本次api调用");
    if (_cancelMark) {
      httpLog(tag, "此api调用已取消");
      return;
    }
    if (_counter <= 0) {
      httpLog(tag, "此api未开始调用");
      return;
    }
    _cancelMark = true;
    _cancelToken.cancel();
  }
}
