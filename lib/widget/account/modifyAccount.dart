import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ModifyAccountPage extends StatefulWidget {
  final List<Account> accounts;
  final MyDatabase db;

  ModifyAccountPage({super.key, required this.accounts, required this.db});
  @override
  _ModifyAccountPageState createState() => _ModifyAccountPageState();
}

class _ModifyAccountPageState extends State<ModifyAccountPage> {
  Set<int> deletedAccounts = {};
  Set<int> modifiedAccounts = {};
  Set<int> addedAccounts = {};
  List<TextEditingController> controllers = [];
  List<FocusNode> focusNodes = [];
  List<bool> isEditing = [];

  TextEditingController newAccountNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < widget.accounts.length; i++) {
      controllers.add(TextEditingController(text: widget.accounts[i].name));
      focusNodes.add(FocusNode());
      isEditing.add(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!
            .transactions_BottomSheet_ManageAccounts),
        actions: [
          IconButton(
            icon: Icon(Icons.save_rounded),
            onPressed: () async {
              await (widget.db.delete(widget.db.accounts)
                    ..where((t) => t.id.isIn(deletedAccounts)))
                  .go();
              await (widget.db.delete(widget.db.categories)
                    ..where((t) => t.accountId.isIn(deletedAccounts)))
                  .go();
              await (widget.db.delete(widget.db.tags)
                    ..where((t) => t.accountId.isIn(deletedAccounts)))
                  .go();
              await (widget.db.delete(widget.db.transactions)
                    ..where((t) => t.accountId.isIn(deletedAccounts)))
                  .go();
              await (widget.db.delete(widget.db.budgets)
                    ..where((t) => t.accountId.isIn(deletedAccounts)))
                  .go();

              for (int i = 0; i < widget.accounts.length; i++) {
                if (modifiedAccounts.contains(widget.accounts[i].id)) {
                  await widget.db.update(widget.db.accounts).replace(
                      AccountsCompanion(
                          id: drift.Value<int>(widget.accounts[i].id),
                          name: drift.Value<String>(controllers[i].text)));
                  widget.accounts[i] = Account(
                      id: widget.accounts[i].id, name: controllers[i].text);
                } else if (addedAccounts.contains(widget.accounts[i].id)) {
                  int ret = await widget.db.into(widget.db.accounts).insert(
                      AccountsCompanion(
                          name: drift.Value<String>(controllers[i].text)));
                  widget.accounts[i] =
                      Account(id: ret, name: widget.accounts[i].name);
                  widget.db.insertPredefinedCategories(ret);
                }
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
            itemCount: widget.accounts.length + 1,
            itemBuilder: (context, index) {
              if (index == widget.accounts.length) {
                return TextButton(
                    key: UniqueKey(),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            newAccountNameController.text = "";
                            return AlertDialog(
                              title: Text(AppLocalizations.of(context)!
                                  .modifyAccount_AddAccountDialog_Ttile),
                              content: TextField(
                                  controller: newAccountNameController,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .modifyAccount_form_name,
                                  )),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                        AppLocalizations.of(context)!.cancel)),
                                TextButton(
                                    onPressed: () {
                                      setState(() {
                                        var newAccount = Account(
                                            id: DateTime.now()
                                                .millisecondsSinceEpoch,
                                            name:
                                                newAccountNameController.text);
                                        widget.accounts.add(newAccount);
                                        addedAccounts.add(newAccount.id);
                                        controllers.add(TextEditingController(
                                            text: newAccount.name));
                                        focusNodes.add(FocusNode());
                                        isEditing.add(false);
                                      });
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                        AppLocalizations.of(context)!.confirm)),
                              ],
                            );
                          });
                    },
                    child: Icon(Icons.add_rounded));
              }
              return Row(
                key: Key(widget.accounts[index].hashCode.toString()),
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Focus(
                      onFocusChange: (value) {
                        if (value == false) {
                          setState(() {
                            isEditing[index] = false;
                            modifiedAccounts.add(widget.accounts[index].id);
                          });
                        }
                      },
                      child: TextField(
                          maxLines: 1,
                          focusNode: focusNodes[index],
                          controller: controllers[index],
                          onSubmitted: (changed) {
                            setState(() {
                              focusNodes[index].unfocus();
                            });
                          },
                          onTap: () {
                            setState(() {
                              isEditing[index] = true;
                            });
                          },
                          onTapOutside: (event) {
                            setState(() {
                              isEditing[index] = false;
                              modifiedAccounts.add(widget.accounts[index].id);
                              focusNodes[index].unfocus();
                            });
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 4.4,
                            ),
                            border: isEditing[index]
                                ? const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(0)),
                                  )
                                : InputBorder.none,
                          )),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_rounded, color: Colors.red),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(AppLocalizations.of(context)!
                                  .modifyAccount_DeleteAccountDialog_Title),
                              content: Text(AppLocalizations.of(context)!
                                  .modifyAccount_DeleteAccountDialog_Content),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                        AppLocalizations.of(context)!.cancel)),
                                TextButton(
                                    onPressed: () {
                                      setState(() {
                                        deletedAccounts
                                            .add(widget.accounts[index].id);
                                        widget.accounts.removeAt(index);
                                        controllers.removeAt(index);
                                        focusNodes.removeAt(index);
                                        isEditing.removeAt(index);
                                      });
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      AppLocalizations.of(context)!.confirm,
                                      style: TextStyle(color: Colors.red),
                                    )),
                              ],
                            );
                          });
                    },
                  ),
                ],
              );
            }),
      )),
    );
  }
}
