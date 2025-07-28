import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:excel/excel.dart';
import 'package:ji_zhang/widget/ocr/addTransactionsFromBillFile.dart';
import 'dart:convert';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ExtractedTransaction {
  String billName;
  String billExtraInfo;
  DateTime billDate;
  double billAmount;
  double billRefund;
  bool isExpense;
  String? billTransactionId;
  String? billRefundTransactionId;

  ExtractedTransaction({
    required this.billName,
    required this.billExtraInfo,
    required this.billDate,
    required this.billAmount,
    required this.billRefund,
    required this.isExpense,
    this.billTransactionId,
    this.billRefundTransactionId,
  });

  String toString() {
    return 'ExtractedTransaction(billName: $billName, billExtraInfo: $billExtraInfo, billDate: $billDate, billAmount: $billAmount, billRefund: $billRefund, isExpense: $isExpense)';
  }
}

class BillImportWidget extends StatefulWidget {
  const BillImportWidget({super.key});

  @override
  State<BillImportWidget> createState() => _BillImportWidgetState();
}

class _BillImportWidgetState extends State<BillImportWidget> {
  String? _filePath;
  ValueNotifier<List<bool>> _isSelectedNotifier = ValueNotifier([false, false]);
  List<ExtractedTransaction> _extractedTransactions = [];

  Future<void> _readAliPayXlsxFile(String filePath) async {
    final amountRegex = RegExp(r'[-+]?\d+(\.\d+)?');
    try {
      final data = gbk_bytes.decode(await File(filePath).readAsBytes());
      // parse info from csv
      List<String> lines = data.split(RegExp(r'\r\n|\r|\n'));
      Map<String, int> transctionIdIndex = {};
      List<String> filterKeywords = ['支付宝小荷包-自动攒'];
      for (var line in lines) {
        print(line);
        List<String> columns =
            line.split(',').map((item) => item.trim()).toList();
        if (columns.length < 12) continue; // Ensure there are enough columns
        // 0 交易时间, 1 交易分类, 2 交易对方, 3 对方账号, 4 商品说明, 5 收/支
        // 6 金额, 7 收/付款方式, 8 交易状态, 9 交易订单号, 10 商家订单号, 11 备注
        String itemInstrument = columns[4];
        if (filterKeywords.any((keyword) => itemInstrument.contains(keyword))) {
          print('Skipping item: $itemInstrument');
          continue; // Skip items containing filter keywords
        }
        double billAmount = 0;
        double billRefund = 0;
        String billType = columns[5];
        String transactionId = columns[9];
        String? refundTransactionId;
        bool isExpense = true;
        DateTime? billDate = DateTime.tryParse(columns[0].trim());
        if (billDate == null) continue; // Skip if date is invalid

        if (columns[6].trim().isNotEmpty &&
            amountRegex.hasMatch(columns[6].trim())) {
          billAmount = double.parse(
              amountRegex.firstMatch(columns[6].trim())!.group(0)!);
        }
        if (billType == '支出') {
        } else if (billType == '收入') {
          isExpense = false;
        } else {
          if (itemInstrument.contains('退款')) {
            billRefund = billAmount;
            billAmount = 0; // If it's a refund, set amount to 0
            refundTransactionId = transactionId.split('_')[0];
          } else {
            continue; // Skip if not income or expense
          }
        }
        if (transctionIdIndex.containsKey(transactionId)) {
          print('Transaction ID $transactionId already exists, updating info.');
          _extractedTransactions[transctionIdIndex[transactionId]!].billAmount =
              billAmount;
          _extractedTransactions[transctionIdIndex[transactionId]!].billName =
              itemInstrument;
          _extractedTransactions[transctionIdIndex[transactionId]!]
              .billExtraInfo = columns[2].trim();
          _extractedTransactions[transctionIdIndex[transactionId]!].billDate =
              billDate;
          continue;
        }

        ExtractedTransaction transaction = ExtractedTransaction(
          billName: itemInstrument,
          billExtraInfo: columns[2].trim(),
          billDate: billDate,
          billAmount: billAmount,
          billRefund: billRefund,
          isExpense: isExpense,
          billTransactionId: transactionId,
          billRefundTransactionId: refundTransactionId,
        );
        _extractedTransactions.add(transaction);
        if (refundTransactionId == null) {
          transctionIdIndex[transactionId] = _extractedTransactions.length - 1;
        } else {
          transctionIdIndex[refundTransactionId!] =
              _extractedTransactions.length - 1;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${AppLocalizations.of(context)!.billImport_InvalidData}, ${e.toString()}'),
      ));
    }
  }

