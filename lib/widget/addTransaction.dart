import 'package:ji_zhang/models/labelList.dart';
import 'package:ji_zhang/models/transactionList.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:ji_zhang/common/dbHelper.dart';
import 'package:ji_zhang/models/index.dart';
import 'package:ji_zhang/widget/categorySelector.dart';
import 'package:ji_zhang/common/datetime_extension.dart';
import 'dart:convert';

class CategoryItem {
  CategoryItem(Category category) {
    id = category.id;
    name = category.name;
    type = category.type;
    var iconIn = jsonDecode(category.icon);
    icon = IconData(iconIn['codePoint'],
        fontFamily: iconIn['fontFamily'], fontPackage: iconIn['fontPackage']);
    color = Color(int.parse(category.color));
  }

  late num id;
  late String name;
  late String type;
  late IconData icon;
  late Color color;
}

class AddTransactionsWidget extends StatelessWidget {
  const AddTransactionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: AddTransactionsPage(),
    );
  }
}

class AddTransactionsPage extends StatefulWidget {
  const AddTransactionsPage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  @override
  State<AddTransactionsPage> createState() => _AddTransactionsPageState();
}

class _AddTransactionsPageState extends State<AddTransactionsPage> {
  Transaction transaction = Transaction();
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
  }

  bool canSave() {
    return moneyController.text.isNotEmpty &&
        moneyController.text != "0" &&
        selectedCategoryIcon.icon != Icons.add;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: categoryColor,
            elevation: 0,
            centerTitle: true,
            title: const Text("Add Transaction"),
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
                        int id = await DatabaseHelper.instance
                            .insertTransaction(transaction);
                        if (id == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to save transaction"),
                            ),
                          );
                        } else {
                          transaction.id = id;
                          context.read<TransactionList>().add(transaction);
                          Navigator.of(context, rootNavigator: true)
                              .pop(context);
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    DottedBorder(
                      borderType: BorderType.Circle,
                      color: Colors.white,
                      padding: const EdgeInsets.all(0),
                      dashPattern: const [6],
                      child: MaterialButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) =>
                                const CategorySelectorWidget(),
                          ).then((value) {
                            if (value != null) {
                              setState(() {
                                categoryColor = value["color"];
                                selectedCategoryIcon =
                                    Icon(value["icon"], color: Colors.white);
                                transaction.categoryId = value["id"] as int;
                              });
                            }
                          });
                        },
                        child: selectedCategoryIcon,
                        shape: const CircleBorder(),
                      ),
                    ),
                    const Spacer(),
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
                        onChanged: (String text) {
                          double? value = double.tryParse(text);
                          setState(() {
                            if (value != null) transaction.money = value;
                          });
                        },
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
                    if (value != null) transaction.date = value;
                    dateController.text = transaction.date.format("yyyy-MM-dd");
                  });
                });
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.note, color: categoryColor),
            title: Focus(
              child: TextField(
                controller: commentController,
                keyboardType: TextInputType.multiline,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Write a comment",
                ),
              ),
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  setState(() {
                    transaction.comment = commentController.text;
                  });
                }
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.label, color: categoryColor),
            title: const Text("Labels"),
            trailing: const Icon(Icons.chevron_right),
          ),
          Container(
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
          )
        ]));
  }
}
