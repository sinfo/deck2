import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CompanyListWidget extends StatefulWidget {
  const CompanyListWidget({Key key}) : super(key: key);

  @override
  _CompanyListWidgetState createState() => _CompanyListWidgetState();
}

class _CompanyListWidgetState extends State<CompanyListWidget> {
  CompanyService companyService = new CompanyService();
  Future<List<CompanyLight>> companies;

  @override
  void initState() {
    super.initState();
    this.companies = companyService.getCompanies();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: this.companies,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<CompanyLight> comps = snapshot.data as List;
          return Column(
            children: comps
                .map((e) => CompanyCard(
                      company: e,
                    ))
                .toList(),
          );
        } else {
          return CircularProgressIndicator();
        }
      });
}

class CompanyCard extends StatelessWidget {
  final CompanyLight company;
  const CompanyCard({Key key, this.company}) : super(key: key);

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
