import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';

class CompanyListWidget extends StatefulWidget {
  const CompanyListWidget({Key? key}) : super(key: key);

  @override
  _CompanyListWidgetState createState() => _CompanyListWidgetState();
}

class _CompanyListWidgetState extends State<CompanyListWidget> {
  CompanyService companyService = new CompanyService();
  late Future<List<CompanyLight>> companies;

  @override
  void initState() {
    super.initState();
    this.companies = companyService.getCompanies();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: companies,
      builder: (context, snapshot) {
        print(snapshot.hasData);
        if (snapshot.hasData) {
          List<CompanyLight> comps = snapshot.data as List<CompanyLight>;

          return Column(
            children: <Widget>[
              Column(
                children: <Widget>[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: rowChips(),
                  )
                ],
              ),
              Column(
                children: comps
                    .map((e) => CompanyCard(
                          company: e,
                        ))
                    .toList(),
              ),
            ],
          );
        } else {
          return CircularProgressIndicator();
        }
      });
}

rowChips() {
  return Row(
    children: <Widget>[
      createChip("Suggestion", Colors.orange),
      createChip("Contacted", Colors.yellow),
      createChip("Rejected", Colors.red),
      createChip("Give Up", Colors.black),
      createChip("Announced", Colors.green),
      createChip("In Conversations", Colors.blue),
      createChip("In Negotiations", Colors.blueGrey),
    ],
  );
}

Widget createChip(String label, Color color) {
  return Container(
    margin: EdgeInsets.all(6.0),
    child: Chip(
      labelPadding: EdgeInsets.all(5.0),
      //avatar: CircleAvatar(
      //  backgroundColor: Colors.grey.shade600,
      //  child: Text(label[0].toUpperCase()),
      //),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      elevation: 6.0,
      shadowColor: Colors.grey[60],
      padding: EdgeInsets.all(6.0),
    ),
  );
}

class CompanyCard extends StatelessWidget {
  final CompanyLight company;
  const CompanyCard({Key? key, required this.company}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    NetworkImage(this.company.companyImages.internal),
              ),
              title: Text(this.company.name),
            ),
          ],
        ),
      ),
    );
  }
}
