// import 'dart:async';
// import 'dart:convert';
// import 'dart:io' as io;
//
// import 'package:flutter/material.dart';
// import 'package:ji_zhang/models/index.dart' as models;
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
//
//
//
// class DatabaseHelper {
//   static const _dbName = "jizhang.db";
//   static const _dbVersion = 3;
//
//   // make this a singleton class
//   DatabaseHelper._privateConstructor();
//
//   static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
//
//   // only have a single app-wide reference to the database
//   static Database? _db;
//
//   Future<Database> get database async => _db ??= await _initiateDatabase();
//
//   // this opens the database (and creates it if it doesn't exist)
//   Future<Database> _initiateDatabase() async {
//     io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
//     String path = join(documentsDirectory.path, _dbName);
//     return await openDatabase(path,
//         version: _dbVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
//   }
//
//   // SQL code to create the database table
//   Future _onCreate(Database db, int version) async {
//     await db.execute("DROP TABLE IF EXISTS `transaction`");
//     await db.execute(
//         "CREATE TABLE `transaction` (`id` INTEGER PRIMARY KEY, `name` TEXT, `money` INTEGER, `date` TEXT, `categoryId` INTEGER, `tagIds` TEXT, `recurrence` TEXT, `comment` TEXT, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
//     await db.execute("DROP TABLE IF EXISTS `category`");
//     await db.execute(
//         "CREATE TABLE `category` (`id` INTEGER PRIMARY KEY, `name` TEXT, `type` TEXT, `icon` TEXT, `color` TEXT, `predefined` INTEGER(1), `index` INTEGER, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
//     await db.execute("DROP TABLE IF EXISTS `event`");
//     await db.execute(
//         "CREATE TABLE `event` (`id` INTEGER PRIMARY KEY, `name` TEXT, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
//     await db.execute("DROP TABLE IF EXISTS `tag`");
//     await db.execute(
//         "CREATE TABLE `tag` (`id` INTEGER PRIMARY KEY, `name` TEXT, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
//
//     await insertPredefinedCategories(db);
//   }
//
//   Future _onUpgrade(Database db, int a, int b) async {
//     await db.execute("DROP TABLE IF EXISTS `transaction`");
//     await db.execute(
//         "CREATE TABLE `transaction` (`id` INTEGER PRIMARY KEY, `money` INTEGER, `date` TEXT, `categoryId` INTEGER, `tagIds` TEXT, `recurrence` TEXT, `comment` TEXT, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
//     await db.execute("DROP TABLE IF EXISTS `category`");
//     await db.execute(
//         "CREATE TABLE `category` (`id` INTEGER PRIMARY KEY, `name` TEXT, `type` TEXT, `icon` TEXT, `color` TEXT, `predefined` INTEGER(1), `index` INTEGER, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
//     await db.execute("DROP TABLE IF EXISTS `event`");
//     await db.execute(
//         "CREATE TABLE `event` (`id` INTEGER PRIMARY KEY, `name` TEXT, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
//     await db.execute("DROP TABLE IF EXISTS `tag`");
//     await db.execute(
//         "CREATE TABLE `tag` (`id` INTEGER PRIMARY KEY, `name` TEXT, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
//
//     await insertPredefinedCategories(db);
//   }
//
//   Future insertPredefinedCategories(Database db) async {
//     var expenseCategoryColorKeys = expenseCategoryColorInfo.keys.toList();
//     for (int i = 0; i < expenseCategoryColorKeys.length; ++i) {
//       var category = expenseCategoryColorKeys[i];
//       IconData icon =
//           (expenseCategoryIconInfo[category] as Icon).icon as IconData;
//       Color color = expenseCategoryColorInfo[category] as Color;
//       await db.insert(
//           "category",
//           {
//             "name": category,
//             "type": 'expense',
//             "icon": jsonEncode({
//               "codePoint": icon.codePoint,
//               "fontFamily": icon.fontFamily,
//               "fontPackage": icon.fontPackage
//             }),
//             "color": color.value.toString(),
//             "predefined": 1,
//             "index": i
//           },
//           conflictAlgorithm: ConflictAlgorithm.ignore);
//     }
//     var incomeCategoryColorKeys = incomeCategoryIconInfo.keys.toList();
//     for (int i = 0; i < incomeCategoryColorKeys.length; ++i) {
//       var category = incomeCategoryColorKeys[i];
//       IconData icon =
//           (incomeCategoryIconInfo[category] as Icon).icon as IconData;
//       Color color = incomeCategoryColorInfo[category] as Color;
//       await db.insert(
//           "category",
//           {
//             "name": category,
//             "type": 'income',
//             "icon": jsonEncode({
//               "codePoint": icon.codePoint,
//               "fontFamily": icon.fontFamily,
//               "fontPackage": icon.fontPackage
//             }),
//             "color": color.value.toString(),
//             "predefined": 1,
//             "index": i
//           },
//           conflictAlgorithm: ConflictAlgorithm.ignore);
//     }
//   }
//
//   Future<List<models.Tag>> getAllTags() async {
//     Database db = await database;
//     String sql = "SELECT * FROM `tag`";
//     List<Map<String, dynamic>> result = await db.rawQuery(sql);
//     List<models.Tag> ret = [];
//     if (result.isNotEmpty) {
//       for (var item in result) {
//         ret.add(models.Tag.fromJson(item));
//       }
//     }
//     return ret;
//   }
//
//   Future<int> insertTag(models.Tag tag) async {
//     Database db = await database;
//     int id = await db.insert("tag", tag.toJson(),
//         conflictAlgorithm: ConflictAlgorithm.replace);
//     return id;
//   }
//
//   Future<bool> updateTag(models.Tag tag) async {
//     Database db = await database;
//     var args = tag.toJson();
//     args.remove("id");
//     int rowsUpdated =
//         await db.update("tag", args, where: "id = ?", whereArgs: [tag.id]);
//     return rowsUpdated == 1;
//   }
//
//   Future<bool> deleteTag(num tagId) async {
//     Database db = await database;
//     int rowsDeleted =
//         await db.delete("tag", where: "id = ?", whereArgs: [tagId]);
//     return rowsDeleted == 1;
//   }
//
//   void truncateTag() async {
//     Database db = await database;
//     await db.execute("DELETE FROM `tag`");
//   }
//
//   Future<List<models.Event>> getAllEvents() async {
//     Database db = await database;
//     String sql = "SELECT * FROM `event`";
//     List<Map<String, dynamic>> result = await db.rawQuery(sql);
//     List<models.Event> ret = [];
//     if (result.isNotEmpty) {
//       for (var item in result) {
//         ret.add(models.Event.fromJson(item));
//       }
//     }
//     return ret;
//   }
//
//   Future<int> insertEvent(models.Event event) async {
//     Database db = await database;
//     int id = await db.insert("event", event.toJson(),
//         conflictAlgorithm: ConflictAlgorithm.replace);
//     return id;
//   }
//
//   Future<bool> updateEvent(models.Event event) async {
//     Database db = await database;
//     var args = event.toJson();
//     args.remove("id");
//     int rowsUpdated =
//         await db.update("event", args, where: "id = ?", whereArgs: [event.id]);
//     return rowsUpdated == 1;
//   }
//
//   Future<bool> deleteEvent(num eventId) async {
//     Database db = await database;
//     int rowsDeleted =
//         await db.delete("event", where: "id = ?", whereArgs: [eventId]);
//     return rowsDeleted == 1;
//   }
//
//   void truncateEvent() async {
//     Database db = await database;
//     await db.execute("DELETE FROM `event`");
//   }
//
//   Future<List<models.Category>> getAllCategories() async {
//     Database db = await database;
//     String sql = "SELECT * FROM `category`";
//     List<Map<String, Object?>> result = await db.rawQuery(sql);
//     List<models.Category> ret = [];
//     if (result.isNotEmpty) {
//       for (var item in result) {
//         ret.add(models.Category.fromJson(item));
//       }
//     }
//     return ret;
//   }
//
//   Future<int> insertCategory(models.Category category) async {
//     Database db = await database;
//     int id = await db.insert("category", category.toJson(),
//         conflictAlgorithm: ConflictAlgorithm.replace);
//     return id;
//   }
//
//   Future<bool> updateCategory(models.Category category) async {
//     Database db = await database;
//     var args = category.toJson();
//     args.remove("id");
//     args.remove("createdAt");
//     int rowsUpdated = await db
//         .update("category", args, where: "id = ?", whereArgs: [category.id]);
//     return rowsUpdated == 1;
//   }
//
//   Future<bool> deleteCategory(num categoryId) async {
//     Database db = await database;
//     int rowsDeleted =
//         await db.delete("category", where: "id = ?", whereArgs: [categoryId]);
//     return rowsDeleted == 1;
//   }
//
//   void truncateCategory() async {
//     Database db = await database;
//     await db.execute("DELETE FROM `category`");
//   }
//
//   Future<List<models.Transaction>> getAllTransactions() async {
//     Database db = await database;
//     List<Map<String, Object?>> result =
//         await db.rawQuery("SELECT * FROM `transaction`");
//     List<models.Transaction> ret = [];
//     if (result.isNotEmpty) {
//       for (var item in result) {
//         ret.add(models.Transaction.fromJson(item));
//       }
//     }
//     return ret;
//   }
//
//   Future<List<models.Transaction>> getTransactionsByMonth(
//       int year, int month) async {
//     Database db = await database;
//     DateTime startDate = DateTime(year, month = month);
//     DateTime endDate =
//         DateTime(year, month = month + 1).subtract(const Duration(days: 1));
//     List<Map<String, Object?>> result = await db.query("transaction",
//         where: "Date(date) >= ? and Date(date) <= ?",
//         whereArgs: [startDate.toString(), endDate.toString()]);
//     List<models.Transaction> ret = [];
//     if (result.isNotEmpty) {
//       for (var item in result) {
//         ret.add(models.Transaction.fromJson(item));
//       }
//     }
//     return ret;
//   }
//
//   Future<int> insertTransaction(models.Transaction transaction) async {
//     Database db = await database;
//     int id = await db.insert("transaction", transaction.toJson(),
//         conflictAlgorithm: ConflictAlgorithm.replace);
//     return id;
//   }
//
//   Future<bool> updateTransaction(models.Transaction transaction) async {
//     Database db = await database;
//     var args = transaction.toJson();
//     args.remove("id");
//     args.remove("createdAt");
//     int rowsUpdated = await db.update("transaction", args,
//         where: "id = ?", whereArgs: [transaction.id]);
//     return rowsUpdated == 1;
//   }
//
//   Future<bool> deleteTransaction(num transactionId) async {
//     Database db = await database;
//     int rowsDeleted = await db
//         .delete("transaction", where: "id = ?", whereArgs: [transactionId]);
//     return rowsDeleted == 1;
//   }
//
//   void truncateTransaction() async {
//     Database db = await database;
//     await db.rawDelete("DELETE FROM `transaction`");
//   }
// }
