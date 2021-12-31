import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/models/tag.dart';

class TagList extends ChangeNotifier {
  final Map<num, Tag> _itemsMap = {};

  UnmodifiableListView<Tag> get items {
    var ret = _itemsMap.values.toList();
    ret.sort((a, b) => a.id.compareTo(b.id));
    return UnmodifiableListView(ret);
  }

  UnmodifiableMapView<num, Tag> get itemsMap => UnmodifiableMapView(_itemsMap);

  void addAll(List<Tag> items) {
    _itemsMap.addAll({for (var item in items) item.id: item});
    notifyListeners();
  }

  void modify(Tag item) {
    _itemsMap[item.id] = item;
    notifyListeners();
  }

  void removeAll() {
    _itemsMap.clear();
    notifyListeners();
  }
}
