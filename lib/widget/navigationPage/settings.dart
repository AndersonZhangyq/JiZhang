import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

enum RestoreMode {
  TrancateCurrentAccount,
  TrancateAll,
}

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SettingsPageWidget();
  }
}

class SettingsPageWidget extends StatefulWidget {
  const SettingsPageWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPageWidget> {
  int backUpPercent = -1;
  int restorePercent = -1;
  late MyDatabase db;

  @override
  void initState() {
    super.initState();
    db = Provider.of<MyDatabase>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: SafeArea(
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        AppBar(
          title: Text(AppLocalizations.of(context)!.settings_title),
          leading: null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 0.0, 8.0),
          child: FutureBuilder<Directory?>(
              future: getExternalStorageDirectory(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(AppLocalizations.of(context)!.settings_DataPath +
                      "\n" +
                      snapshot.data!.path +
                      "/backup");
                }
                return const Text("");
              }),
        ),
        _buildBackupButton(),
        _buildRestoreButton(),
      ]),
    ));
  }

  Future<bool> _checkStoragePermission() async {
    final plugin = DeviceInfoPlugin();
    final android = await plugin.androidInfo;

    final storageStatus = android.version.sdkInt < 33
        ? await Permission.storage.request()
        : PermissionStatus.granted;

    if (!storageStatus.isGranted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context)!.settings_NeedStoragePermission)));
      return false;
    }
    return true;
  }

  Widget _buildBackupButton() {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.settings_Backup),
      trailing: Visibility(
        child: CircularProgressIndicator(
          value: backUpPercent / 5,
        ),
        visible: backUpPercent != -1,
      ),
      onTap: () async {
        backUpPercent = 0;
        if (await _checkStoragePermission() == false) return;
        try {
          final externalRoot = (await getExternalStorageDirectory())!;
          Directory("${externalRoot.path}/backup").create(recursive: true);
          final allTransactions = await db.select(db.transactions).get();
          final transactionsFile =
              File("${externalRoot.path}/backup/transaction.txt");
          await transactionsFile.writeAsString(jsonEncode(allTransactions));
          setState(() {
            backUpPercent++;
          });
          final allCategories = await db.select(db.categories).get();
          final categoriesFile =
              File("${externalRoot.path}/backup/category.txt");
          await categoriesFile.writeAsString(jsonEncode(allCategories));
          setState(() {
            backUpPercent++;
          });
          final allTages = await db.select(db.tags).get();
          final tagesFile = File("${externalRoot.path}/backup/tag.txt");
          await tagesFile.writeAsString(jsonEncode(allTages));
          setState(() {
            backUpPercent++;
          });
          final allEvents = await db.select(db.events).get();
          final eventsFile = File("${externalRoot.path}/backup/event.txt");
          await eventsFile.writeAsString(jsonEncode(allEvents));
          setState(() {
            backUpPercent++;
          });
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.settings_BackupSuccess),
          ));
          final allBudgets = await db.select(db.budgets).get();
          final budgetsFile = File("${externalRoot.path}/backup/budget.txt");
          await budgetsFile
              .writeAsString(jsonEncode(allBudgets, toEncodable: (value) {
            if (value is Budget) {
              var ret = value.toJson();
              ret['recurrence'] = value.recurrence.index;
              return ret;
            }
            return value;
          }));
          setState(() {
            backUpPercent++;
          });
          final allAccounts = await db.select(db.accounts).get();
          final accountsFile = File("${externalRoot.path}/backup/account.txt");
          await accountsFile.writeAsString(jsonEncode(allAccounts));
          setState(() {
            backUpPercent++;
          });
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.settings_BackupSuccess),
          ));
        } catch (e) {
          print(e.toString());
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.settings_BackupFaliure),
          ));
        } finally {
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() {
              backUpPercent = -1;
            });
          });
        }
      },
    );
  }

  Widget _buildRestoreButton() {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.settings_Restore),
      trailing: Visibility(
        child: CircularProgressIndicator(
          value: restorePercent / 5,
        ),
        visible: restorePercent != -1,
      ),
      onTap: () async {
        restorePercent = 0;
        if (await _checkStoragePermission() == false) return;
        try {
          final externalRoot = (await getExternalStorageDirectory())!;
          final transactionsFile =
              File("${externalRoot.path}/backup/transaction.txt");
          final categoriesFile =
              File("${externalRoot.path}/backup/category.txt");
          final tagesFile = File("${externalRoot.path}/backup/tag.txt");
          final eventsFile = File("${externalRoot.path}/backup/event.txt");
          final budgetsFile = File("${externalRoot.path}/backup/budget.txt");
          final accountsFile = File("${externalRoot.path}/backup/account.txt");
          if (!(await Directory("${externalRoot.path}/backup").exists())) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.settings_RestoreNotFound),
            ));
          } else {
            ValueNotifier<RestoreMode> restoreModeNotifier =
                ValueNotifier(RestoreMode.TrancateCurrentAccount);
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(AppLocalizations.of(context)!.settings_Restore),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppLocalizations.of(context)!
                            .settings_RestoreConfirm),
                        ListTile(
                          dense: true,
                          title: Text(AppLocalizations.of(context)!
                              .settings_Restore_TrancateCurrentAccount),
                          leading: ValueListenableBuilder<RestoreMode>(
                              valueListenable: restoreModeNotifier,
                              builder: (context, restoreMode, _) {
                                return Radio<RestoreMode>(
                                  value: RestoreMode.TrancateCurrentAccount,
                                  groupValue: restoreMode,
                                  onChanged: (value) {
                                    if (value != null) {
                                      restoreModeNotifier.value = value;
                                    }
                                  },
                                );
                              }),
                        ),
                        ListTile(
                          dense: true,
                          title: Text(AppLocalizations.of(context)!
                              .settings_Restore_TrancateAll),
                          leading: ValueListenableBuilder<RestoreMode>(
                              valueListenable: restoreModeNotifier,
                              builder: (context, restoreMode, _) {
                                return Radio<RestoreMode>(
                                  value: RestoreMode.TrancateAll,
                                  groupValue: restoreMode,
                                  onChanged: (value) {
                                    if (value != null) {
                                      restoreModeNotifier.value = value;
                                    }
                                  },
                                );
                              }),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: Text(AppLocalizations.of(context)!.cancel),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                          child: Text(AppLocalizations.of(context)!.ok),
                          onPressed: () async {
                            try {
                              if (restoreModeNotifier.value ==
                                  RestoreMode.TrancateCurrentAccount) {
                                Map<int, int> categoryMap = {};
                                Map<int, int> tagMap = {};
                                Map<int, int> eventMap = {};

                                if (await categoriesFile.exists()) {
                                  await (db.delete(db.categories)
                                        ..where((t) => t.accountId
                                            .equals(db.currentAccountId)))
                                      .go();
                                  final allCategories = jsonDecode(
                                      await categoriesFile.readAsString());
                                  allCategories.forEach((category) async {
                                    if (!category.containsKey('accountId')) {
                                      category['accountId'] =
                                          db.currentAccountId;
                                    }
                                    var newCategory =
                                        Category.fromJson(category);
                                    int newCategoryId = await db
                                        .into(db.categories)
                                        .insertOnConflictUpdate(
                                            CategoriesCompanion.insert(
                                                name: newCategory.name,
                                                type: newCategory.type,
                                                icon: newCategory.icon,
                                                color: newCategory.color,
                                                pos: newCategory.pos,
                                                predefined:
                                                    newCategory.predefined,
                                                parentId: drift.Value(
                                                    newCategory.parentId),
                                                parentName: drift.Value(
                                                    newCategory.parentName),
                                                accountId:
                                                    newCategory.accountId,
                                                createdAt: drift.Value(
                                                    newCategory.createdAt)));
                                    categoryMap[category['id']] = newCategoryId;
                                  });
                                  setState(() {
                                    restorePercent++;
                                  });
                                }
                                if (await tagesFile.exists()) {
                                  await (db.delete(db.tags)
                                        ..where((t) => t.accountId
                                            .equals(db.currentAccountId)))
                                      .go();
                                  final allTages = jsonDecode(
                                      await tagesFile.readAsString());
                                  allTages.forEach((tag) async {
                                    if (!tag.containsKey('accountId')) {
                                      tag['accountId'] = db.currentAccountId;
                                    }
                                    var newTag = Tag.fromJson(tag);
                                    int newTagId = await db
                                        .into(db.tags)
                                        .insertOnConflictUpdate(
                                            TagsCompanion.insert(
                                          name: newTag.name,
                                          accountId: newTag.accountId,
                                          createdAt:
                                              drift.Value(newTag.createdAt),
                                        ));
                                    tagMap[tag['id']] = newTagId;
                                  });
                                  setState(() {
                                    restorePercent++;
                                  });
                                }
                                if (await eventsFile.exists()) {
                                  await db.delete(db.events).go();
                                  final allEvents = jsonDecode(
                                      await eventsFile.readAsString());
                                  allEvents.forEach((event) async {
                                    var newEvent = Event.fromJson(event);
                                    await db
                                        .into(db.events)
                                        .insertOnConflictUpdate(
                                            EventsCompanion.insert(
                                          name: newEvent.name,
                                          createdAt:
                                              drift.Value(newEvent.createdAt),
                                        ));
                                  });
                                  setState(() {
                                    restorePercent++;
                                  });
                                }
                                if (await budgetsFile.exists()) {
                                  await (db.delete(db.budgets)
                                        ..where((t) => t.accountId
                                            .equals(db.currentAccountId)))
                                      .go();
                                  await db.delete(db.budgets).go();
                                  final allBudgets = jsonDecode(
                                      await budgetsFile.readAsString());
                                  allBudgets.forEach((budget) async {
                                    if (!budget.containsKey('accountId')) {
                                      budget['accountId'] = db.currentAccountId;
                                    }
                                    List<int> categoryIds = [];
                                    budget['categoryIds'].forEach((categoryId) {
                                      categoryIds.add(categoryMap[categoryId]!);
                                    });
                                    budget['categoryIds'] = categoryIds;
                                    var newBudget = Budget.fromJson(budget,
                                        serializer: const MyValueSerializer());
                                    await db
                                        .into(db.budgets)
                                        .insertOnConflictUpdate(
                                            BudgetsCompanion.insert(
                                                name: newBudget.name,
                                                amount: newBudget.amount,
                                                categoryIds:
                                                    newBudget.categoryIds,
                                                recurrence:
                                                    newBudget.recurrence,
                                                accountId: newBudget.accountId,
                                                createdAt: drift.Value(
                                                    newBudget.createdAt)));
                                  });
                                  setState(() {
                                    restorePercent++;
                                  });
                                }
                                if (await transactionsFile.exists()) {
                                  await (db.delete(db.transactions)
                                        ..where((t) => t.accountId
                                            .equals(db.currentAccountId)))
                                      .go();
                                  final allTransactions = jsonDecode(
                                      await transactionsFile.readAsString());
                                  allTransactions.forEach((transaction) async {
                                    if (!transaction.containsKey('accountId')) {
                                      transaction['accountId'] =
                                          db.currentAccountId;
                                    }
                                    var newTransaction = Transaction.fromJson(
                                        transaction,
                                        serializer: const MyValueSerializer());
                                    await db
                                        .into(db.transactions)
                                        .insertOnConflictUpdate(
                                            TransactionsCompanion.insert(
                                          amount: newTransaction.amount,
                                          date: newTransaction.date,
                                          categoryId: categoryMap[
                                              newTransaction.categoryId]!,
                                          recurrence: drift.Value(
                                              newTransaction.recurrence),
                                          tagIds: newTransaction.tagIds == null
                                              ? drift.Value.absent()
                                              : drift.Value(newTransaction
                                                  .tagIds!
                                                  .map(
                                                      (tagId) => tagMap[tagId]!)
                                                  .toList()),
                                          comment: drift.Value(
                                              newTransaction.comment),
                                          accountId: newTransaction.accountId,
                                          createdAt: drift.Value(
                                              newTransaction.createdAt),
                                        ));
                                  });
                                  setState(() {
                                    restorePercent++;
                                  });
                                }
                              } else {
                                if (await transactionsFile.exists()) {
                                  await db.delete(db.transactions).go();
                                  final allTransactions = jsonDecode(
                                      await transactionsFile.readAsString());
                                  allTransactions.forEach((transaction) async {
                                    if (!transaction.containsKey('accountId')) {
                                      transaction['accountId'] =
                                          db.currentAccountId;
                                    }
                                    db
                                        .into(db.transactions)
                                        .insertOnConflictUpdate(
                                            Transaction.fromJson(
                                                transaction,
                                                serializer:
                                                    const MyValueSerializer()));
                                  });
                                  setState(() {
                                    restorePercent++;
                                  });
                                }

                                if (await categoriesFile.exists()) {
                                  await db.delete(db.categories).go();
                                  final allCategories = jsonDecode(
                                      await categoriesFile.readAsString());
                                  allCategories.forEach((category) async {
                                    if (!category.containsKey('accountId')) {
                                      category['accountId'] =
                                          db.currentAccountId;
                                    }
                                    db
                                        .into(db.categories)
                                        .insertOnConflictUpdate(
                                            Category.fromJson(category));
                                  });
                                  setState(() {
                                    restorePercent++;
                                  });
                                }
                                if (await tagesFile.exists()) {
                                  await db.delete(db.tags).go();
                                  final allTages = jsonDecode(
                                      await tagesFile.readAsString());
                                  allTages.forEach((tag) async {
                                    if (!tag.containsKey('accountId')) {
                                      tag['accountId'] = db.currentAccountId;
                                    }
                                    db.into(db.tags).insertOnConflictUpdate(
                                        Tag.fromJson(tag));
                                  });
                                  setState(() {
                                    restorePercent++;
                                  });
                                }
                                if (await eventsFile.exists()) {
                                  await db.delete(db.events).go();
                                  final allEvents = jsonDecode(
                                      await eventsFile.readAsString());
                                  allEvents.forEach((event) async {
                                    db.into(db.events).insertOnConflictUpdate(
                                        Event.fromJson(event));
                                  });
                                  setState(() {
                                    restorePercent++;
                                  });
                                }
                                if (await budgetsFile.exists()) {
                                  await db.delete(db.budgets).go();
                                  final allBudgets = jsonDecode(
                                      await budgetsFile.readAsString());
                                  allBudgets.forEach((budget) async {
                                    if (!budget.containsKey('accountId')) {
                                      budget['accountId'] = db.currentAccountId;
                                    }
                                    db.into(db.budgets).insertOnConflictUpdate(
                                        Budget.fromJson(budget,
                                            serializer:
                                                const MyValueSerializer()));
                                  });
                                  setState(() {
                                    restorePercent++;
                                  });
                                }
                                if (await accountsFile.exists()) {
                                  await db.delete(db.accounts).go();
                                  final allAccounts = jsonDecode(
                                      await accountsFile.readAsString());
                                  allAccounts.forEach((account) async {
                                    db.into(db.accounts).insertOnConflictUpdate(
                                        Account.fromJson(account));
                                  });
                                  setState(() {
                                    restorePercent++;
                                  });
                                }
                              }
                              ScaffoldMessenger.of(context)
                                  .removeCurrentSnackBar();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .settings_RestoreSuccess),
                              ));
                            } catch (e) {
                              ScaffoldMessenger.of(context)
                                  .removeCurrentSnackBar();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .settings_RestoreFailure),
                              ));
                            } finally {
                              Navigator.of(context).pop();
                              Future.delayed(const Duration(milliseconds: 300),
                                  () {
                                setState(() {
                                  restorePercent = -1;
                                });
                              });
                            }
                          })
                    ],
                  );
                });
          }
        } catch (e) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context)!.settings_RestoreFailure),
          ));
        } finally {
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() {
              restorePercent = -1;
            });
          });
        }
      },
    );
  }
}

