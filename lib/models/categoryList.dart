import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/widget/modifyTransaction.dart';

class CategoryList extends ChangeNotifier {
  final Map<num, CategoryItem> _itemsMap = {};

  UnmodifiableListView<CategoryItem> get items {
    var ret = _itemsMap.values.toList();
    ret.sort((a, b) => a.id.compareTo(b.id));
    return UnmodifiableListView(ret);
  }

  UnmodifiableMapView<num, CategoryItem> get itemsMap =>
      UnmodifiableMapView(_itemsMap);

  void addAll(List<CategoryItem> items) {
    _itemsMap.addAll({for (var item in items) item.id: item});
    notifyListeners();
  }

  void add(CategoryItem item) {
    _itemsMap[item.id] = item;
    notifyListeners();
  }

  void removeAll() {
    _itemsMap.clear();
    notifyListeners();
  }
}
