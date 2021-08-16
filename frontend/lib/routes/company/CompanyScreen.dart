import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/routes/company/CompanyBanner.dart';
import 'package:frontend/routes/company/EditBox.dart';

class CompanyScreen extends StatefulWidget {
  final CompanyLight companyLight;
  CompanyScreen({Key? key, required this.companyLight}) : super(key: key);

  @override
  _CompanyScreen createState() => _CompanyScreen(companyLight: companyLight);
}

class _CompanyScreen extends State<CompanyScreen> {
  CompanyService companyService = new CompanyService();
  final CompanyLight companyLight;

  _CompanyScreen({Key? key, required this.companyLight});

  @override
  void initState() {
    super.initState();
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
      body: Container(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DeckBanner(companyLight: this.companyLight),
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
                                        color: Colors.indigo, width: 0.5))),
                            child: TabBarView(children: <Widget>[
                              Container(
                                child: displayDetails(),
                              ),
                              Container(
                                child: displayCommunication(),
                              ),
                              Container(
                                child: displayParticipations(),
                              ),
                              Container(
                                child: displayEmployees(),
                              ),
                              Container(
                                child: displayBilling(),
                              ),
                            ]))
                      ])),
            ]),
      ),
    );
  }

  Widget displayDetails() {
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

  Widget displayEmployees() {
    return Text('Employees',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
  }

  Widget displayBilling() {
    return Text('Billing',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
  }

  Widget displayParticipations() {
    return Text('Participations',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
  }

  Widget displayCommunication() {
    return Text('Communications',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
  }
}
