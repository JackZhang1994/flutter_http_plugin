import 'package:jvtd_http/jvtd_http.dart';
import 'base_api.dart';
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