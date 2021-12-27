import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/models/index.dart';

class TransactionList extends ChangeNotifier {
  final Map<num, Transaction> _itemsMap = {};

  UnmodifiableListView<Transaction> get items {
    var ret = _itemsMap.values.toList();
    ret.sort();
    return UnmodifiableListView(ret);
  }

  UnmodifiableMapView<num, Transaction> get itemsMap =>
      UnmodifiableMapView(_itemsMap);

  void addAll(List<Transaction> items) {
    _itemsMap.addAll({for (var item in items) item.id: item});
    notifyListeners();
  }

  void modify(Transaction item) {
    _itemsMap[item.id] = item;
    notifyListeners();
  }

  void removeAll() {
    _itemsMap.clear();
    notifyListeners();
  }

  void remove(Transaction transaction) {
    _itemsMap.remove(transaction.id);
    notifyListeners();
  }
}
