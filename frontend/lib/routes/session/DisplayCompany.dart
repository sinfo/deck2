import 'package:flutter/material.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/company/CompanyScreen.dart';
import 'package:frontend/routes/member/EditContact.dart';
import 'package:frontend/routes/session/SessionInformationBox.dart';
import 'package:frontend/routes/speaker/SpeakerScreen.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';

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
    print("Company name: " + companyName);
    // speakersNames = _getSpeakers(widget.session.speakersIds);
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
    return Scaffold(
      backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
      body: new ListView(
        padding: EdgeInsets.symmetric(horizontal: 32),
        physics: BouncingScrollPhysics(),
        children: [
          ListTile(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CompanyScreen(
                            company: company!,
                          )));
            },
            title: Text(companyName,
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 18, color: Colors.black)),
            subtitle: Text(companySite!),
            leading: CircleAvatar(
              radius: 26.0,
              foregroundImage: NetworkImage(
                companyImage!.internal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
