import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/member.dart';

class MemberBanner extends StatelessWidget {
  final Member member;
  final String role;
  MemberBanner({Key? key, required this.member, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/banner_background.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          SizedBox(height: 30),
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30),
            ),
            padding: const EdgeInsets.all(5),
            child: ClipOval(
              child: (member.image == '')
                  ? Image.asset("assets/noImage.png")
                  : Image.network(member.image!),
            ),
          ),
          SizedBox(height: 20),
          Text(member.name,
              style: TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text(role.toLowerCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              )),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
