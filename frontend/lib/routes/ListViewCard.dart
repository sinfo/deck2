import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/UnknownScreen.dart';

class ListViewCard extends StatelessWidget {
  final Member? member;
  final CompanyLight? company;
  //Speaker? speaker;

  const ListViewCard({Key? key, this.member, this.company}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (member != null) {
      return InkWell(
          child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5)),
                    child: Image(
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                      image: (member!.image == '')
                          ? AssetImage("assets/noImage.png") as ImageProvider
                          : NetworkImage(member!.image),
                      //image: NetworkImage(member.image),
                    ),
                  ),
                  SizedBox(height: 12.5),
                  Text(member!.name!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        //fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                      )),
                  Text(
                    'Role',
                    textAlign: TextAlign.center,
                  ),
                ],
              )),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return UnknownScreen();
            } //MemberScreen(member: this.member)),
                ));
          });
    } else if (company != null) {
      return InkWell(
          child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5)),
                    child: Image(
                      width: 200,
                      height: 200,
                      fit: BoxFit.fill,
                      image: (company!.companyImages.internal == '')
                          ? AssetImage("assets/noImage.png") as ImageProvider
                          : NetworkImage(company!.companyImages.internal),
                    ),
                  ),
                  SizedBox(height: 12.5),
                  Text(company!.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        //fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                      )),
                  Text(
                    'Description',
                    textAlign: TextAlign.center,
                  ),
                ],
              )),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return UnknownScreen();
            } // CompanyScreen(company: this.company)),
                ));
          });
    } else {
      return UnknownScreen();
    }
  }
}
