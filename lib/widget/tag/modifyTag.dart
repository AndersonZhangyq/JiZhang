import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ModifyTagWidget extends StatefulWidget {
  const ModifyTagWidget({Key? key}) : super(key: key);

  @override
  _ModifyTagState createState() => _ModifyTagState();
}

class _ModifyTagState extends State<ModifyTagWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(AppLocalizations.of(context)!.modifyTransaction_Title_add),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop(context);
          },
        ),
      ),
    );
  }
}
