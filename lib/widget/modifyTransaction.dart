import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/categoryNameHelper.dart';
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/categorySelector.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;

class CategoryItem implements Comparable {
  CategoryItem(Category category) {
    id = category.id;
    name = category.name;
    type = category.type;
    predefined = category.predefined;
    var iconIn = jsonDecode(category.icon);
    icon = IconData(iconIn['codePoint'],
        fontFamily: iconIn['fontFamily'], fontPackage: iconIn['fontPackage']);
    color = Color(int.parse(category.color));
    index = category.index;
  }

  late int id;
  late String name;
  late String type;
  late int index;
  late int predefined;
  late IconData icon;
  late Color color;

  @override
  int compareTo(other) {
    if (other is CategoryItem) {
      return index.compareTo(other.index);
    }
    return 0;
  }

  String getDisplayName(BuildContext context) {
    if (predefined == 1) {
      return CategoryNameLocalizationHelper.getDisplayName(name, type, context);
    }
    return name;
  }
}

class ModifyTransactionsPage extends StatefulWidget {
  const ModifyTransactionsPage({Key? key, required this.transaction})
      : super(key: key);
  final Transaction? transaction;

  @override
  State<ModifyTransactionsPage> createState() => _ModifyTransactionsPageState();
}

class _ModifyTransactionsPageState extends State<ModifyTransactionsPage> {
  late MyDatabase db;
  late bool isAdd;
  late int selectedCategoryId;
  DateTime selectedDate = DateTime.now().getDateOnly();
  Color categoryColor = const Color(0xFF68a1e8);
  Icon selectedCategoryIcon = const Icon(Icons.add, color: Colors.white);

  final TextEditingController moneyController =
      TextEditingController(text: "0");

  final TextEditingController dateController =
      TextEditingController(text: DateTime.now().format("yyyy-MM-dd"));

