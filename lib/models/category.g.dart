// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category()
  ..id = json['id'] as num
  ..name = json['name'] as String
  ..type = json['type'] as String
  ..icon = json['icon'] as String
  ..color = json['color'] as String
  ..createdAt = DateTime.parse(json['createdAt'] as String);

Map<String, dynamic> _$CategoryToJson(Category instance) {
  Map<String, dynamic> ret = {
    'name': instance.name,
    'type': instance.type,
    'icon': instance.icon,
    'color': instance.color,
  };
  if (-1 != instance.id) {
    ret['id'] = instance.id;
  }
  return ret;
}
