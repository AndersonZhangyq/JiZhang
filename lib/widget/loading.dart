import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Loading...",
        style: TextStyle(
            color: Colors.grey[400], fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
