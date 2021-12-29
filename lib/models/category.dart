import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ji_zhang/widget/modifyTransaction.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  Category();

  num id = -1;
  late String name;
  late String type;
  late String icon;
  late String color;
  late int index;
  late int predefined;
  late DateTime createdAt;

  factory Category.fromCategoryItem(CategoryItem item) {
    IconData icon = item.icon;
    return Category()
      ..id = item.id
      ..name = item.name
      ..type = item.type
      ..icon = jsonEncode({
        "codePoint": icon.codePoint,
        "fontFamily": icon.fontFamily,
        "fontPackage": icon.fontPackage
      })
      ..color = item.color.value.toString()
      ..predefined = item.predefined
      ..index = item.index;
  }

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