  Future<void> _readWechatXlsxFile(String filePath) async {
    final amountRegex = RegExp(r'[-+]?\d+(\.\d+)?');
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      for (var table in excel.tables.keys) {
        print('Sheet: $table');
        for (var row in excel.tables[table]!.rows) {
          print(row.map((cell) => cell?.value).toList());
          // 遇到第一个正确日期，开始处理
          if (row.isNotEmpty &&
              row[0] != null &&
              row[0]!.value != null &&
              DateTime.tryParse(row[0]!.value.toString()) != null) {
            // print('Found date in sheet $table: ${row[0]?.value}');
            double billAmount = 0;
            double billRefund = 0;
            if (row[5]?.value != null &&
                amountRegex.hasMatch(row[5]!.value.toString())) {
              billAmount = double.parse(
                  amountRegex.firstMatch(row[5]!.value.toString())!.group(0)!);
            }
            if (row[7]?.value != null &&
                row[7]!.value.toString().contains('退款') &&
                amountRegex.hasMatch(row[7]!.value.toString())) {
              billRefund = double.parse(
                  amountRegex.firstMatch(row[7]!.value.toString())!.group(0)!);
            }
            ExtractedTransaction transaction = ExtractedTransaction(
              billName: row[2]?.value?.toString() ?? '',
              billExtraInfo: row[3]?.value?.toString() ?? '',
              billDate: DateTime.parse(row[0]!.value.toString()),
              billAmount: billAmount,
              billRefund: billRefund,
              isExpense: row[4]?.value?.toString() == '支出',
            );
            print(transaction.toString());
            _extractedTransactions.add(transaction);
          }
        }
        break; // 只读取第一个表格
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${AppLocalizations.of(context)!.billImport_InvalidData}, ${e.toString()}'),
      ));
    }
  }

  Future<void> _pickXlsxFile(String platform) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );
    if (result != null &&
        result.files.isNotEmpty &&
        result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
        _isSelectedNotifier.value = [false, false];
      });
      _extractedTransactions.clear();
      switch (platform) {
        case 'wechat':
          await _readWechatXlsxFile(_filePath!);
          break;
        case 'zhifubao':
          await _readAliPayXlsxFile(_filePath!);
          break;
      }
    }
  }

  void _navigateToNewPage() {
    if (_filePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTransactionsFromBillFile(
            extractedTransactions: _extractedTransactions,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(AppLocalizations.of(context)!.billImport_Title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  _pickXlsxFile("wechat");
                },
                child: Text(AppLocalizations.of(context)!
                    .billImport_ChooseWeChatBillFile),
              ),
              ElevatedButton(
                onPressed: () {
                  _pickXlsxFile("zhifubao");
                },
                child: Text(AppLocalizations.of(context)!
                    .billImport_ChooseAliPayBillFile),
              ),
              if (_filePath != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${AppLocalizations.of(context)!.billImport_ChosenFilePath}'),
                      SizedBox(
                        height: 8,
                      ),
                      Text('${_filePath!}'),
                    ],
                  ),
                ),
              if (_filePath != null)
                TextButton(
                  child: Text(AppLocalizations.of(context)!
                      .billImport_GenerateTransactions),
                  onPressed: _navigateToNewPage,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
