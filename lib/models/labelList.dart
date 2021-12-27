import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/models/label.dart';

class LabelList extends ChangeNotifier {
  final List<Label> _items = [];

  UnmodifiableListView<Label> get items => UnmodifiableListView(_items);

  UnmodifiableMapView<num, Label> get itemsMap =>
      UnmodifiableMapView({for (var item in _items) item.id: item});

  void addAll(List<Label> items) {
    _items.addAll(items);
    notifyListeners();
  }

  void add(Label item, {int position = -1}) {
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
