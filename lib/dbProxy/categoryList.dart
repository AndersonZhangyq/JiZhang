import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/widget/modifyTransaction.dart';

class CategoryList extends ChangeNotifier {
  final Map<num, CategoryItem> _itemsMap = {};

  UnmodifiableListView<CategoryItem> get items {
    var ret = _itemsMap.values.toList();
    ret.sort();
    return UnmodifiableListView(ret);
  }

  UnmodifiableMapView<num, CategoryItem> get itemsMap =>
      UnmodifiableMapView(_itemsMap);

  void addAll(List<CategoryItem> items) {
    _itemsMap.addAll({for (var item in items) item.id: item});
    notifyListeners();
  }

  void modify(CategoryItem item) {
    _itemsMap[item.id] = item;
    notifyListeners();
  }

  void removeAll() {
    _itemsMap.clear();
    notifyListeners();
  }

  void updateAll(List<CategoryItem> items) {
    for (var item in items) {
      _itemsMap[item.id] = item;
    }
    notifyListeners();
  }

  void remove(CategoryItem item) {
    _itemsMap.remove(item.id);
    notifyListeners();
  }
}
