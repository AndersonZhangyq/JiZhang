import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/category/categorySelector.dart';
import 'package:ji_zhang/widget/ocr/textRecognition.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image/image.dart' as image;

class RecognizedTransaction {
  late String title;
  late double amount;
  late DateTime date;
  late Rect boundingBox;
  IconData? iconData;
  Color? color;
  int? categoryId;
  String? categoryType;

  RecognizedTransaction(RecognizedTextElement title,
      RecognizedTextElement amount, RecognizedTextElement date) {
    this.title = title.text;
    this.amount = amount.amount!;
    this.date = date.date!;
    boundingBox = amount.boundingBox;
    this.boundingBox = title.boundingBox
        .expandToInclude(amount.boundingBox)
        .expandToInclude(date.boundingBox);
    this.boundingBox = this.boundingBox.inflate(15);
  }
}

class BatchAddTransactions extends StatefulWidget {
  final List<RecognizedTextElement> recognizedTextElements;
  final Uint8List originalImageBytes;
  final String type;

  const BatchAddTransactions(
      {super.key,
      required this.recognizedTextElements,
      required this.originalImageBytes,
      required this.type});
  @override
  State<BatchAddTransactions> createState() => _BatchAddTransactionsState();
}

class _BatchAddTransactionsState extends State<BatchAddTransactions> {
  List<RecognizedTransaction> recognizedTransactions = [];
  List<bool> _selected = [];
  late MyDatabase db;
  late image.Image img;
  @override
  void initState() {
    super.initState();
    generateRecognizedTransactions();
    img = image.decodeImage(widget.originalImageBytes)!;
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
                                      : transaction.title)));
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
              child: ListView.builder(
                itemCount: recognizedTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = recognizedTransactions[index];
                  var croppedImage = image.copyCrop(img,
                      x: transaction.boundingBox.left.round(),
                      y: transaction.boundingBox.top.round(),
                      width: transaction.boundingBox.width.round(),
                      height: transaction.boundingBox.height.round());
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: TransactionListElment(
                        key: ValueKey(transaction.hashCode),
                        isSelected: _selected[index],
                        widget: widget,
                        transaction: transaction,
                        index: index,
                        imageBytes:
                            Uint8List.fromList(image.encodePng(croppedImage)),
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
    // sort the recognizedTextElements by their position in the image, from top to bottom, from left to right
    widget.recognizedTextElements.sort((a, b) {
      if (a.boundingBox.top < b.boundingBox.top) {
        return -1;
      } else if (a.boundingBox.top > b.boundingBox.top) {
        return 1;
      } else {
        if (a.boundingBox.left < b.boundingBox.left) {
          return -1;
        } else if (a.boundingBox.left > b.boundingBox.left) {
          return 1;
        } else {
          return 0;
        }
      }
    });
    for (int i = 0; i < widget.recognizedTextElements.length; i++) {
      final currentElement = widget.recognizedTextElements[i];
      if (currentElement.isAmount) {
        // look for the corresponding transaction title, should have similar height
        RecognizedTextElement? titleElement;
        for (int j = i - 1; j >= 0; j--) {
          final candidateTitleElement = widget.recognizedTextElements[j];
          final heightDiff = (candidateTitleElement.boundingBox.top -
                  currentElement.boundingBox.top)
              .abs();
          if (heightDiff > 20) {
            break;
          }
          if (candidateTitleElement.isAmount == false &&
              candidateTitleElement.isDate == false) {
            if (titleElement == null ||
                (candidateTitleElement.boundingBox.left >
                    titleElement.boundingBox.left)) {
              titleElement = candidateTitleElement;
            }
          }
        }
        for (int j = i + 1; j < widget.recognizedTextElements.length; j++) {
          final candidateTitleElement = widget.recognizedTextElements[j];
          final heightDiff = (candidateTitleElement.boundingBox.top -
                  currentElement.boundingBox.top)
              .abs();
          if (heightDiff > 20) {
            break;
          }
          if (candidateTitleElement.isAmount == false &&
              candidateTitleElement.isDate == false) {
            if (titleElement == null ||
                (candidateTitleElement.boundingBox.left >
                    titleElement.boundingBox.left)) {
              titleElement = candidateTitleElement;
            }
          }
        }
        if (titleElement == null) {
          continue;
        }
        // look for the corresponding transaction date, should have similar left position
        RecognizedTextElement? dateElement;
        for (int j = i + 1; j < widget.recognizedTextElements.length; j++) {
          final candidateDateElement = widget.recognizedTextElements[j];
          final heightDiff = (candidateDateElement.boundingBox.top -
                  titleElement.boundingBox.top)
              .abs();
          if (heightDiff > (widget.type == 'wechat' ? 100 : 200)) {
            break;
          }
          if (candidateDateElement.isDate) {
            dateElement = candidateDateElement;
            break;
          }
        }
        if (dateElement == null) {
          continue;
        }
        // print this candidate transaction
        print(
            'Transaction: ${titleElement.text}, Amount: ${currentElement.amount}, Date: ${dateElement.date!.format("MM-dd")}');
        recognizedTransactions.add(
            RecognizedTransaction(titleElement, currentElement, dateElement));
        _selected.add(true);
      }
    }
  }
}

class TransactionListElment extends StatefulWidget {
  const TransactionListElment({
    super.key,
    required this.widget,
    required this.transaction,
    required this.index,
    required this.onSelected,
    required this.isSelected,
    required this.imageBytes,
  });

  final Uint8List imageBytes;
  final BatchAddTransactions widget;
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
    _amountController.text = widget.transaction.amount > 0
        ? '+${widget.transaction.amount.toString()}'
        : widget.transaction.amount.toString();
  }

  void updateAmountController() {
    if (widget.transaction.categoryType != null) {
      if (widget.transaction.categoryType == 'income') {
        _amountController.text = '+${widget.transaction.amount.toString()}';
      } else {
        _amountController.text = '-${widget.transaction.amount.toString()}';
      }
    } else {
      _amountController.text = widget.transaction.amount > 0
          ? '+${widget.transaction.amount.toString()}'
          : widget.transaction.amount.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Opacity(
        opacity: _isSelected ? 1 : 0.3,
        child: Column(
          children: [
            Image.memory(widget.imageBytes),
            // _isSelected ? Image.memory(widget.imageBytes) : Container(),
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
                        widget.transaction.title = changed;
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
                        _amountIsEditing = false;
                        var changed = _amountController.text;
                        if (double.tryParse(changed) != null) {
                          if (widget.transaction.categoryType == null) {
                            if (widget.transaction.amount < 0) {
                              widget.transaction.amount =
                                  -double.parse(changed);
                            } else {
                              widget.transaction.amount = double.parse(changed);
                            }
                          } else if (widget.transaction.categoryType ==
                              'income') {
                            widget.transaction.amount = double.parse(changed);
                          } else {
                            widget.transaction.amount = -double.parse(changed);
                          }
                        }
                        updateAmountController();
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
                        _amountController.text =
                            widget.transaction.amount.abs().toString();
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
