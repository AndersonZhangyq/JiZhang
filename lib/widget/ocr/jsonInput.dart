import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/widget/ocr/addTransactionsFromJSON.dart';

class JsonInputWidget extends StatefulWidget {
  const JsonInputWidget({super.key});

  @override
  _JsonInputWidgetState createState() => _JsonInputWidgetState();
}

class _JsonInputWidgetState extends State<JsonInputWidget> {
  TextEditingController _controller = TextEditingController();
  bool _showBatchAdd = false;

  // Toggles the visibility of the BatchAdd widget
  void _onTransformPressed() {
    try {
      if (_controller.text.trim().isEmpty) {
        throw Exception(
            AppLocalizations.of(context)!.jsonInput_InvalidJSONEmpty);
      }
      dynamic ret = jsonDecode(_controller.text);
      if (ret is! List) {
        throw Exception(
            AppLocalizations.of(context)!.jsonInput_InvalidJSONNotAList);
      }
      for (var item in ret) {
        if (item['bill_name'] == null ||
            item['bill_date'] == null ||
            item['bill_amount'] == null ||
            item['bill_refund'] == null ||
            item['bill_adjusted_amount'] == null) {
          throw Exception(AppLocalizations.of(context)!
              .jsonInput_InvalidJSONMissingRequired);
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AddTransactionsFromJSON(
                  jsonString: _controller.text,
                )),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${AppLocalizations.of(context)!.jsonInput_InvalidJSON}, ${e.toString()}'),
      ));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.jsonInput_Title),
      ),
      body: SingleChildScrollView(
        // Make the entire body scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Multi-line TextField
              TextField(
                textAlignVertical: TextAlignVertical.top,
                controller: _controller,
                maxLines: 10, // Set maximum lines to 10
                minLines: 10, // Ensure it has a minimum height of 10 line
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)!.jsonInput_EnterJSONHint,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20), // Spacing between input field and button

              // Transform Button
              ElevatedButton(
                onPressed: _onTransformPressed,
                child: Text(AppLocalizations.of(context)!
                    .jsonInput_GenerateTransactions),
              ),
              SizedBox(
                  height: 20), // Spacing between button and BatchAdd widget
            ],
          ),
        ),
      ),
    );
  }
}
