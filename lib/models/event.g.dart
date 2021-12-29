// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) {
  var tmp = Event()
    ..id = json['id'] as num
    ..name = json['name'] as String;
  if (json['createdAt'] != null) {
    tmp.createdAt = DateTime.parse(json['createdAt'] as String);
  }
  return tmp;
}

Map<String, dynamic> _$EventToJson(Event instance) {
  Map<String, dynamic> ret = {
    'name': instance.name,
  };
  if (-1 != instance.id) {
    ret['id'] = instance.id;
  }
  return ret;
}