class AccountItemWidget extends StatefulWidget {
  const AccountItemWidget({
    super.key,
    required this.account,
    required this.db,
  });

  final Account account;
  final MyDatabase db;

  @override
  State<AccountItemWidget> createState() => _AccountItemWidgetState();
}

class _AccountItemWidgetState extends State<AccountItemWidget> {
  TextEditingController _nameController = TextEditingController();
  FocusNode _nameFocusNode = FocusNode();
  bool _nameIsEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.account.name;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Focus(
        onFocusChange: (value) {
          if (value == false) {
            setState(() {
              _nameIsEditing = false;
            });
          }
        },
        child: TextField(
            maxLines: 1,
            focusNode: _nameFocusNode,
            controller: _nameController,
            onSubmitted: (changed) {
              setState(() {
                _nameFocusNode.unfocus();
              });
            },
            onTap: () {
              setState(() {
                _nameIsEditing = true;
              });
            },
            onTapOutside: (event) {
              setState(() {
                _nameIsEditing = false;
                _nameFocusNode.unfocus();
              });
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 4.4,
              ),
              border: _nameIsEditing
                  ? const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(0)),
                    )
                  : InputBorder.none,
            )),
      ),
      trailing: IconButton(
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          onPressed: () async {
            (widget.db.delete(widget.db.accounts)
                  ..where((t) => t.id.equals(widget.account.id)))
                .go();
          }),
    );
  }
}
