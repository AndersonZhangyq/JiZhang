import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/models/index.dart';

class TransactionList extends ChangeNotifier {
  final Map<num, Transaction> _itemsMap = {};
  late int year, month;
  late DateTime startDate, endDate;

  TransactionList({int? year, int? month}) {
    this.year = year ?? DateTime.now().year;
    this.month = month ?? DateTime.now().month;
    startDate = DateTime(this.year, month = this.month);
    endDate = DateTime(this.year, month = this.month + 1)
        .subtract(const Duration(days: 1));
  }

  UnmodifiableListView<Transaction> get items {
    var ret = _itemsMap.values.toList();
    ret.sort();
    return UnmodifiableListView(ret);
  }

  UnmodifiableMapView<num, Transaction> get itemsMap =>
      UnmodifiableMapView(_itemsMap);

  void setYearMonth(int year, int month) {
    this.year = year;
    this.month = month;
    startDate = DateTime(this.year, month = this.month);
    endDate = DateTime(this.year, month = this.month + 1)
        .subtract(const Duration(days: 1));
    notifyListeners();
  }

  bool _isBounded(Transaction element) {
    return element.date.compareTo(startDate) >= 0 &&
        element.date.compareTo(endDate) <= 0;
  }

  void addAll(List<Transaction> items) {
    items = items.where((element) => _isBounded(element)).toList();
    _itemsMap.addAll({for (var item in items) item.id: item});
    notifyListeners();
  }

  void modify(Transaction item) {
    if (_isBounded(item)) {
      _itemsMap[item.id] = item;
      notifyListeners();
    } else {
      _itemsMap.remove(item.id);
    }
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
