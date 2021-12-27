import 'package:ji_zhang/common/datetime_extension.dart';
import 'package:json_annotation/json_annotation.dart';
part 'transaction.g.dart';

@JsonSerializable()
class Transaction implements Comparable {
  Transaction();

  num id = -1;
  late num money;
  DateTime date = DateTime.now().getDateOnly();
  late int categoryId;
  List<int>? labelIds;
  String? recurrence;
  String? comment;
  late DateTime createdAt;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  @override
  int compareTo(other) {
    if (other is Transaction) {
      int dateCompare = date.compareTo(other.date);
      if (dateCompare != 0) {
        return dateCompare;
      } else {
        return id.compareTo(other.id);
      }
    }
    return 0;
  }
}
