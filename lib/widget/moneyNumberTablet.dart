import 'package:flutter/material.dart';

class MoneyNumberTablet extends StatefulWidget {
  MoneyNumberTablet(
      {Key? key, required this.moneyController, required this.callback})
      : super(key: key);

  final TextEditingController moneyController;

  final void Function(String text)? callback;

  @override
  State<MoneyNumberTablet> createState() => _MoneyNumberTabletState();
}

class _MoneyNumberTabletState extends State<MoneyNumberTablet> {
  int symbolCounter = 0;

  void _onNumberTabletPressed(
      {int? number,
      bool isDot = false,
      bool isRemove = false,
      bool isAdd = false,
      bool isEqual = false,
      bool isSubstract = false}) {
    String ret = widget.moneyController.text;
    if (isAdd || isSubstract) {
      if (ret.isEmpty) {
        ret = "0";
      } else if (ret.characters.last != '+' && ret.characters.last != '-') {
        ret = ret + (isAdd ? "+" : "-");
        symbolCounter++;
      }
      if (widget.callback != null) {
        widget.callback!(ret);
      }
      return;
    }
    if (isEqual) {
      if (ret.isEmpty) {
        ret = "0";
      } else if (symbolCounter != 0) {
        // analyze the expression and calculate the result
        // remove tailing '+' or '-'
        if (ret.characters.last == '+' || ret.characters.last == '-') {
          ret = ret.substring(0, ret.length - 1);
          symbolCounter--;
        }
        var parts = ret.split(RegExp(r'[+|-]'));
        var result = double.parse(parts.first);
        int currentIndex = parts[0].length;
        for (var i = 1; i < parts.length; i++) {
          if (currentIndex < ret.length) {
            if (ret[currentIndex] == '+') {
              result += double.parse(parts[i]);
            } else if (ret[currentIndex] == '-') {
              result -= double.parse(parts[i]);
            }
            currentIndex = currentIndex + parts[i].length + 1;
          }
        }
        ret = result.toString();
        symbolCounter = 0;
      }
      if (widget.callback != null) {
        widget.callback!(ret);
      }
      return;
    }
    if (isRemove) {
      if (ret[ret.length - 1] == '+' || ret[ret.length - 1] == '-') {
        symbolCounter--;
      }
      ret = ret.substring(0, ret.length - 1);
    } else if (isDot) {
      ret = ret + ".";
    } else if (number != null) {
      ret = ret + number.toString();
    }
    // remove leading zero
    // ret = ret.replaceFirst(RegExp('^0+'), '');
    // make sure only two number after dot
    // use '[0-9]+' to ensure that if tmp is Empty then set to "0"
    var numberPattern = RegExp("[0-9]+[.]?[0-9]{0,2}");
    if (symbolCounter == 0) {
      ret = RegExp("[0-9]+[.]?[0-9]{0,2}").stringMatch(ret) ?? "0";
    } else {
      var parts = ret.split(RegExp(r'[+|-]'));
      var matched = numberPattern.stringMatch(parts.last);
      if (matched == null ||
          matched.isEmpty ||
          matched.length != parts.last.length) {
        ret = ret.substring(0, ret.length - 1);
      }
    }
    if (widget.callback != null) {
      widget.callback!(ret);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(4),
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 4 / 2.5,
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      children: <Widget>[
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontSize: 18),
            backgroundColor: Colors.white,
          ),
          child: const Text('1'),
          onPressed: () {
            _onNumberTabletPressed(number: 1);
          },
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontSize: 18),
            backgroundColor: Colors.white,
          ),
          child: const Text('2'),
          onPressed: () {
            _onNumberTabletPressed(number: 2);
          },
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontSize: 18),
            backgroundColor: Colors.white,
          ),
          child: const Text('3'),
          onPressed: () {
            _onNumberTabletPressed(number: 3);
          },
        ),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: Colors.white,
            ),
            child: const Icon(
              Icons.backspace,
              color: Colors.red,
            ),
            onPressed: () {
              _onNumberTabletPressed(isRemove: true);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: Colors.white,
            ),
            child: const Text('4'),
            onPressed: () {
              _onNumberTabletPressed(number: 4);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: Colors.white,
            ),
            child: const Text('5'),
            onPressed: () {
              _onNumberTabletPressed(number: 5);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: Colors.white,
            ),
            child: const Text('6'),
            onPressed: () {
              _onNumberTabletPressed(number: 6);
            }),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontSize: 18),
            backgroundColor: Colors.white,
          ),
          child: const Text('+'),
          onPressed: () {
            _onNumberTabletPressed(isAdd: true);
          },
        ),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: Colors.white,
            ),
            child: const Text('7'),
            onPressed: () {
              _onNumberTabletPressed(number: 7);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: Colors.white,
            ),
            child: const Text('8'),
            onPressed: () {
              _onNumberTabletPressed(number: 8);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: Colors.white,
            ),
            child: const Text('9'),
            onPressed: () {
              _onNumberTabletPressed(number: 9);
            }),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontSize: 18),
            backgroundColor: Colors.white,
          ),
          child: const Text('-'),
          onPressed: () {
            _onNumberTabletPressed(isSubstract: true);
          },
        ),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: Colors.white,
            ),
            child: const Text('.'),
            onPressed: () {
              _onNumberTabletPressed(isDot: true);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: Colors.white,
            ),
            child: const Text('0'),
            onPressed: () {
              _onNumberTabletPressed(number: 0);
            }),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: Colors.white,
            ),
            child: const Text(''),
            onPressed: null),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontSize: 18),
            backgroundColor: Colors.white,
          ),
          child: const Text('='),
          onPressed: () {
            _onNumberTabletPressed(isEqual: true);
          },
        ),
      ],
    );
  }
}
