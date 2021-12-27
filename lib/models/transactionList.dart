import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/models/index.dart';

class TransactionList extends ChangeNotifier {
  final List<Transaction> _items = [];

  UnmodifiableListView<Transaction> get items => UnmodifiableListView(_items);

  UnmodifiableMapView<num, Transaction> get itemsMap =>
      UnmodifiableMapView({for (var item in _items) item.id: item});

  void addAll(List<Transaction> items) {
    _items.addAll(items);
    notifyListeners();
  }

  void add(Transaction item, {int position = -1}) {
    if (position == -1) {
      _items.add(item);
      _items.sort();
    } else {
      _items.insert(position, item);
    }
    notifyListeners();
  }

  void removeAll() {
    _items.clear();
    notifyListeners();
  }

  void remove(Transaction transaction) {
    _items.remove(transaction);
    notifyListeners();
  }
}
