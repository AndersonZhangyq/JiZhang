import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/categoryNameHelper.dart';
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/category/categorySelector.dart';
import 'package:ji_zhang/widget/moneyNumberTablet.dart';
import 'package:provider/provider.dart';

class CategoryItem implements Comparable {
  CategoryItem(Category category) {
    id = category.id;
    name = category.name;
    type = category.type;
    predefined = category.predefined;
    originColor = category.color;
    originIcon = category.icon;
    var iconIn = jsonDecode(category.icon);
    icon = IconData(iconIn['codePoint'],
        fontFamily: iconIn['fontFamily'], fontPackage: iconIn['fontPackage']);
    int? value = int.tryParse(category.color);
    if (value == null) {
      color = Colors.lightBlueAccent;
    } else {
      color = Color(int.parse(category.color));
    }
    pos = category.pos;
    parentId = category.parentId;
    parentName = category.parentName;
    accountId = category.accountId;
  }

  CategoryItem.empty();

  late int id;
  late String name;
  late String type;
  late int pos;
  late int predefined;
  late IconData icon;
  late Color color;
  late String originIcon;
  late String originColor;
  late int? parentId;
  late String? parentName;
  late int accountId;

  @override
  int compareTo(other) {
    if (other is CategoryItem) {
      return pos.compareTo(other.pos);
    }
    return 0;
  }

  String getDisplayName(BuildContext context) {
    if (parentId != null) {
      return CategoryNameLocalizationHelper.getDisplayName(
              parentName!, type, context) +
          " - " +
          CategoryNameLocalizationHelper.getDisplayName(name, type, context);
    } else {
      return CategoryNameLocalizationHelper.getDisplayName(name, type, context);
    }
  }

  String getTrueName(BuildContext context) {
    return CategoryNameLocalizationHelper.getDisplayName(name, type, context);
  }
}

class ModifyTransactionsPage extends StatefulWidget {
  const ModifyTransactionsPage(
      {Key? key, required this.transaction, required this.category})
      : super(key: key);
  final Transaction? transaction;
  final CategoryItem? category;

  @override
  State<ModifyTransactionsPage> createState() => _ModifyTransactionsPageState();
}

class _ModifyTransactionsPageState extends State<ModifyTransactionsPage> {
  late MyDatabase db;
  late bool isAdd;
  // late int selectedCategoryId;
  DateTime selectedDate = DateTime.now().getDateOnly();
  final defaultColor = const Color(0xFF68a1e8);
  final defaultIcon = const Icon(Icons.add, color: Colors.white);
  // Color categoryColor = const Color(0xFF68a1e8);
  // Icon selectedCategoryIcon = const Icon(Icons.add, color: Colors.white);
  CategoryItem? selectedCategory;

  final TextEditingController amountController = TextEditingController();

  final TextEditingController dateController =
      TextEditingController(text: DateTime.now().format("yyyy-MM-dd"));

