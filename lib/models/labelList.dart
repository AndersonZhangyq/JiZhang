import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/models/label.dart';

class LabelList extends ChangeNotifier {
  final Map<num, Label> _itemsMap = {};

  UnmodifiableListView<Label> get items {
    var ret = _itemsMap.values.toList();
    ret.sort((a, b) => a.id.compareTo(b.id));
    return UnmodifiableListView(ret);
  }

  UnmodifiableMapView<num, Label> get itemsMap =>
      UnmodifiableMapView(_itemsMap);

  void addAll(List<Label> items) {
    _itemsMap.addAll({for (var item in items) item.id: item});
    notifyListeners();
  }

  void modify(Label item) {
    _itemsMap[item.id] = item;
    notifyListeners();
  }

  void removeAll() {
    _itemsMap.clear();
    notifyListeners();
  }
}
