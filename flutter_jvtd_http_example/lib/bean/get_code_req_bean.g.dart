// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_code_req_bean.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetCodeReqBean _$GetCodeReqBeanFromJson(Map<String, dynamic> json) {
  return GetCodeReqBean(phone: json['phone'] as String);
}

Map<String, dynamic> _$GetCodeReqBeanToJson(GetCodeReqBean instance) =>
    <String, dynamic>{'phone': instance.phone};


LoginReqBean _$LoginReqBeanFromJson(Map<String, dynamic> json) {
  return LoginReqBean(
    mobile: json['mobile'] as String,
    password: json['password'] as String,
    deviceName: json['deviceName'] as String,
    userType: json['userType'] as String,
    uuid: json['uuid'] as String,
  );
}

Map<String, dynamic> _$LoginReqBeanToJson(LoginReqBean instance) =>
    <String, dynamic>{
      'mobile': instance.mobile,
      'password': instance.password,
      'deviceName': instance.deviceName,
      'userType': instance.userType,
      'uuid': instance.uuid,
    };
