import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/category/categorySelector.dart';
import 'package:ji_zhang/widget/ocr/billImport.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image/image.dart' as image;

class RecognizedTransaction {
  IconData? iconData;
  Color? color;
  int? categoryId;
  String? categoryType;

  late String billName;
  late String billExtraInfo;
  late DateTime billDate;
  late double billAmount;
  late double billRefund;
  late bool isExpense;
  late double amount;
  late String title;
  late DateTime date;

  RecognizedTransaction(ExtractedTransaction transaction) {
    billName = transaction.billName;
    billExtraInfo = transaction.billExtraInfo;
    billDate = transaction.billDate;
    billAmount = transaction.billAmount - transaction.billRefund;
    billRefund = transaction.billRefund;
    isExpense = transaction.isExpense;
    amount = billAmount * (isExpense ? -1 : 1) + billRefund;
    title = billName;
    date = billDate.getDateOnly();
  }
}

class AddTransactionsFromBillFile extends StatefulWidget {
  final List<ExtractedTransaction> extractedTransactions;

  const AddTransactionsFromBillFile(
      {super.key, required this.extractedTransactions});
  @override
  State<AddTransactionsFromBillFile> createState() =>
      _AddTransactionsFromBillFileState();
}

class _AddTransactionsFromBillFileState
    extends State<AddTransactionsFromBillFile> {
  List<RecognizedTransaction> recognizedTransactions = [];
  List<bool> _selected = [];
  late MyDatabase db;
  late image.Image img;
  @override
  void initState() {
    super.initState();
    generateRecognizedTransactions();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  @override
  Widget build(BuildContext context) {
    // generateRecognizedTransactions();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.batchAddTransaction_Title),
        actions: recognizedTransactions.isEmpty
            ? []
            : [
                IconButton(
                    icon: Icon(Icons.save),
                    onPressed: () async {
                      if (!_selected.any((value) => value == true)) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .batchAddTransaction_SnackBar_choose_at_least_one_transaction)));
                        return;
                      }
                      for (int i = 0; i < recognizedTransactions.length; i++) {
                        if (_selected[i]) {
                          if (recognizedTransactions[i].categoryId == null) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .batchAddTransaction_SnackBar_transactions_without_category)));
                            return;
                          }
                        }
                      }
                      List<RecognizedTransaction> failedTransactions = [];
                      List<bool> failedSelected = [];
                      for (int i = 0; i < recognizedTransactions.length; i++) {
                        final transaction = recognizedTransactions[i];
                        if (_selected[i]) {
                          var id = await db.into(db.transactions).insert(
                              TransactionsCompanion.insert(
                                  amount: transaction.amount,
                                  date: transaction.date,
                                  categoryId: transaction.categoryId!,
                                  comment: drift.Value(transaction.title.isEmpty
                                      ? null
                                      : transaction.title),
                                  accountId: db.currentAccountId));
                          if (0 == id) {
                            failedTransactions.add(transaction);
                            failedSelected.add(_selected[i]);
                          }
                        } else {
                          failedTransactions.add(transaction);
                          failedSelected.add(_selected[i]);
                        }
                      }
                      if (failedTransactions.isNotEmpty) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .batchAddTransaction_SnackBar_failed_to_add_part_of_transactions)));
                        setState(() {
                          recognizedTransactions = failedTransactions;
                          _selected = failedSelected;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    }),
              ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) => Divider(),
                itemCount: recognizedTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = recognizedTransactions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child:
                        // Text("${index}")
                        TransactionListElment(
                            key: ValueKey(transaction.hashCode),
                            isSelected: _selected[index],
                            // widget: widget,
                            transaction: transaction,
                            index: index,
                            onSelected: (value) {
                              _selected[index] = value;
                            }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void generateRecognizedTransactions() {
    recognizedTransactions.clear();
    for (var item in widget.extractedTransactions) {
      final recognizedTransaction = RecognizedTransaction(item);
      recognizedTransactions.add(recognizedTransaction);
      _selected.add(true);
    }
  }
}

class TransactionListElment extends StatefulWidget {
  const TransactionListElment({
    super.key,
    // required this.widget,
    required this.transaction,
    required this.index,
    required this.onSelected,
    required this.isSelected,
  });

  // final BatchAddTransactions widget;
  final RecognizedTransaction transaction;
  final int index;
  final bool isSelected;
  final Null Function(bool value) onSelected;

  @override
  State<TransactionListElment> createState() => _TransactionListElmentState();
}

