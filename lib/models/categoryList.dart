import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/widget/addTransaction.dart';

class CategoryList extends ChangeNotifier {
  final List<CategoryItem> _items = [];

  UnmodifiableListView<CategoryItem> get items => UnmodifiableListView(_items);

  UnmodifiableMapView<num, CategoryItem> get itemsMap =>
      UnmodifiableMapView({for (var item in _items) item.id: item});

  void addAll(List<CategoryItem> items) {
    _items.addAll(items);
    notifyListeners();
  }

  void add(CategoryItem item, {int position = -1}) {
    if (position == -1) {
      _items.add(item);
      _items.sort((a, b) => a.id.compareTo(b.id));
    } else {
      _items.insert(position, item);
    }
    notifyListeners();
  }

  void removeAll() {
    _items.clear();
    notifyListeners();
  }
}
