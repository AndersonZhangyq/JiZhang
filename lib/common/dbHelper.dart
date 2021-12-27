import 'dart:async';
import 'dart:io' as io;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ji_zhang/models/index.dart' as models;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

final Map<String, Icon> expenseCategoryIconInfo = {
  "Food": const Icon(Icons.fastfood),
  "Shopping": const Icon(Icons.shopping_cart),
  "Transport": const Icon(Icons.directions_car),
  "Home": const Icon(Icons.home),
  "Bills": const Icon(Icons.attach_money),
  "Entertainment": const Icon(Icons.local_movies),
  "Car": const Icon(Icons.directions_car),
  "Travel": const Icon(Icons.airplanemode_active),
  "Family": const Icon(Icons.people),
  "Healthcare": const Icon(Icons.local_hospital),
  "Education": const Icon(Icons.school),
  "Groceries": const Icon(Icons.local_grocery_store),
  "Gifts": const Icon(Icons.card_giftcard),
  "Sports": const Icon(Icons.directions_run),
  "Beauty": const Icon(Icons.face),
  "Work": const Icon(Icons.work),
  "Other": const Icon(Icons.more_horiz)
};

final Map<String, Color> expenseCategoryColorInfo = {
  "Food": Colors.orange,
  "Shopping": Colors.pink,
  "Transport": Colors.yellow,
  "Home": Colors.brown,
  "Bills": Colors.green,
  "Entertainment": Colors.deepOrange,
  "Car": Colors.blue,
  "Travel": Colors.redAccent,
  "Family": Colors.blueGrey,
  "Healthcare": Colors.purple,
  "Education": Colors.amber,
  "Groceries": Colors.blueAccent,
  "Gifts": Colors.greenAccent,
  "Sports": Colors.lightGreen,
  "Beauty": Colors.purpleAccent,
  "Work": Colors.grey,
  "Other": Colors.grey,
};

final Map<String, Icon> incomeCategoryIconInfo = {
  "Salary": const Icon(Icons.attach_money),
  "Business": const Icon(Icons.business),
  "Gifts": const Icon(Icons.card_giftcard),
  "ExtraIncome": const Icon(Icons.money_sharp),
  "Loan": const Icon(Icons.wallet_giftcard),
  "ParentalLeave": const Icon(Icons.people),
  "InsurancePayout": const Icon(Icons.local_hospital),
  "Other": const Icon(Icons.more_horiz)
};

final Map<String, Color> incomeCategoryColorInfo = {
  "Salary": Colors.green,
  "Business": Colors.orange,
  "Gifts": Colors.greenAccent,
  "ExtraIncome": Colors.lightGreen,
  "Loan": Colors.pinkAccent,
  "ParentalLeave": Colors.pink,
  "InsurancePayout": Colors.blueAccent,
  "Other": Colors.grey
};

class DatabaseHelper {
  static const _dbName = "jizhang.db";
  static const _dbVersion = 1;

  // make this a singleton class
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _db;

  Future<Database> get database async => _db ??= await _initiateDatabase();

  // this opens the database (and creates it if it doesn't exist)
  Future<Database> _initiateDatabase() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path,
        version: _dbVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute("DROP TABLE IF EXISTS `transaction`");
    await db.execute(
        "CREATE TABLE `transaction` (`id` INTEGER PRIMARY KEY, `name` TEXT, `money` INTEGER, `date` TEXT, `categoryId` INTEGER, `labelIds` TEXT, `recurrence` TEXT, `comment` TEXT)");
    await db.execute("DROP TABLE IF EXISTS `category`");
    await db.execute(
        "CREATE TABLE `category` (`id` INTEGER PRIMARY KEY, `name` TEXT, `type` TEXT, `icon` TEXT, `color` TEXT)");
    await db.execute("DROP TABLE IF EXISTS `event`");
    await db.execute(
        "CREATE TABLE `event` (`id` INTEGER PRIMARY KEY, `name` TEXT)");
    await db.execute("DROP TABLE IF EXISTS `label`");
    await db.execute(
        "CREATE TABLE `label` (`id` INTEGER PRIMARY KEY, `name` TEXT)");

