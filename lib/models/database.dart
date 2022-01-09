import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' as ui;
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:ji_zhang/common/predefinedCategory.dart';
import 'package:ji_zhang/common/predefinedRecurrence.dart';
import 'package:ji_zhang/widget/navigationPage/budget.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get type => text()();

  TextColumn get icon => text()();

  TextColumn get color => text()();

  IntColumn get pos => integer()();

  IntColumn get predefined => integer()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get amount => real()();

  DateTimeColumn get date => dateTime()();

  IntColumn get categoryId => integer()();

  TextColumn get recurrence => text().nullable()();

  TextColumn get tagIds =>
      text().map(const IntegerListConverter()).nullable()();

  TextColumn get comment => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  RealColumn get amount => real()();

  TextColumn get categoryIds => text().map(const IntegerListConverter())();

  IntColumn get recurrence => intEnum<RECURRENCE_TYPE>()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

int compareTransaction(Transaction a, Transaction b) {
  int dateCompare = a.date.compareTo(b.date);
  if (dateCompare != 0) {
    return dateCompare;
  } else {
    return -a.id.compareTo(b.id);
  }
}

class MyValueSerializer extends ValueSerializer {
  const MyValueSerializer();

  @override
  T fromJson<T>(dynamic json) {
    if (json == null) {
      return null as T;
    }

    final _typeList = <T>[];

    if (_typeList is List<DateTime?>) {
      return DateTime.fromMillisecondsSinceEpoch(json as int) as T;
    }

    if (_typeList is List<double?> && json is int) {
      return json.toDouble() as T;
    }

    // blobs are encoded as a regular json array, so we manually convert that to
    // a Uint8List
    if (_typeList is List<Uint8List?> && json is! Uint8List) {
      final asList = (json as List).cast<int>();
      return Uint8List.fromList(asList) as T;
    }

    if (_typeList is List<List<int>?> && json is! List<int>) {
      final asList = (json as List).cast<int>();
      return asList as T;
    }

    if (T == RECURRENCE_TYPE && json is int) {
      return RECURRENCE_TYPE.values[json] as T;
    }

    return json as T;
  }

  @override
  dynamic toJson<T>(T value) {
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }

    return value;
  }
}

class IntegerListConverter extends TypeConverter<List<int>, String> {
  const IntegerListConverter();

  @override
  List<int>? mapToDart(String? fromDb) {
    if (fromDb == null) {
      return null;
    }
    final ret = jsonDecode(fromDb);
    return ret.cast<int>();
  }

  @override
  String? mapToSql(List<int>? value) {
    return jsonEncode(value);
  }
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'jizhang.db'));
    return NativeDatabase(file, logStatements: true);
  });
}

@DriftDatabase(tables: [Categories, Events, Transactions, Tags, Budgets])
class MyDatabase extends _$MyDatabase {
  // we tell the database where to store the data with this constructor
  MyDatabase() : super(_openConnection());

