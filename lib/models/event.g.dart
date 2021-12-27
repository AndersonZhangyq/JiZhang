// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event()
  ..id = json['id'] as num
  ..name = json['name'] as String;

Map<String, dynamic> _$EventToJson(Event instance) {
  Map<String, dynamic> ret = {
    'name': instance.name,
  };
  if (-1 != instance.id) {
    ret['id'] = instance.id;
  }
  return ret;
}