  final TextEditingController commentController =
      TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    if (null == widget.transaction) {
      isAdd = true;
      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
        showCategorySelector(context);
      });
    } else {
      setState(() {
        isAdd = false;
        moneyController.text = widget.transaction!.money.toStringAsFixed(2);
        dateController.text = widget.transaction!.date.format("yyyy-MM-dd");
        commentController.text = widget.transaction!.comment ?? "";
        selectedCategoryId = widget.transaction!.categoryId;
        selectedDate = widget.transaction!.date;
      });
    }
  }

  bool canSave() {
    return moneyController.text.isNotEmpty &&
        0 != double.tryParse(moneyController.text) &&
        Icons.add != selectedCategoryIcon.icon;
  }

  void showCategorySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => const CategorySelectorWidget(),
    ).then((value) {
      if (null != value) {
        setState(() {
          categoryColor = value["color"];
          selectedCategoryIcon = Icon(value["icon"], color: Colors.white);
          selectedCategoryId = value["id"] as int;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    db = Provider.of<MyDatabase>(context);
    if (!isAdd) {
      (db.select(db.categories)..where((t) => t.id.equals(selectedCategoryId)))
          .getSingleOrNull()
          .then((value) {
        CategoryItem categoryItem = CategoryItem(value!);
        setState(() {
          categoryColor = categoryItem.color;
          selectedCategoryIcon = Icon(categoryItem.icon, color: Colors.white);
        });
      });
    }
    return Scaffold(
        appBar: AppBar(
            backgroundColor: categoryColor,
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
                        final money = double.parse(moneyController.text);
                        if (isAdd) {
                          int id = await db
                              .into(db.transactions)
                              .insert(TransactionsCompanion.insert(
                                money: money,
                                date: selectedDate,
                                categoryId: selectedCategoryId,
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
                                    money: drift.Value(money),
                                    date: drift.Value(selectedDate),
                                    categoryId: drift.Value(selectedCategoryId),
                                    comment: drift.Value(
                                        commentController.text.isEmpty
                                            ? null
                                            : commentController.text)),
                              );
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
            color: categoryColor,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    DottedBorder(
                      borderType: BorderType.Circle,
                      color: Colors.white,
                      padding: const EdgeInsets.all(0),
                      dashPattern: const [6],
                      child: MaterialButton(
                        onPressed: () {
                          showCategorySelector(context);
                        },
                        child: selectedCategoryIcon,
                        shape: const CircleBorder(),
                      ),
                    ),
                    // const Spacer(),
                    Expanded(
                      child: TextFormField(
                        controller: moneyController,
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
            leading: Icon(Icons.calendar_today, color: categoryColor),
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
            leading: Icon(Icons.note, color: categoryColor),
            title: TextField(
              controller: commentController,
              keyboardType: TextInputType.multiline,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: AppLocalizations.of(context)!
                    .modifyTransaction_Comment_hint,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.label, color: categoryColor),
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
                                backgroundColor: categoryColor.withOpacity(0.1),
                                label: Text(cur.name),
                                onSelected: (bool value) {},
                              ));
                        });
                  })),
          const Spacer(),
          Center(child: _buildNumberTablet())
        ]));
  }

  void _onNumberTabletPressed(
      {int? number, bool isDot = false, bool isRemove = false}) {
    String tmp = moneyController.text;
    if (isRemove) {
      tmp = tmp.substring(0, tmp.length - 1);
    } else if (isDot) {
      tmp = tmp + ".";
    } else if (number != null) {
      tmp = tmp + number.toString();
    }
    setState(() {
      // remove leading zero
      tmp = tmp.replaceFirst(RegExp('^0+'), '');
      // make sure only two number after dot
      // use '[0-9]+' to ensure that if tmp is Empty then set to "0"
      tmp = RegExp("[0-9]+[.]?[0-9]{0,2}").stringMatch(tmp) ?? "0";
      moneyController.text = tmp;
    });
  }

  Widget _buildNumberTablet() {
    return GridView.count(
      padding: const EdgeInsets.all(4),
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 4 / 2.5,
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      children: <Widget>[
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 18),
            primary: Colors.black,
            backgroundColor: Colors.white,
          ),
          child: const Text('1'),
          onPressed: () {
            _onNumberTabletPressed(number: 1);
          },
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 18),
            primary: Colors.black,
            backgroundColor: Colors.white,
          ),
          child: const Text('2'),
          onPressed: () {
            _onNumberTabletPressed(number: 2);
          },
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 18),
            primary: Colors.black,
            backgroundColor: Colors.white,
          ),
          child: const Text('3'),
          onPressed: () {
            _onNumberTabletPressed(number: 3);
          },
        ),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18),
              primary: Colors.black,
              backgroundColor: Colors.white,
            ),
            child: const Text('4'),
            onPressed: () {
              _onNumberTabletPressed(number: 4);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18),
              primary: Colors.black,
              backgroundColor: Colors.white,
            ),
            child: const Text('5'),
            onPressed: () {
              _onNumberTabletPressed(number: 5);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18),
              primary: Colors.black,
              backgroundColor: Colors.white,
            ),
            child: const Text('6'),
            onPressed: () {
              _onNumberTabletPressed(number: 6);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18),
              primary: Colors.black,
              backgroundColor: Colors.white,
            ),
            child: const Text('7'),
            onPressed: () {
              _onNumberTabletPressed(number: 7);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18),
              primary: Colors.black,
              backgroundColor: Colors.white,
            ),
            child: const Text('8'),
            onPressed: () {
              _onNumberTabletPressed(number: 8);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18),
              primary: Colors.black,
              backgroundColor: Colors.white,
            ),
            child: const Text('9'),
            onPressed: () {
              _onNumberTabletPressed(number: 9);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18),
              primary: Colors.black,
              backgroundColor: Colors.white,
            ),
            child: const Text('.'),
            onPressed: () {
              _onNumberTabletPressed(isDot: true);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18),
              primary: Colors.black,
              backgroundColor: Colors.white,
            ),
            child: const Text('0'),
            onPressed: () {
              _onNumberTabletPressed(number: 0);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18),
              primary: Colors.black,
              backgroundColor: Colors.white,
            ),
            child: const Icon(
              Icons.backspace,
              color: Colors.red,
            ),
            onPressed: () {
              _onNumberTabletPressed(isRemove: true);
            }),
      ],
    );
  }
}
