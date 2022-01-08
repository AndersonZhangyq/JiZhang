import 'package:flutter/material.dart';

class MoneyNumberTablet extends StatelessWidget {
  const MoneyNumberTablet(
      {Key? key, required this.moneyController, required this.callback})
      : super(key: key);

  final TextEditingController moneyController;

  final void Function(String text)? callback;

  void _onNumberTabletPressed(
      {int? number, bool isDot = false, bool isRemove = false}) {
    String ret = moneyController.text;
    if (isRemove) {
      ret = ret.substring(0, ret.length - 1);
    } else if (isDot) {
      ret = ret + ".";
    } else if (number != null) {
      ret = ret + number.toString();
    }
    // remove leading zero
    ret = ret.replaceFirst(RegExp('^0+'), '');
    // make sure only two number after dot
    // use '[0-9]+' to ensure that if tmp is Empty then set to "0"
    ret = RegExp("[0-9]+[.]?[0-9]{0,2}").stringMatch(ret) ?? "0";
    if (callback != null) {
      callback!(ret);
    }
  }

  @override
  Widget build(BuildContext context) {
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
