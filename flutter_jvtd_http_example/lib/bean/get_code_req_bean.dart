part 'get_code_req_bean.g.dart';

class GetCodeReqBean{
  String phone;


  GetCodeReqBean({this.phone});

  factory GetCodeReqBean.fromJson(Map<String, dynamic> json) =>
      _$GetCodeReqBeanFromJson(json);

  Map<String, dynamic> toJson() => _$GetCodeReqBeanToJson(this);
}

class LoginReqBean {
  factory LoginReqBean.fromJson(Map<String, dynamic> json) =>
      _$LoginReqBeanFromJson(json);

  Map<String, dynamic> toJson() => _$LoginReqBeanToJson(this);

  String mobile; //账户
  String password; //密码
  String deviceName; //设备名称
  String userType; //用户类型
  String uuid; //设备唯一标识

  LoginReqBean({
    this.mobile,
    this.password,
    this.deviceName,
    this.userType,
    this.uuid,
  });
}