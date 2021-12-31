import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/dbHelper.dart';
import 'package:ji_zhang/dbProxy/index.dart';
import 'package:ji_zhang/models/index.dart';
import 'package:ji_zhang/widget/modifyTransaction.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class AccountWidget extends StatelessWidget {
  const AccountWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AccountPageWidget();
  }
}

class AccountPageWidget extends StatefulWidget {
  const AccountPageWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPageWidget> {
  int backUpPercent = -1;
  int restorePercent = -1;

  Future<bool> _checkStoragePermission() async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              AppLocalizations.of(context)!.account_NeedStoragePermission)));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.account_Backup),
            trailing: Visibility(
              child: CircularProgressIndicator(
                value: backUpPercent / 4,
              ),
              visible: backUpPercent != -1,
            ),
            onTap: () async {
              backUpPercent = 0;
              if (await _checkStoragePermission() == false) return;
              try {
                final externalRoot = (await getExternalStorageDirectory())!
                    .parent
                    .parent
                    .parent
                    .parent;
                Directory("${externalRoot.path}/JiZhang/backup")
                    .create(recursive: true);
                final allTransactions =
                    await DatabaseHelper.instance.getAllTransactions();
                final transactionsFile =
                    File("${externalRoot.path}/JiZhang/backup/transaction.txt");
                setState(() {
                  backUpPercent++;
                });
                await transactionsFile
                    .writeAsString(jsonEncode(allTransactions));
                final allCategories =
                    await DatabaseHelper.instance.getAllCategories();
                final categoriesFile =
                    File("${externalRoot.path}/JiZhang/backup/category.txt");
                await categoriesFile.writeAsString(jsonEncode(allCategories));
                setState(() {
                  backUpPercent++;
                });
                final allTages = await DatabaseHelper.instance.getAllTags();
                final tagesFile =
                    File("${externalRoot.path}/JiZhang/backup/tag.txt");
                await tagesFile.writeAsString(jsonEncode(allTages));
                final allEvents = await DatabaseHelper.instance.getAllEvents();
                setState(() {
                  backUpPercent++;
                });
                final eventsFile =
                    File("${externalRoot.path}/JiZhang/backup/event.txt");
                await eventsFile.writeAsString(jsonEncode(allEvents));
                setState(() {
                  backUpPercent++;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.account_BackupSuccess),
                ));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.account_BackupFaliure),
                ));
              } finally {
                Future.delayed(const Duration(milliseconds: 300), () {
                  setState(() {
                    backUpPercent = -1;
                  });
                });
              }
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.account_Restore),
            trailing: Visibility(
              child: CircularProgressIndicator(
                value: restorePercent / 4,
              ),
              visible: restorePercent != -1,
            ),
            onTap: () async {
              restorePercent = 0;
              if (await _checkStoragePermission() == false) return;
              try {
                final externalRoot = (await getExternalStorageDirectory())!
                    .parent
                    .parent
                    .parent
                    .parent;
                final transactionsFile =
                    File("${externalRoot.path}/JiZhang/backup/transaction.txt");
                final categoriesFile =
                    File("${externalRoot.path}/JiZhang/backup/category.txt");
                final tagesFile =
                    File("${externalRoot.path}/JiZhang/backup/tag.txt");
                final eventsFile =
                    File("${externalRoot.path}/JiZhang/backup/event.txt");
                if (!(await Directory("${externalRoot.path}/JiZhang/backup")
                        .exists() &&
                    await transactionsFile.exists() &&
                    await categoriesFile.exists() &&
                    await tagesFile.exists() &&
                    await eventsFile.exists())) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        AppLocalizations.of(context)!.account_RestoreNotFound),
                  ));
                } else {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                              AppLocalizations.of(context)!.account_Restore),
                          content: Text(AppLocalizations.of(context)!
                              .account_RestoreConfirm),
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
                                    DatabaseHelper.instance
                                        .truncateTransaction();
                                    context.read<TransactionList>().removeAll();
                                    DatabaseHelper.instance.truncateCategory();
                                    context.read<CategoryList>().removeAll();
                                    DatabaseHelper.instance.truncateTag();
                                    context.read<TagList>().removeAll();
                                    DatabaseHelper.instance.truncateEvent();
                                    context.read<EventList>().removeAll();
                                    final allTransactions = jsonDecode(
                                        await transactionsFile.readAsString());
                                    allTransactions
                                        .forEach((transaction) async {
                                      await DatabaseHelper.instance
                                          .insertTransaction(
                                              Transaction.fromJson(
                                                  transaction));
                                    });
                                    context.read<TransactionList>().addAll(
                                        await DatabaseHelper.instance
                                            .getTransactionsByMonth(
                                                context
                                                    .read<TransactionList>()
                                                    .year,
                                                context
                                                    .read<TransactionList>()
                                                    .month));
                                    setState(() {
                                      restorePercent++;
                                    });
                                    final allCategories = jsonDecode(
                                        await categoriesFile.readAsString());
                                    allCategories.forEach((category) async {
                                      await DatabaseHelper.instance
                                          .insertCategory(
                                              Category.fromJson(category));
                                      context.read<CategoryList>().modify(
                                          CategoryItem(
                                              Category.fromJson(category)));
                                    });
                                    setState(() {
                                      restorePercent++;
                                    });
                                    final allTages = jsonDecode(
                                        await tagesFile.readAsString());
                                    allTages.forEach((tag) async {
                                      await DatabaseHelper.instance
                                          .insertTag(Tag.fromJson(tag));
                                    });
                                    context.read<TagList>().addAll(
                                        await DatabaseHelper.instance
                                            .getAllTags());
                                    setState(() {
                                      restorePercent++;
                                    });
                                    final allEvents = jsonDecode(
                                        await eventsFile.readAsString());
                                    allEvents.forEach((event) async {
                                      await DatabaseHelper.instance
                                          .insertEvent(Event.fromJson(event));
                                    });
                                    context.read<EventList>().addAll(
                                        await DatabaseHelper.instance
                                            .getAllEvents());
                                    setState(() {
                                      restorePercent++;
                                    });
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .account_RestoreSuccess),
                                    ));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .account_RestoreFailure),
                                    ));
                                  } finally {
                                    Navigator.of(context).pop();
                                    Future.delayed(
                                        const Duration(milliseconds: 300), () {
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      AppLocalizations.of(context)!.account_RestoreFailure),
                ));
              } finally {
                Future.delayed(const Duration(milliseconds: 300), () {
                  setState(() {
                    restorePercent = -1;
                  });
                });
              }
            },
          )
        ],
      ),
    ));
  }
}