class _TransactionListElmentState extends State<TransactionListElment> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  bool _titleIsEditing = false;
  bool _amountIsEditing = false;
  FocusNode _titleFocusNode = FocusNode();
  FocusNode _amountFocusNode = FocusNode();
  bool _isSelected = true;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;
    _titleController.text = widget.transaction.title;
    _amountController.text = widget.transaction.amount < 0
        ? '${widget.transaction.amount.toStringAsFixed(2)}'
        : '+${widget.transaction.amount.toStringAsFixed(2)}';
  }

  void updateAmountController() {
    if (widget.transaction.categoryType != null) {
      if (widget.transaction.categoryType == 'income') {
        _amountController.text =
            '+${widget.transaction.amount.toStringAsFixed(2)}';
      } else {
        _amountController.text =
            '${widget.transaction.amount.toStringAsFixed(2)}';
      }
    } else {
      _amountController.text = widget.transaction.amount < 0
          ? '${widget.transaction.amount.toStringAsFixed(2)}'
          : '+${widget.transaction.amount.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Opacity(
        opacity: _isSelected ? 1 : 0.3,
        child: Column(
          children: [
            // _isSelected ? Image.memory(widget.imageBytes) : Container(),
            ListTile(
              title: ListTile(
                contentPadding: const EdgeInsets.all(0),
                title: Text(
                  '${widget.transaction.billName}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.transaction.isExpense
                          ? Colors.red
                          : Colors.green),
                ),
                subtitle: widget.transaction.billExtraInfo.isNotEmpty
                    ? Text('${widget.transaction.billExtraInfo}')
                    : Container(),
              ),
              subtitle: Text(
                  '${widget.transaction.billDate.format("yyyy-MM-dd hh:mm:ss")}'),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '账单金额  ${widget.transaction.billAmount.toStringAsFixed(2)}',
                  ),
                  Text(
                    '账单退款  ${widget.transaction.billRefund.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 2),
              horizontalTitleGap: 8,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                      value: _isSelected,
                      onChanged: (value) {
                        if (value != null) {
                          widget.onSelected(value);
                          setState(() {
                            _isSelected = value;
                          });
                        }
                      }),
                  FloatingActionButton.small(
                    heroTag: "transaction_category_${widget.index}",
                    child: widget.transaction.iconData == null
                        ? Icon(Icons.add, color: Colors.white)
                        : Icon(widget.transaction.iconData!),
                    backgroundColor: widget.transaction.iconData == null
                        ? Colors.lightBlue.withOpacity(0.6)
                        : widget.transaction.color!,
                    elevation: 0,
                    onPressed: _isSelected
                        ? () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) =>
                                  const CategorySelectorWidget(),
                            ).then((value) async {
                              if (null != value) {
                                setState(() {
                                  widget.transaction.iconData = value["icon"];
                                  widget.transaction.color = value["color"];
                                  widget.transaction.categoryId =
                                      value["id"] as int;
                                  widget.transaction.categoryType =
                                      value["type"] as String;
                                  widget.transaction.amount =
                                      widget.transaction.amount.abs();
                                  updateAmountController();
                                });
                              }
                            });
                          }
                        : null,
                  ),
                ],
              ),
              title: Focus(
                onFocusChange: (value) {
                  if (value == false) {
                    setState(() {
                      widget.transaction.title = _titleController.text;
                      _titleIsEditing = false;
                    });
                  }
                },
                child: TextField(
                    enabled: _isSelected,
                    maxLines: 1,
                    focusNode: _titleFocusNode,
                    controller: _titleController,
                    onSubmitted: (changed) {
                      setState(() {
                        _titleIsEditing = false;
                        _titleFocusNode.unfocus();
                      });
                    },
                    onTap: () {
                      setState(() {
                        _titleIsEditing = true;
                      });
                    },
                    onTapOutside: (event) {
                      setState(() {
                        _titleIsEditing = false;
                        _titleFocusNode.unfocus();
                      });
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 4.4,
                      ),
                      border: _titleIsEditing
                          ? const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            )
                          : InputBorder.none,
                    )),
              ),
              subtitle: GestureDetector(
                onTap: _isSelected
                    ? () {
                        showDatePicker(
                                context: context,
                                initialDate: widget.transaction.date,
                                firstDate: DateTime(1900),
                                lastDate: DateTime(3000))
                            .then((date) {
                          if (date != null) {
                            setState(() {
                              widget.transaction.date = date;
                            });
                          }
                        });
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(widget.transaction.date.format("yyyy-MM-dd")),
                ),
              ),
              trailing: SizedBox(
                width: 75,
                child: Focus(
                  onFocusChange: (value) {
                    if (value == false) {
                      setState(() {
                        var changed = _amountController.text;
                        if (double.tryParse(changed) != null) {
                          if (widget.transaction.categoryType == null) {
                            widget.transaction.amount = double.parse(changed);
                          } else if (widget.transaction.categoryType ==
                              'income') {
                            widget.transaction.amount = double.parse(changed);
                          } else {
                            widget.transaction.amount = -double.parse(changed);
                          }
                        }
                        updateAmountController();
                        _amountIsEditing = false;
                      });
                    }
                  },
                  child: TextField(
                    enabled: _isSelected,
                    maxLines: 1,
                    keyboardType: TextInputType.number,
                    focusNode: _amountFocusNode,
                    controller: _amountController,
                    textAlign: TextAlign.end,
                    onSubmitted: (changed) {
                      setState(() {
                        _amountIsEditing = false;
                        _amountFocusNode.unfocus();
                      });
                    },
                    onTap: () {
                      setState(() {
                        _amountIsEditing = true;
                      });
                    },
                    onTapOutside: (event) {
                      setState(() {
                        _amountIsEditing = false;
                        _amountFocusNode.unfocus();
                      });
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 4.4,
                      ),
                      border: _amountIsEditing
                          ? const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(0)),
                            )
                          : InputBorder.none,
                    ),
                    style: _amountIsEditing
                        ? const TextStyle(color: Colors.black)
                        : () {
                            if (widget.transaction.categoryType == null) {
                              return widget.transaction.amount < 0
                                  ? const TextStyle(color: Colors.red)
                                  : const TextStyle(color: Colors.green);
                            } else if (widget.transaction.categoryType ==
                                'income') {
                              return const TextStyle(color: Colors.green);
                            } else {
                              return const TextStyle(color: Colors.red);
                            }
                          }(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
