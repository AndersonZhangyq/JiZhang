import 'package:flutter/widgets.dart';

class TextFieldWithFocus extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  TextFieldWithFocus({
    Key? key,
    required this.controller,
    required this.focusNode,
  }) : super(key: key);

  @override
  State<TextFieldWithFocus> createState() => _TextFieldWithFocusState();
}

class _TextFieldWithFocusState extends State<TextFieldWithFocus> {
  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        if (value == false) {
          setState(() {
            isEditing = false;
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
              isEditing = true;
            });
          },
          onTapOutside: (event) {
            setState(() {
              widget.transaction.title = _titleController.text;
              isEditing = false;
              _titleFocusNode.unfocus();
            });
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 4.4,
            ),
            border: isEditing
                ? const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(0)),
                  )
                : InputBorder.none,
          )),
    );
  }
}
