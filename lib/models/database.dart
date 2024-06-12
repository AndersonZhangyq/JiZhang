import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations.dart';
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

  IntColumn get parentId => integer().nullable()();

  TextColumn get parentName => text().nullable()();

  IntColumn get accountId => integer()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  IntColumn get accountId => integer()();

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

  IntColumn get accountId => integer()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  RealColumn get amount => real()();

  TextColumn get categoryIds => text().map(const IntegerListConverter())();

  IntColumn get recurrence => intEnum<RECURRENCE_TYPE>()();

  IntColumn get accountId => integer()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();
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
  List<int> fromSql(String? fromDb) {
    if (fromDb == null) {
      return [];
    }
    final ret = jsonDecode(fromDb);
    return ret.cast<int>();
  }

  @override
  String toSql(List<int>? value) {
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

@DriftDatabase(
    tables: [Categories, Events, Transactions, Tags, Budgets, Accounts])
class MyDatabase extends _$MyDatabase {
  // we tell the database where to store the data with this constructor
  MyDatabase() : super(_openConnection());

  int currentAccountId = 1;

  Future<void> insertPredefinedCategories(int accountId) async {
    var expenseCategoryColorKeys = expenseCategoryColorInfo.keys.toList();
    for (int i = 0; i < expenseCategoryColorKeys.length; ++i) {
      var curCategory = expenseCategoryColorKeys[i];
      ui.IconData icon =
          (expenseCategoryIconInfo[curCategory] as ui.Icon).icon as ui.IconData;
      ui.Color color = expenseCategoryColorInfo[curCategory] as ui.Color;
      if (curCategory.contains("_")) {
        var splited = curCategory.split("_");
        var parentName = splited[0];
        var categoryName = splited[1];
        var parentCategory = await (select(categories)
              ..where((tbl) => tbl.name.equals(parentName))
              ..where((tbl) => tbl.accountId.equals(accountId)))
            .getSingleOrNull();
        if (parentCategory == null) {
          print("parent of $curCategory $parentName is not found!");
        } else {
          into(categories).insertOnConflictUpdate(CategoriesCompanion.insert(
              name: categoryName,
              type: 'expense',
              icon: jsonEncode({
                "codePoint": icon.codePoint,
                "fontFamily": icon.fontFamily,
                "fontPackage": icon.fontPackage
              }),
              color: color.value.toString(),
              predefined: 1,
              parentName: Value.absentIfNull(parentName),
              parentId: Value.absentIfNull(parentCategory.id),
              pos: i,
              accountId: accountId));
        }
      } else {
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
            pos: i,
            accountId: accountId));
      }
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
          pos: i,
          accountId: accountId));
    }
  }

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (Migrator m) async {
        print("onCreate called");
        m.createAll();
        currentAccountId = await into(accounts)
            .insert(AccountsCompanion.insert(name: "default"));
        insertPredefinedCategories(currentAccountId);
      }, onUpgrade: (Migrator m, int from, int to) async {
        m.drop(categories);
        m.drop(transactions);
        m.drop(events);
        m.drop(tags);
        m.drop(budgets);
        m.drop(accounts);
        m.createAll();
        currentAccountId = await into(accounts)
            .insert(AccountsCompanion.insert(name: "default"));
        insertPredefinedCategories(currentAccountId);
      }, beforeOpen: (details) async {
        var tmp = await select(accounts).get();
        if (tmp.isEmpty) {
          currentAccountId = await into(accounts)
              .insert(AccountsCompanion.insert(name: "default"));
        } else {
          currentAccountId = tmp.first.id;
        }
      });

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 8;

  Future<void> removeCategory(
      int categoryId, int defaultCategoryId, int? parentId) async {
    if (parentId == null) {
      await (update(transactions)..where((t) => t.id.equals(categoryId)))
          .write(TransactionsCompanion(categoryId: Value(defaultCategoryId)));
      await (delete(categories)..where((t) => t.id.equals(categoryId))).go();
    } else {
      await (update(transactions)..where((t) => t.id.equals(categoryId)))
          .write(TransactionsCompanion(categoryId: Value(parentId)));
      await (delete(categories)..where((t) => t.id.equals(categoryId))).go();
    }
  }

  Stream<List<Account>> watchAccounts() {
    return select(accounts).watch();
  }

  Stream<List<Transaction>>? getTransactionsByMonth(int year, int month) {
    DateTime startDate = DateTime(year, month);
    DateTime endDate =
        DateTime(year, month + 1).subtract(const Duration(days: 1));
    return (select(transactions)
          ..where((t) => t.accountId.equals(currentAccountId))
          ..where((t) => t.date.isBetween(
              CustomExpression(
                  (startDate.millisecondsSinceEpoch / 1000).toString(),
                  precedence: Precedence.primary),
              CustomExpression(
                  (endDate.millisecondsSinceEpoch / 1000).toString(),
                  precedence: Precedence.primary)))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch();
  }

  Stream<List<CategoryItem>>? watchAllCategories() {
    return (select(categories)
          ..where((t) => t.accountId.equals(currentAccountId))
          ..orderBy([(u) => OrderingTerm.asc(u.pos)]))
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
          ..where((t) => t.accountId.equals(currentAccountId))
          ..where((c) => c.type.equals(type))
          ..orderBy([(u) => OrderingTerm.asc(u.pos)]))
        .watch()
        .map((value) {
      List<CategoryItem> ret = [];
      for (var item in value) {
        ret.add(CategoryItem(item));
      }
      return ret;
    });
  }

  Stream<Map<String, List<CategoryItem>>>? watchCategoriesGroupByType() {
    return (select(categories)
          ..where((t) => t.accountId.equals(currentAccountId))
          ..orderBy([(u) => OrderingTerm.asc(u.pos)]))
        .watch()
        .map((value) {
      Map<String, List<CategoryItem>> ret = {};
      for (var item in value) {
        if (ret[item.type] == null) {
          ret[item.type] = [];
        }
        ret[item.type]!.add(CategoryItem(item));
      }
      return ret;
    });
  }

  Future<int?> getCategoryLastPosByType(String type) {
    return (select(categories)
          ..where((t) => t.accountId.equals(currentAccountId))
          ..where((c) => c.type.equals(type))
          ..orderBy([(u) => OrderingTerm.desc(u.pos)])
          ..limit(1))
        .map((c) => c.pos)
        .getSingleOrNull();
  }

  Stream<List<BudgetItem>>? watchBudgetItems() {
    DateTime now = DateTime.now().getDateOnly();
    int currentYear = now.year;
    int currentMonth = now.month;
    int currentDay = now.day;
    int currentWeekDay = now.weekday;
    Future<BudgetItem> process(BudgetItem budget) async {
      var curTransactions = <Transaction>[];
      DateTime? startDate;
      DateTime? endDate;
      switch (budget.recurrence) {
        case RECURRENCE_TYPE.daily:
          startDate = endDate = now;
          break;
        case RECURRENCE_TYPE.biweekly:
          startDate = DateTime(currentYear, currentMonth, currentDay)
              .subtract(Duration(days: currentWeekDay - 1));
          endDate = DateTime(currentYear, currentMonth, currentDay)
              .add(Duration(days: 14 - currentWeekDay));
          break;
        case RECURRENCE_TYPE.weekly:
          startDate = DateTime(currentYear, currentMonth, currentDay)
              .subtract(Duration(days: currentWeekDay - 1));
          endDate = DateTime(currentYear, currentMonth, currentDay)
              .add(Duration(days: 7 - currentWeekDay));
          break;
        case RECURRENCE_TYPE.monthly:
          startDate = DateTime(currentYear, currentMonth);
          endDate = DateTime(currentYear, currentMonth + 1)
              .subtract(const Duration(days: 1));
          break;
        case RECURRENCE_TYPE.yearly:
          startDate = DateTime(currentYear);
          endDate = DateTime(currentYear + 1).subtract(const Duration(days: 1));
          break;
      }
      curTransactions = await (select(transactions)
            ..where((t) => t.accountId.equals(currentAccountId))
            ..where((t) => t.date.isBetween(
                CustomExpression(
                    (startDate!.millisecondsSinceEpoch / 1000).toString(),
                    precedence: Precedence.primary),
                CustomExpression(
                    (endDate!.millisecondsSinceEpoch / 1000).toString(),
                    precedence: Precedence.primary)))
            ..orderBy([(t) => OrderingTerm.desc(t.id)]))
          .get();
      var totalExpenses = 0.0;
      var categoryExpenses = budget.categoryIds;
      for (final transaction in curTransactions) {
        if (categoryExpenses.contains(transaction.categoryId)) {
          totalExpenses += transaction.amount;
        }
      }
      budget.used = totalExpenses;
      return budget;
    }

    var query = select(budgets)
      ..where((t) => t.accountId.equals(currentAccountId));
    return query.map((t) => BudgetItem(t)).watch().asyncMap<List<BudgetItem>>(
        (budgetItems) =>
            Future.wait([for (final budget in budgetItems) process(budget)]));
  }

  Stream<ui.DateTimeRange>? getTransactionRange() {
    final minDate = transactions.date.min();
    final maxDate = transactions.date.max();
    return (selectOnly(transactions)
          ..where(transactions.accountId.equals(currentAccountId))
          ..addColumns([minDate, maxDate]))
        .watchSingleOrNull()
        .map((row) {
      if (row != null) {
        return ui.DateTimeRange(
            start: row.read(minDate)!, end: row.read(maxDate)!);
      }
      return ui.DateTimeRange(start: DateTime.now(), end: DateTime.now());
    });
  }

  Stream<List<Transaction>>? getTransactionsByMonthAndCategoryId(
      int year, int month, int categoryId) {
    DateTime startDate = DateTime(year, month);
    DateTime endDate =
        DateTime(year, month + 1).subtract(const Duration(days: 1));
    return (select(transactions)
          ..where((t) => t.accountId.equals(currentAccountId))
          ..where((t) => t.date.isBetween(
              CustomExpression(
                  (startDate.millisecondsSinceEpoch / 1000).toString(),
                  precedence: Precedence.primary),
              CustomExpression(
                  (endDate.millisecondsSinceEpoch / 1000).toString(),
                  precedence: Precedence.primary)))
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch();
  }

  Stream<List<Transaction>>? getTransactionsByYear(int year) {
    DateTime startDate = DateTime(year);
    DateTime endDate = DateTime(year + 1).subtract(const Duration(days: 1));
    return (select(transactions)
          ..where((t) => t.accountId.equals(currentAccountId))
          ..where((t) => t.date.isBetween(
              CustomExpression(
                  (startDate.millisecondsSinceEpoch / 1000).toString(),
                  precedence: Precedence.primary),
              CustomExpression(
                  (endDate.millisecondsSinceEpoch / 1000).toString(),
                  precedence: Precedence.primary)))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch();
  }

  Stream<List<Transaction>>? getTransactionsByYearAndCategoryId(
      int year, int id) {
    DateTime startDate = DateTime(year);
    DateTime endDate = DateTime(year + 1).subtract(const Duration(days: 1));
    return (select(transactions)
          ..where((t) => t.accountId.equals(currentAccountId))
          ..where((t) => t.date.isBetween(
              CustomExpression(
                  (startDate.millisecondsSinceEpoch / 1000).toString(),
                  precedence: Precedence.primary),
              CustomExpression(
                  (endDate.millisecondsSinceEpoch / 1000).toString(),
                  precedence: Precedence.primary)))
          ..where((t) => t.categoryId.equals(id))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch();
  }

  Stream<Map<DateTime, double>>? getMonthlySum(String categoryType) {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId))
    ]);
    query.where(categories.type.equals(categoryType));
    query.where(transactions.accountId.equals(currentAccountId));
    query.orderBy([OrderingTerm.desc(transactions.date)]);
    return query.watch().map((value) {
      Map<DateTime, double> ret = {};
      Map<DateTime, int> counter = {};
      for (var item in value) {
        DateTime date = item.read(transactions.date)!.getDateTillMonth();
        // if (date.year == 2023 && date.month == 6) {
        //   print(date);
        //   print(item.read(transactions.date));
        //   print(item.read(transactions.comment));
        // }
        if (ret[date] == null) {
          ret[date] = 0;
          counter[date] = 0;
        }
        ret[date] = ret[date]! + item.read(transactions.amount)!;
        counter[date] = counter[date]! + 1;
      }
      print(counter);
      return ret;
    });
  }

  Stream<Map<DateTime, double>>? getYearlySum(String categoryType) {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId))
    ]);
    query.where(categories.type.equals(categoryType));
    query.where(transactions.accountId.equals(currentAccountId));
    return query.watch().map((value) {
      Map<DateTime, double> ret = {};
      for (var item in value) {
        DateTime date = item.read(transactions.date)!.getDateTillYear();
        if (ret[date] == null) {
          ret[date] = 0;
        }
        ret[date] = ret[date]! + item.read(transactions.amount)!;
      }
      return ret;
    });
  }
}
