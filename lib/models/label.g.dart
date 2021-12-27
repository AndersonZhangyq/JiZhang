// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'label.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Label _$LabelFromJson(Map<String, dynamic> json) => Label()
  ..id = json['id'] as num
  ..name = json['name'] as String;

Map<String, dynamic> _$LabelToJson(Label instance) {
  Map<String, dynamic> ret = {
    'name': instance.name,
  };
  if (-1 != instance.id) {
    ret['id'] = instance.id;
  }
  return ret;
}
