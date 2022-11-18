import 'dart:ui';

import 'package:flutter/material.dart';

class EditableCard extends StatefulWidget {
  ///The title displayed at the top of the card
  final String title;

  ///A function to be called when the user performs an edit to the body of the card
  ///
  ///Use this function to call services and perform whatever actions necessary to edit the values in the backend.
  ///This function does not need to call setState(), as far as this widget is concerned.
  ///
  ///The function will recieve a [String] that corresponds to the new contents of the box.
  ///It should return a [Future] that only completes when
  ///all the assynchronous actions are completed
  ///(if multiple services are called use [Future.wait])
  final Future<dynamic> Function(String) bodyEditedCallback;

  ///The initial text to be placed inside the card
  final String body;

  ///A value of [TextInputType] that will determine what kind of text will be displayed in the card
  ///
  ///This value will aid in the user input when editing the card
  final TextInputType textInputType;

  ///Determines whether the input box will be just a single line.
  ///If set to false the input will be equivalent to a Text Area
  ///
  ///Material design guidelines recommend single line inputs when possible
  final bool isSingleline;

  ///A Card-like widget that consists of a title and a body, and that can be edited
  EditableCard({
    Key? key,
    required this.title,
    required this.body,
    required this.bodyEditedCallback,
    this.textInputType = TextInputType.text,
    this.isSingleline = true,
  }) : super(key: key);

  @override
  _EditableCardState createState() => _EditableCardState();
}

class _EditableCardState extends State<EditableCard> {
  TextEditingController _textFieldController = TextEditingController();
  bool _isEditing = false;
  bool _isWaiting = false;
  late String _body;

  @override
  void initState() {
    super.initState();
    _body = widget.body;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
      padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(5)),
      child: Stack(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Divider(
              color: Colors.grey[600],
            ),
            AnimatedCrossFade(
              firstChild: SelectableText(
                _body,
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 18),
              ),
              secondChild: Column(
                children: [
                  Stack(
                    children: <Widget>[
                          TextField(
                            controller: _textFieldController,
                            keyboardType: widget.textInputType,
                            textInputAction: widget.isSingleline
                                ? TextInputAction.done
                                : TextInputAction.newline,
                            maxLines: widget.isSingleline ? 1 : 8,
                            minLines: widget.isSingleline ? 1 : 8,
                          ),
                        ] +
                        (_isWaiting
                            ? [
                                BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: CircularProgressIndicator(),
                                )
                              ]
                            : []),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text('Submit'),
                        onPressed: () {
                          widget
                              .bodyEditedCallback(_textFieldController.text)
                              .then((value) {
                            setState(() {
                              _isEditing = false;
                              _isWaiting = false;
                            });
                          });
                          _isWaiting = true;
                          _body = _textFieldController.text;
                        },
                      ),
                    ],
                  )
                ],
              ),
              crossFadeState: !_isEditing
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: Duration(milliseconds: 250),
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeOut,
              sizeCurve: Curves.easeOut,
            ),
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              icon: !_isEditing ? Icon(Icons.edit) : Icon(Icons.cancel),
              color:
                  !_isEditing ? Color.fromRGBO(211, 211, 211, 1) : Colors.red,
              iconSize: 18,
              onPressed: () {
                !_isEditing
                    ? _textFieldController.text = _body
                    : _textFieldController.clear();
                setState(() {
                  _isEditing = !_isEditing;
                });
              }),
        )
      ]),
    );
  }
}
