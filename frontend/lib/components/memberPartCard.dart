import 'package:flutter/material.dart';

final Map<String, String> roles = {
  "MEMBER": "Member",
  "TEAMLEADER": "Team Leader",
  "COORDINATOR": "Coordinator",
  "ADMIN": "Administrator"
};

class MemberPartCard extends StatelessWidget {
  final int event;
  final String role;
  final String team;
  final bool small;
  MemberPartCard(
      {Key? key, required this.event, required this.role, required this.team, required this.small})
      : super(key: key);

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
                Text(team,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(5)),
                  child: Padding(
                    padding: EdgeInsets.all(small ? 4.0 : 8.0),
                    child: Text(
                      "SINFO " + event.toString(),
                      style: TextStyle(fontSize: small ? 12 : 16),
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Theme.of(context).dividerColor,),
            Text(roles[role]!,
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 18))
          ],
        ),
      ]),
    );
  }
}
