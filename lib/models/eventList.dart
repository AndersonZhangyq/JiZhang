import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/models/index.dart';

class EventList extends ChangeNotifier {
  final List<Event> _items = [];

  UnmodifiableListView<Event> get items => UnmodifiableListView(_items);

  UnmodifiableMapView<num, Event> get itemsMap =>
      UnmodifiableMapView({for (var item in _items) item.id: item});

  void addAll(List<Event> items) {
    _items.addAll(items);
    notifyListeners();
  }

  void add(Event item, {int position = -1}) {
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
