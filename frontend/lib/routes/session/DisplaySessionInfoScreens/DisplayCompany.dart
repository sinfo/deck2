import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/company/CompanyScreen.dart';
import 'package:frontend/services/companyService.dart';

class DisplayCompany extends StatefulWidget {
  final Session session;
  const DisplayCompany({Key? key, required this.session}) : super(key: key);

  @override
  _DisplayCompanyState createState() => _DisplayCompanyState();
}

class _DisplayCompanyState extends State<DisplayCompany> {
  CompanyService companyService = new CompanyService();
  String companyName = "not filled yet";
  Company? company;
  CompanyImages? companyImage;
  String? companySite = "";

  @override
  void initState() {
    super.initState();
    _getCompanies(widget.session.companyId);
  }

  Future<String> _getCompanies(String? id) async {
    Future<Company?> companyFuture = companyService.getCompany(id: id!);
    company = await companyFuture;
    setState(() {
      companyName = company!.name;
      companyImage = company!.companyImages;
      companySite = company!.site;
    });
    return companyName;
  }

  @override
  Widget build(BuildContext context) {
    if (companyName != "not filled yet") {
      return Scaffold(
        backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
        body: new ListView(
          padding: EdgeInsets.symmetric(horizontal: 32),
          physics: BouncingScrollPhysics(),
          children: [
            Container(
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
                  ]),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CompanyScreen(
                                company: company!,
                              )));
                },
                title: Text(companyName,
                    textAlign: TextAlign.left, style: TextStyle(fontSize: 18)),
                subtitle: Text(companySite!),
                leading: CircleAvatar(
                  radius: 26.0,
                  foregroundImage: NetworkImage(
                    companyImage!.internal,
                  ),
                  backgroundImage: AssetImage('assets/noImage.png'),
                ),
              ),
            )
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Container(
              height: 40,
              width: 40,
              margin: EdgeInsets.all(5),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }
  }
}
