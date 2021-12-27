import 'package:json_annotation/json_annotation.dart';

part 'label.g.dart';

@JsonSerializable()
class Label {
  Label();

  num id = -1;
  late String name;
  late DateTime createdAt;

  factory Label.fromJson(Map<String, dynamic> json) => _$LabelFromJson(json);
  Map<String, dynamic> toJson() => _$LabelToJson(this);
}
