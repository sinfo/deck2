import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';

class DeckBanner extends StatelessWidget {
  final CompanyLight companyLight;
  DeckBanner({Key? key, required this.companyLight}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white24, Colors.indigo])),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          CircleAvatar(
            backgroundImage:
                NetworkImage(this.companyLight.companyImages.internal),
            minRadius: 50,
            maxRadius: 50,
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 10, 10),
              child: Column(
                children: [
                  Text(companyLight.name,
                      style: TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ],
              )),
        ],
      ),
    );
  }
}