  final TextEditingController commentController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
    if (null == widget.transaction) {
      isAdd = true;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        showCategorySelector(context);
      });
    } else {
      isAdd = false;
      amountController.text = widget.transaction!.amount.toStringAsFixed(2);
      dateController.text = widget.transaction!.date.format("yyyy-MM-dd");
      commentController.text = widget.transaction!.comment ?? "";
      selectedDate = widget.transaction!.date;
      selectedCategory = widget.category!;
    }
  }

  bool canSave() {
    return amountController.text.isNotEmpty &&
        0 != double.tryParse(amountController.text) &&
        selectedCategory != null;
  }

  void showCategorySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => const CategorySelectorWidget(),
    ).then((value) {
      if (null != value) {
        setState(() {
          // categoryColor = value["color"];
          // selectedCategoryIcon = Icon(value["icon"], color: Colors.white);
          // selectedCategoryId = value["id"] as int;
          selectedCategory = CategoryItem.empty();
          selectedCategory!.parentId = value["parentId"] as int?;
          selectedCategory!.name = value["name"] as String;
          selectedCategory!.type = value["type"] as String;
          selectedCategory!.color = value["color"] as Color;
          selectedCategory!.icon = value["icon"] as IconData;
          selectedCategory!.id = value["id"] as int;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
            backgroundColor: selectedCategory == null
                ? defaultColor
                : selectedCategory!.color,
            elevation: 0,
            centerTitle: true,
            title: Text((isAdd
                    ? AppLocalizations.of(context)!.modifyTransaction_Title_add
                    : AppLocalizations.of(context)!
                        .modifyTransaction_Title_edit) +
                AppLocalizations.of(context)!
                    .modifyTransaction_Title_transaction),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(context);
              },
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: canSave()
                    ? () async {
                        final amount = double.parse(amountController.text);
                        if (isAdd) {
                          int id = await db
                              .into(db.transactions)
                              .insert(TransactionsCompanion.insert(
                                amount: amount,
                                date: selectedDate,
                                categoryId: selectedCategory!.id,
                                accountId: db.currentAccountId,
                                comment: drift.Value(
                                    commentController.text.isEmpty
                                        ? null
                                        : commentController.text),
                              ));
                          if (0 == id) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .modifyTransaction_SnackBar_failed_to_add_transaction),
                              ),
                            );
                          } else {
                            Navigator.of(context, rootNavigator: true)
                                .pop(context);
                          }
                        } else {
                          bool ret = await db.update(db.transactions).replace(
                              TransactionsCompanion(
                                  id: drift.Value(widget.transaction!.id),
                                  amount: drift.Value(amount),
                                  date: drift.Value(selectedDate),
                                  categoryId: drift.Value(selectedCategory!.id),
                                  comment: drift.Value(
                                      commentController.text.isEmpty
                                          ? null
                                          : commentController.text),
                                  accountId: drift.Value(
                                      widget.transaction!.accountId)));
                          if (false == ret) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .modifyTransaction_SnackBar_failed_to_update_transaction),
                              ),
                            );
                          } else {
                            Navigator.of(context, rootNavigator: true)
                                .pop(context);
                          }
                        }
                      }
                    : null,
              ),
            ]),
        body: Column(children: [
          Container(
            color: selectedCategory == null
                ? defaultColor
                : selectedCategory!.color,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      children: [
                        DottedBorder(
                          borderType: BorderType.Circle,
                          color: Colors.white,
                          padding: const EdgeInsets.all(0),
                          dashPattern: const [6],
                          child: MaterialButton(
                            onPressed: () {
                              showCategorySelector(context);
                            },
                            child: selectedCategory == null
                                ? defaultIcon
                                : Icon(selectedCategory!.icon,
                                    color: Colors.white),
                            shape: const CircleBorder(),
                          ),
                        ),
                        Visibility(
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          visible: (selectedCategory != null) &&
                              (selectedCategory!.parentId != null),
                          child: SizedBox(
                            height: 24,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                selectedCategory == null
                                    ? ""
                                    : selectedCategory!.getTrueName(context),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    // const Spacer(),
                    Expanded(
                      child: TextFormField(
                        controller: amountController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 24),
                        textAlign: TextAlign.end,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          // border: OutlineInputBorder(),
                          border: InputBorder.none,
                        ),
                        readOnly: true,
                      ),
                    )
                  ],
                )),
          ),
          ListTile(
            leading: Icon(Icons.date_range,
                color: selectedCategory == null
                    ? defaultColor
                    : selectedCategory!.color),
            title: TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              showCursor: false,
              readOnly: true,
              controller: dateController,
              onTap: () {
                showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(3000))
                    .then((value) {
                  setState(() {
                    if (null != value) selectedDate = value;
                    dateController.text = selectedDate.format("yyyy-MM-dd");
                  });
                });
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.note,
                color: selectedCategory == null
                    ? defaultColor
                    : selectedCategory!.color),
            title: TextField(
              controller: commentController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: AppLocalizations.of(context)!
                    .modifyTransaction_Comment_hint,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.label,
                color: selectedCategory == null
                    ? defaultColor
                    : selectedCategory!.color),
            title: Text(AppLocalizations.of(context)!.tags),
            trailing: const Icon(Icons.chevron_right),
          ),
          SizedBox(
              height: 50,
              child: StreamBuilder<List<Tag>>(
                  stream: null,
                  builder: (context, snapshot) {
                    final tags = snapshot.data ?? <Tag>[];
                    return ListView.builder(
                        itemCount: tags.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          Tag cur = tags[index];
                          return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: FilterChip(
                                backgroundColor: (selectedCategory == null
                                        ? defaultColor
                                        : selectedCategory!.color)
                                    .withOpacity(0.1),
                                label: Text(cur.name),
                                onSelected: (bool value) {},
                              ));
                        });
                  })),
          const Spacer(),
          Center(
              child: MoneyNumberTablet(
            moneyController: amountController,
            callback: (text) {
              setState(() {
                amountController.text = text;
              });
            },
          ))
        ]));
  }
}
