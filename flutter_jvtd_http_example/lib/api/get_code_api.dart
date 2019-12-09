import 'package:jvtd_http/jvtd_http.dart';
import 'base_api.dart';
import '../bean/get_code_res_bean.dart';
export '../bean/get_code_res_bean.dart';
export '../bean/get_code_req_bean.dart';

class GetCodeApi extends BaseApi<String>{
  @override
  String apiMethod(dynamic params) {
    return 'app/login';
  }

  @override
  String onExtractResult(resultData, HttpData<String> data) {
    return resultData['token'];
  }
}