import 'package:flutter/foundation.dart';
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

  Widget _buildSmallCard(BuildContext context) {
    return Container(
      height: 125,
      width: 100,
      margin: EdgeInsets.all(5),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.orange),
      ),
      child: Stack(
        children: [
          InkWell(
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5)),
                      child: Image.network(
                        company!.companyImages.internal,
                        fit: BoxFit.fill,
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return Image.asset(
                            'assets/noImage.png',
                            fit: BoxFit.fill,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(company!.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      )),
                  SizedBox(height: 6),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return UnknownScreen();
                } // CompanyScreen(company: this.company)),
                    ));
              }),
          Container(
            padding: EdgeInsets.all(4),
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Text(
              "STATUS",
              style: TextStyle(fontSize: 8),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBigCard(BuildContext context) {
    return Container(
      height: 175,
      width: 150,
      margin: EdgeInsets.all(10),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.orange),
      ),
      child: Stack(
        children: [
          InkWell(
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5)),
                      child: Image.network(
                        company!.companyImages.internal,
                        fit: BoxFit.fill,
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return Image.asset(
                            'assets/noImage.png',
                            fit: BoxFit.fill,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 12.5),
                  Text(company!.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        //fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                      )),
                  SizedBox(height: 12.5),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return UnknownScreen();
                } // CompanyScreen(company: this.company)),
                    ));
              }),
          Container(
            padding: EdgeInsets.all(8),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Text(
              "STATUS",
              style: TextStyle(fontSize: 14),
            ),
          )
        ],
      ),
    );
  }

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
      return LayoutBuilder(builder: (context, constraints) {
        MediaQueryData data = MediaQuery.of(context);
        if (data.orientation == Orientation.portrait ||
            data.size.width < 1500) {
          return _buildSmallCard(context);
        } else {
          return _buildBigCard(context);
        }
      });
    } else {
      return UnknownScreen();
    }
  }
}
