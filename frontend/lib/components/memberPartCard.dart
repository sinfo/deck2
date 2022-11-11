import 'dart:html';

import 'package:flutter/material.dart';
import 'package:frontend/services/authService.dart';
import 'package:provider/provider.dart'; 

final Map<String, String> roles = {
  "MEMBER": "Member",
  "TEAMLEADER": "Team Leader",
  "COORDINATOR": "Coordinator",
  "ADMIN": "Administrator"
};

class MemberPartCard extends StatefulWidget{
  final int event;
  final String cardRole, myRole;
  final String team;
  final bool small;
  final bool canEdit;

  final Function(String role) onChanged;

  MemberPartCard(
      {Key? key, required this.event, required this.cardRole, required this.myRole, required this.team, required this.small, required this.canEdit, required this.onChanged})
      : super(key: key);

  @override
  _MemberPartCardState createState() => _MemberPartCardState();
}

class _MemberPartCardState extends State<MemberPartCard> {
  late String cardRole, tmpRole;
  late String myRole;
  late bool _isEditingMode;

  List<DropdownMenuItem<String>> roleNames = 
        roles.entries.map((entry) => DropdownMenuItem(child: Text(entry.value), value: entry.key)).toList();

  @override
  void initState() {
    super.initState();
    this.cardRole= widget.cardRole;
    this.tmpRole= widget.cardRole;
    this.myRole = widget.myRole;
    this._isEditingMode = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
      padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
              blurRadius: 7.0,
              color: Colors.grey.withOpacity(0.3),
              offset: new Offset(0, 3),
              spreadRadius: 4.0),
        ],
      ),
      child: Stack(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.team,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(5)),
                  child: Padding(
                    padding: EdgeInsets.all(widget.small ? 4.0 : 8.0),
                    child: Text(
                      "SINFO " + widget.event.toString(),
                      style: TextStyle(fontSize: widget.small ? 12 : 16),
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Theme.of(context).dividerColor,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                roleWidget,
                Visibility(
                  visible: widget.canEdit,
                  child: tralingButton
                )
              ],
            ),
          ],
        ),
      ]),
    );
  }

  Widget get roleWidget {
    if (_isEditingMode) {
      
      if(myRole=="COORDINATOR"){
        roleNames.removeWhere((option) => option.value == "ADMIN");
      }

      return DropdownButton(
        items: roleNames,
        value: cardRole,
        hint: new Text ("Select a Role"),
        onChanged: (value) => setState((){
          cardRole = value.toString();
        }),
      );
    } else
      return Text(roles[cardRole]!,
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 18));
  }

  Widget get tralingButton {
    if (_isEditingMode) {
      return IconButton(
        icon: Icon(Icons.check),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(),
        iconSize: 20,
        onPressed: saveChange,
      );
    } else
      return IconButton(
        icon: Icon(Icons.edit),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(),
        iconSize: 20,
        onPressed: _toggleMode,
      );
  }

  void _toggleMode() {
    setState(() {
      _isEditingMode = !_isEditingMode;
    });
  }

  void saveChange() {
    _toggleMode();
    if(this.tmpRole!=this.cardRole){
      widget.onChanged(this.cardRole);
      this.tmpRole=this.cardRole;
    }
  }

}