  Future<void> insertPredefinedCategories() async {
    var expenseCategoryColorKeys = expenseCategoryColorInfo.keys.toList();
    for (int i = 0; i < expenseCategoryColorKeys.length; ++i) {
      var curCategory = expenseCategoryColorKeys[i];
      ui.IconData icon =
          (expenseCategoryIconInfo[curCategory] as ui.Icon).icon as ui.IconData;
      ui.Color color = expenseCategoryColorInfo[curCategory] as ui.Color;
      into(categories).insertOnConflictUpdate(CategoriesCompanion.insert(
          name: curCategory,
          type: 'expense',
          icon: jsonEncode({
            "codePoint": icon.codePoint,
            "fontFamily": icon.fontFamily,
            "fontPackage": icon.fontPackage
          }),
          color: color.value.toString(),
          predefined: 1,
          pos: i));
    }
    var incomeCategoryColorKeys = incomeCategoryIconInfo.keys.toList();
    for (int i = 0; i < incomeCategoryColorKeys.length; ++i) {
      var curCategory = incomeCategoryColorKeys[i];
      ui.IconData icon =
          (incomeCategoryIconInfo[curCategory] as ui.Icon).icon as ui.IconData;
      ui.Color color = incomeCategoryColorInfo[curCategory] as ui.Color;
      into(categories).insertOnConflictUpdate(CategoriesCompanion.insert(
          name: curCategory,
          type: 'income',
          icon: jsonEncode({
            "codePoint": icon.codePoint,
            "fontFamily": icon.fontFamily,
            "fontPackage": icon.fontPackage
          }),
          color: color.value.toString(),
          predefined: 1,
          pos: i));
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (Migrator m) {
        m.createAll();
        return insertPredefinedCategories();
      }, onUpgrade: (Migrator m, int from, int to) async {
        m.drop(categories);
        m.drop(transactions);
        m.drop(events);
        m.drop(tags);
        m.createAll();
        insertPredefinedCategories();
      });

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 2;

  Stream<List<Transaction>>? getTransactionsByMonth(int year, int month) {
    DateTime startDate = DateTime(year, month);
    DateTime endDate =
        DateTime(year, month + 1).subtract(const Duration(days: 1));
    return (select(transactions)
          ..where((t) => t.date.isBetween(
              CustomExpression(
                  (startDate.millisecondsSinceEpoch / 1000).toString(),
                  precedence: Precedence.primary),
              CustomExpression(
                  (endDate.millisecondsSinceEpoch / 1000).toString(),
                  precedence: Precedence.primary)))
          ..orderBy(
              [(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<CategoryItem>>? watchAllCategories() {
    return (select(categories)
          ..orderBy([(u) => OrderingTerm(expression: u.pos)]))
        .watch()
        .map((value) {
      List<CategoryItem> ret = [];
      for (var item in value) {
        ret.add(CategoryItem(item));
      }
      return ret;
    });
  }

  Stream<List<CategoryItem>>? watchCategoriesByType(String type) {
    return (select(categories)
          ..where((c) => c.type.equals(type))
          ..orderBy([(u) => OrderingTerm(expression: u.pos)]))
        .watch()
        .map((value) {
      List<CategoryItem> ret = [];
      for (var item in value) {
        ret.add(CategoryItem(item));
      }
      return ret;
    });
  }

  Future<List<BudgetItem>>? getBudgetItems() async {
    DateTime now = DateTime.now().getDateOnly();
    int currentYear = now.year;
    int currentMonth = now.month;
    int currentDay = now.day;
    int currentWeek = now.weekday;
    var budgetItems = await select(budgets).map((value) {
      return BudgetItem(value);
    }).get();
    var curTransactions = <Transaction>[];
    for (final budget in budgetItems) {
      DateTime? startDate;
      DateTime? endDate;
      switch (budget.recurrence) {
        case RECURRENCE_TYPE.daily:
          break;
        case RECURRENCE_TYPE.biweekly:
          break;
        case RECURRENCE_TYPE.weekly:
          break;
        case RECURRENCE_TYPE.monthly:
          startDate = DateTime(currentYear, currentMonth);
          endDate = DateTime(currentYear, currentMonth + 1)
              .subtract(const Duration(days: 1));
          break;
        case RECURRENCE_TYPE.yearly:
          break;
      }
      if (startDate != null && endDate != null) {
        curTransactions = await (select(transactions)
              ..where((t) => t.date.isBetween(
                  CustomExpression(
                      (startDate!.millisecondsSinceEpoch / 1000).toString(),
                      precedence: Precedence.primary),
                  CustomExpression(
                      (endDate!.millisecondsSinceEpoch / 1000).toString(),
                      precedence: Precedence.primary)))
              ..orderBy([
                (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)
              ]))
            .get();
      }
      var totalExpenses = 0.0;
      var categoryExpenses = budget.categoryIds;
      for (final transaction in curTransactions) {
        if (categoryExpenses.contains(transaction.categoryId)) {
          totalExpenses += transaction.amount;
        }
      }
      budget.used = totalExpenses;
    }
    return budgetItems;
  }

  Stream<ui.DateTimeRange>? getTransactionRange() {
    final minDate = transactions.date.min();
    final maxDate = transactions.date.max();
    return (selectOnly(transactions)..addColumns([minDate, maxDate]))
        .watchSingleOrNull()
        .map((row) {
      if (row != null) {
        return ui.DateTimeRange(
            start: row.read(minDate), end: row.read(maxDate));
      }
      return ui.DateTimeRange(start: DateTime.now(), end: DateTime.now());
    });
  }
}
