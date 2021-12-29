// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) {
  var tmp = Category()
    ..id = json['id'] as num
    ..name = json['name'] as String
    ..type = json['type'] as String
    ..icon = json['icon'] as String
    ..color = json['color'] as String
    ..predefined = json['predefined'] is int
        ? json['predefined']
        : (json['predefined'] ? 1 : 0)
    ..index = json['index'] as int;
  if (json['createdAt'] != null) {
    tmp.createdAt = DateTime.parse(json['createdAt'] as String);
  }
  return tmp;
}

Map<String, dynamic> _$CategoryToJson(Category instance) {
  Map<String, dynamic> ret = {
    'name': instance.name,
    'type': instance.type,
    'icon': instance.icon,
    'color': instance.color,
    'index': instance.index,
    'predefined': instance.predefined
  };
  if (-1 != instance.id) {
    ret['id'] = instance.id;
  }
  return ret;
}
