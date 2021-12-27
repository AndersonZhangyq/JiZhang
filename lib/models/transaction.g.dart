// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction()
  ..id = json['id'] as num
  ..money = json['money'] as num
  ..date = DateTime.parse(json['date'] as String)
  ..categoryId = json['categoryId']
  ..labelIds = json['labelIds'] as List<int>?
  ..recurrence = json['recurrence'] as String?
  ..comment = json['comment'] as String?
  ..createdAt = json['createdAt'] != null
      ? DateTime.parse(json['createdAt'] as String)
      : DateTime.now();

Map<String, dynamic> _$TransactionToJson(Transaction instance) {
  Map<String, dynamic> ret = {
    'money': instance.money,
    'date': instance.date.toIso8601String(),
    'categoryId': instance.categoryId,
    'labelIds': instance.labelIds,
    'recurrence': instance.recurrence,
    'comment': instance.comment,
  };
  if (-1 != instance.id) {
    ret['id'] = instance.id;
  }
  return ret;
}
