import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/routes/company/CompanyBanner.dart';
import 'package:frontend/routes/company/EditBox.dart';

class CompanyScreen extends StatefulWidget {
  final String companyId;
  CompanyScreen({Key? key, required this.companyId}) : super(key: key);

  @override
  _CompanyScreen createState() => _CompanyScreen(companyId: companyId);
}

class _CompanyScreen extends State<CompanyScreen> {
  CompanyService companyService = new CompanyService();
  late Future<Company?> company;
  final String companyId;

  _CompanyScreen({Key? key, required this.companyId});

  @override
  void initState() {
    super.initState();
    company = companyService.getCompany(id: companyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: GestureDetector(
              child: Image.asset(
            'assets/logo-branco2.png',
            height: 100,
            width: 100,
          )),
        ),
        body: FutureBuilder(
            future: company,
            builder: (context, snapshot) {
              print(snapshot.hasData);
              if (snapshot.hasData) {
                Company? cmp = snapshot.data as Company?;
                if (cmp == null) {
                  return Text("No such company");
                }
                return Container(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                      DeckBanner(cmp: cmp),
                      DefaultTabController(
                          length: 5, // length of tabs
                          initialIndex: 0,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Container(
                                  child: TabBar(
                                    labelColor: Colors.indigo,
                                    unselectedLabelColor: Colors.black,
                                    tabs: [
                                      Tab(text: 'Details'),
                                      Tab(text: 'Communications'),
                                      Tab(text: 'Participations'),
                                      Tab(text: 'Employees'),
                                      Tab(text: 'Billing'),
                                    ],
                                  ),
                                ),
                                Container(
                                    height: 500, //height of TabBarView
                                    decoration: BoxDecoration(
                                        border: Border(
                                            top: BorderSide(
                                                color: Colors.indigo,
                                                width: 0.5))),
                                    child: TabBarView(children: <Widget>[
                                      Container(
                                        child: displayDetails(cmp),
                                      ),
                                      Container(
                                        child: displayCommunication(cmp),
                                      ),
                                      Container(
                                        child: displayParticipations(cmp),
                                      ),
                                      Container(
                                        child: displayEmployees(cmp),
                                      ),
                                      Container(
                                        child: displayBilling(cmp),
                                      ),
                                    ]))
                              ])),
                    ]));
              } else {
                return Text("Loading...");
              }
            }));

    /*
    
    
    
    */
  }

  Widget displayDetails(Company cmp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditBox(
            title: "Description",
            body: "Talkdesk is an enterprise cloud contact center platform that helps IBM, Shopify and 1,400" +
                "other enterprises improve customer satisfaction and agent productivity. Talkdesk empowers companies" +
                "to continuously improve customer experience. It is easy to set up, use and adapt. A “visionary” in Gartner’s" +
                " Contact Center as a Service Magic Quadrant, Talkdesk offers ongoing innovation, superior call quality and instant" +
                " integration to the most popular business applications."),
        EditBox(title: "Site", body: "https://www.talkdesk.com/"),
        EditBox(title: "Notes", body: "")
      ],
    );
  }

  Widget displayEmployees(Company cmp) {
    if(cmp.employers==null){
      return Text("No employers information");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cmp.employers!.map((e) => EditBox(title: "", body: e)).toList(),
    );
  }

  Widget displayBilling(Company cmp) {
    return Text('Billing',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
  }

  Widget displayParticipations(Company cmp) {
    if(cmp.participations==null){
      return Text("No participations information");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cmp.participations!.map((p) => EditBox(title: "SINFO ${p.event}", body: p.member!)).toList(),
    );
  }

  Widget displayCommunication(Company cmp) {
    return Text('Communications',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
  }
}
