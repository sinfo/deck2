import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EditBox extends StatelessWidget {
  final String title;
  final String body;
  EditBox({Key? key, required this.title, required this.body})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
      padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5)
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
              Divider(),     
              Text(body,
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 18, color: Colors.black))
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              Icons.edit,
              color: Color.fromRGBO(211, 211, 211, 1),
              size: 18),
          )]
      ),
    );
  }
}
