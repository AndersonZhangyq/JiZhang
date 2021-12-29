// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tag _$TagFromJson(Map<String, dynamic> json) => Tag()
  ..id = json['id'] as num
  ..name = json['name'] as String
  ..createdAt = DateTime.parse(json['createdAt'] as String);

Map<String, dynamic> _$TagToJson(Tag instance) {
  Map<String, dynamic> ret = {
    'name': instance.name,
  };
  if (-1 != instance.id) {
    ret['id'] = instance.id;
  }
  return ret;
}
