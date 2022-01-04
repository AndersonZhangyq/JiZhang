import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/models/database.dart';
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
  late MyDatabase db;

  @override
  void initState() {
    super.initState();
    db = Provider.of<MyDatabase>(context, listen: false);
  }

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
          AppBar(
            title: Text(AppLocalizations.of(context)!.account_title),
            leading: null,
          ),
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
                final externalRoot = (await getExternalStorageDirectory())!;
                Directory("${externalRoot.path}/backup")
                    .create(recursive: true);
                final allTransactions = await db.select(db.transactions).get();
                final transactionsFile =
                    File("${externalRoot.path}/backup/transaction.txt");
                setState(() {
                  backUpPercent++;
                });
                await transactionsFile
                    .writeAsString(jsonEncode(allTransactions));
                final allCategories = await db.select(db.categories).get();
                final categoriesFile =
                    File("${externalRoot.path}/backup/category.txt");
                await categoriesFile.writeAsString(jsonEncode(allCategories));
                setState(() {
                  backUpPercent++;
                });
                final allTages = await db.select(db.tags).get();
                final tagesFile =
                    File("${externalRoot.path}/backup/tag.txt");
                await tagesFile.writeAsString(jsonEncode(allTages));
                final allEvents = await db.select(db.events).get();
                setState(() {
                  backUpPercent++;
                });
                final eventsFile =
                    File("${externalRoot.path}/backup/event.txt");
                await eventsFile.writeAsString(jsonEncode(allEvents));
                setState(() {
                  backUpPercent++;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.account_BackupSuccess),
                ));
              } catch (e) {
                print(e.toString());
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
                final externalRoot = (await getExternalStorageDirectory())!;
                final transactionsFile =
                    File("${externalRoot.path}/backup/transaction.txt");
                final categoriesFile =
                    File("${externalRoot.path}/backup/category.txt");
                final tagesFile =
                    File("${externalRoot.path}/backup/tag.txt");
                final eventsFile =
                    File("${externalRoot.path}/backup/event.txt");
                if (!(await Directory("${externalRoot.path}/backup")
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
                                    db.delete(db.transactions);
                                    db.delete(db.categories);
                                    db.delete(db.tags);
                                    db.delete(db.events);
                                    final allTransactions = jsonDecode(
                                        await transactionsFile.readAsString());
                                    allTransactions
                                        .forEach((transaction) async {
                                      db
                                          .into(db.transactions)
                                          .insertOnConflictUpdate(
                                              Transaction.fromJson(transaction,
                                                  serializer:
                                                      const MyValueSerializer()));
                                    });
                                    setState(() {
                                      restorePercent++;
                                    });
                                    final allCategories = jsonDecode(
                                        await categoriesFile.readAsString());
                                    allCategories.forEach((category) async {
                                      db
                                          .into(db.categories)
                                          .insertOnConflictUpdate(
                                              Category.fromJson(category));
                                    });
                                    setState(() {
                                      restorePercent++;
                                    });
                                    final allTages = jsonDecode(
                                        await tagesFile.readAsString());
                                    allTages.forEach((tag) async {
                                      db.into(db.tags).insertOnConflictUpdate(
                                          Tag.fromJson(tag));
                                    });
                                    setState(() {
                                      restorePercent++;
                                    });
                                    final allEvents = jsonDecode(
                                        await eventsFile.readAsString());
                                    allEvents.forEach((event) async {
                                      db.into(db.events).insertOnConflictUpdate(
                                          Event.fromJson(event));
                                    });
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
