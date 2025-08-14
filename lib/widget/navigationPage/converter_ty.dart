import 'package:flutter/material.dart';

class ConversionScreen extends StatefulWidget {
  const ConversionScreen({Key? key}) : super(key: key);
  @override
  _ConversionScreenState createState() => _ConversionScreenState();
}

class _ConversionScreenState extends State<ConversionScreen> {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController conversionRateController =
      TextEditingController();
  final TextEditingController startItemController = TextEditingController();
  final TextEditingController endItemController = TextEditingController();

  List<String> items = [];
  Map<String, double> conversionRates = {};
  String result = '';

  void addItem() {
    setState(() {
      if (itemController.text.isNotEmpty &&
          !items.contains(itemController.text)) {
        items.add(itemController.text);
      }
    });
  }

  void addConversionRate() {
    setState(() {
      if (conversionRateController.text.isNotEmpty) {
        try {
          var parts = conversionRateController.text.split(' ');
          if (parts.length == 3) {
            conversionRates['${parts[0]}_${parts[2]}'] = double.parse(parts[1]);
            conversionRates['${parts[2]}_${parts[0]}'] =
                1 / double.parse(parts[1]);
          }
        } catch (_) {}
      }
    });
  }

  void convert() {
    setState(() {
      result = '';
      var path = findPath(startItemController.text, endItemController.text);
      if (path != null) {
        var value = 1.0;
        for (int i = 0; i < path.length - 1; i++) {
          value *= conversionRates['${path[i]}_${path[i + 1]}']!;
          result += '${value.toStringAsFixed(2)} ${path[i + 1]}\n';
        }
      } else {
        result = 'No conversion path found!';
      }
    });
  }

  List<String>? findPath(String start, String end, [Set<String>? visited]) {
    visited ??= {};
    if (!visited.contains(start)) {
      visited.add(start);
      if (start == end) {
        return [start];
      }
      for (var item in items) {
        if (conversionRates.containsKey('${start}_item') &&
            !visited.contains(item)) {
          var path = findPath(item, end, visited);
          if (path != null) {
            return [start] + path;
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Converter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: itemController,
              decoration: InputDecoration(labelText: 'Add Item'),
            ),
            ElevatedButton(
              onPressed: addItem,
              child: Text('Add Item'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: conversionRateController,
              decoration: InputDecoration(
                  labelText: 'Add Conversion Rate (e.g., USD 1100 KRW)'),
            ),
            ElevatedButton(
              onPressed: addConversionRate,
              child: Text('Add Conversion Rate'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: startItemController,
              decoration: InputDecoration(labelText: 'Start Item'),
            ),
            TextField(
              controller: endItemController,
              decoration: InputDecoration(labelText: 'End Item'),
            ),
            ElevatedButton(
              onPressed: convert,
              child: Text('Convert'),
            ),
            SizedBox(height: 20),
            Text(result),
          ],
        ),
      ),
    );
  }
}
