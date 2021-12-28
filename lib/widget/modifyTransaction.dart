import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/common/datetime_extension.dart';
import 'package:ji_zhang/common/dbHelper.dart';
import 'package:ji_zhang/models/categoryList.dart';
import 'package:ji_zhang/models/index.dart';
import 'package:ji_zhang/models/labelList.dart';
import 'package:ji_zhang/models/transactionList.dart';
import 'package:ji_zhang/widget/categorySelector.dart';
import 'package:provider/provider.dart';

class CategoryItem implements Comparable {
  CategoryItem(Category category) {
    id = category.id;
    name = category.name;
    type = category.type;
    var iconIn = jsonDecode(category.icon);
    icon = IconData(iconIn['codePoint'],
        fontFamily: iconIn['fontFamily'], fontPackage: iconIn['fontPackage']);
    color = Color(int.parse(category.color));
    index = category.index;
  }

  late num id;
  late String name;
  late String type;
  late int index;
  late IconData icon;
  late Color color;

  @override
  int compareTo(other) {
    if (other is CategoryItem) {
      return index.compareTo(other.index);
    }
    return 0;
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
  late Transaction transaction;
  late bool isAdd;
  Color categoryColor = const Color(0xFF68a1e8);
  Icon selectedCategoryIcon = const Icon(Icons.add, color: Colors.white);

  final TextEditingController moneyController =
      TextEditingController(text: "0");

  final TextEditingController dateController =
      TextEditingController(text: DateTime.now().format("yyyy-MM-dd"));

  final TextEditingController commentController =
      TextEditingController(text: "");
  late DatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    if (null == widget.transaction) {
      isAdd = true;
      transaction = Transaction();
      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
        showCategorySelector(context);
      });
    } else {
      isAdd = false;
      transaction = Transaction.fromJson(widget.transaction!.toJson());
      moneyController.text = transaction.money.toStringAsFixed(2);
      dateController.text = transaction.date.format("yyyy-MM-dd");
      commentController.text = transaction.comment ?? "";
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
          transaction.categoryId = value["id"] as int;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdd) {
      CategoryItem categoryItem =
          context.read<CategoryList>().itemsMap[transaction.categoryId]!;
      setState(() {
        categoryColor = categoryItem.color;
        selectedCategoryIcon = Icon(categoryItem.icon, color: Colors.white);
      });
    }
    return Scaffold(
        appBar: AppBar(
            backgroundColor: categoryColor,
            elevation: 0,
            centerTitle: true,
            title: Text((isAdd ? "Add" : "Edit") + " Transaction"),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(context);
              },
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save transaction',
                onPressed: canSave()
                    ? () async {
                  transaction.money = double.parse(moneyController.text);
                        if (isAdd) {
                          int id = await DatabaseHelper.instance
                              .insertTransaction(transaction);
                          if (0 == id) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to add transaction"),
                              ),
                            );
                          } else {
                            transaction.id = id;
                            context.read<TransactionList>().modify(transaction);
                            Navigator.of(context, rootNavigator: true)
                                .pop(context);
                          }
                        } else {
                          bool ret = await DatabaseHelper.instance
                              .updateTransaction(transaction);
                          if (false == ret) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to update transaction"),
                              ),
                            );
                          } else {
                            context.read<TransactionList>().modify(transaction);
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
                        initialDate: transaction.date,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(3000))
                    .then((value) {
                  setState(() {
                    if (null != value) transaction.date = value;
                    dateController.text = transaction.date.format("yyyy-MM-dd");
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
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Write a comment",
              ),
              onChanged: (value) {
                setState(() {
                  transaction.comment = value;
                });
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.label, color: categoryColor),
            title: const Text("Labels"),
            trailing: const Icon(Icons.chevron_right),
          ),
          SizedBox(
            height: 50,
            child: Consumer<LabelList>(builder: (context, value, child) {
              final List<Label> labels = value.items;
              return ListView.builder(
                  itemCount: labels.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    Label? cur = labels[index];
                    return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: FilterChip(
                          backgroundColor: categoryColor.withOpacity(0.1),
                          label: Text(cur.name),
                          onSelected: (bool value) {},
                        ));
                  });
            }),
          ),
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
      tmp = RegExp("[0-9]*[.]?[0-9]{0,2}").stringMatch(tmp) ?? "0";
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
