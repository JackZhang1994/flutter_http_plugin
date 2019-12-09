import 'package:jvtd_http/jvtd_http.dart';
import 'base_paging_api.dart';
import '../bean/line_bean.dart';
export '../bean/line_bean.dart';
export '../bean/get_line_list_bean.dart';

class GetLineListApi extends BasePagingApi<List<LineBean>> {
  @override
  String apiMethod(dynamic params) {
    return 'route/queryRouteList';
  }

  @override
  List<LineBean> onExtractResult(resultData, HttpData<List<LineBean>> data) {
    List resultList = resultData;
    return resultList.map((item) {
      return LineBean.fromJson(item);
    }).toList();
  }
}
