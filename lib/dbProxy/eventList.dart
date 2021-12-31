import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/models/index.dart';

class EventList extends ChangeNotifier {
  final Map<num, Event> _itemsMap = {};

  UnmodifiableListView<Event> get items {
    var ret = _itemsMap.values.toList();
    ret.sort((a, b) => a.id.compareTo(b.id));
    return UnmodifiableListView(ret);
  }

  UnmodifiableMapView<num, Event> get itemsMap =>
      UnmodifiableMapView(_itemsMap);

  void addAll(List<Event> items) {
    _itemsMap.addAll({for (var item in items) item.id: item});
    notifyListeners();
  }

  void add(Event item) {
    _itemsMap[item.id] = item;
    notifyListeners();
  }

  void removeAll() {
    _itemsMap.clear();
    notifyListeners();
  }
}