    await insertPredefinedCategories(db);
  }

  Future _onUpgrade(Database db, int a, int b) async {
    await db.execute("DROP TABLE IF EXISTS `transaction`");
    await db.execute(
        "CREATE TABLE `transaction` (`id` INTEGER PRIMARY KEY, `money` INTEGER, `date` TEXT, `categoryId` INTEGER, `labelIds` TEXT, `recurrence` TEXT, `comment` TEXT)");
    await db.execute("DROP TABLE IF EXISTS `category`");
    await db.execute(
        "CREATE TABLE `category` (`id` INTEGER PRIMARY KEY, `name` TEXT, `type` TEXT, `icon` TEXT, `color` TEXT)");
    await db.execute("DROP TABLE IF EXISTS `event`");
    await db.execute(
        "CREATE TABLE `event` (`id` INTEGER PRIMARY KEY, `name` TEXT)");
    await db.execute("DROP TABLE IF EXISTS `label`");
    await db.execute(
        "CREATE TABLE `label` (`id` INTEGER PRIMARY KEY, `name` TEXT)");

    await insertPredefinedCategories(db);
  }

  Future insertPredefinedCategories(Database db) async {
    for (var category in expenseCategoryColorInfo.keys) {
      IconData icon =
          (expenseCategoryIconInfo[category] as Icon).icon as IconData;
      Color color = expenseCategoryColorInfo[category] as Color;
      await db.insert(
          "category",
          {
            "name": category,
            "type": 'expense',
            "icon": jsonEncode({
              "codePoint": icon.codePoint,
              "fontFamily": icon.fontFamily,
              "fontPackage": icon.fontPackage
            }),
            "color": color.value.toString()
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (var category in incomeCategoryIconInfo.keys) {
      IconData icon =
          (incomeCategoryIconInfo[category] as Icon).icon as IconData;
      Color color = incomeCategoryColorInfo[category] as Color;
      await db.insert(
          "category",
          {
            "name": category,
            "type": 'income',
            "icon": jsonEncode({
              "codePoint": icon.codePoint,
              "fontFamily": icon.fontFamily,
              "fontPackage": icon.fontPackage
            }),
            "color": color.value.toString()
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<models.Label>> queryLabel() async {
    Database db = await database;
    String sql = "SELECT * FROM `label`";
    List<Map<String, dynamic>> result = await db.rawQuery(sql);
    List<models.Label> ret = [];
    if (result.isNotEmpty) {
      for (var item in result) {
        ret.add(models.Label.fromJson(item));
      }
    }
    return ret;
  }

  Future<int> insertLabel(models.Label label) async {
    Database db = await database;
    int id = await db.insert("label", label.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  void updateLabel(models.Label label) {}

  Future<bool> deleteLabel(num labelId) async {
    Database db = await database;
    int rowsDeleted =
        await db.delete("label", where: "id = ?", whereArgs: [labelId]);
    return rowsDeleted == 1;
  }

  Future<List<models.Event>> queryEvent() async {
    Database db = await database;
    String sql = "SELECT * FROM `event`";
    List<Map<String, dynamic>> result = await db.rawQuery(sql);
    List<models.Event> ret = [];
    if (result.isNotEmpty) {
      for (var item in result) {
        ret.add(models.Event.fromJson(item));
      }
    }
    return ret;
  }

  Future<int> insertEvent(models.Event event) async {
    Database db = await database;
    int id = await db.insert("event", event.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<bool> updateEvent(models.Event event) async {
    Database db = await database;
    int rowsUpdated = await db.update("event", event.toJson(),
        where: "id = ?", whereArgs: [event.id]);
    return rowsUpdated == 1;
  }

  Future<bool> deleteEvent(num eventId) async {
    Database db = await database;
    int rowsDeleted =
        await db.delete("event", where: "id = ?", whereArgs: [eventId]);
    return rowsDeleted == 1;
  }

  Future<List<models.Category>> queryCategory() async {
    Database db = await database;
    String sql = "SELECT * FROM `category`";
    List<Map<String, Object?>> result = await db.rawQuery(sql);
    List<models.Category> ret = [];
    if (result.isNotEmpty) {
      for (var item in result) {
        ret.add(models.Category.fromJson(item));
      }
    }
    return ret;
  }

  Future<int> insertCategory(models.Category category) async {
    Database db = await database;
    int id = await db.insert("category", category.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<bool> updateCategory(models.Category category) async {
    Database db = await database;
    int rowsUpdated = await db.update("category", category.toJson(),
        where: "id = ?", whereArgs: [category.id]);
    return rowsUpdated == 1;
  }

  Future<bool> deleteCategory(num categoryId) async {
    Database db = await database;
    int rowsDeleted =
        await db.delete("category", where: "id = ?", whereArgs: [categoryId]);
    return rowsDeleted == 1;
  }

  Future<List<models.Transaction>> queryTransaction() async {
    Database db = await database;
    String sql = "SELECT * FROM `transaction` ORDER BY `date` DESC";
    List<Map<String, Object?>> result = await db.rawQuery(sql);
    List<models.Transaction> ret = [];
    if (result.isNotEmpty) {
      for (var item in result) {
        ret.add(models.Transaction.fromJson(item));
      }
    }
    return ret;
  }

  Future<int> insertTransaction(models.Transaction transaction) async {
    Database db = await database;
    int id = await db.insert("transaction", transaction.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<bool> updateTransaction(models.Transaction transaction) async {
    Database db = await database;
    int rowsUpdated = await db.update("transaction", transaction.toJson(),
        where: "id = ?", whereArgs: [transaction.id]);
    return rowsUpdated == 1;
  }

  Future<bool> deleteTransaction(num transactionId) async {
    Database db = await database;
    int rowsDeleted = await db
        .delete("transaction", where: "id = ?", whereArgs: [transactionId]);
    return rowsDeleted == 1;
  }
}
