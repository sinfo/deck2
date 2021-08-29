import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';

/**
 * TODO: Remove later.
 * Temporary widget for testing purposes only
 */

class CompanyListWidget extends StatefulWidget {
  const CompanyListWidget({Key? key}) : super(key: key);

  @override
  _CompanyListWidgetState createState() => _CompanyListWidgetState();
}

class _CompanyListWidgetState extends State<CompanyListWidget> {
  CompanyService companyService = new CompanyService();
  late Future<List<Company>> companies;

  @override
  void initState() {
    super.initState();
    this.companies = companyService.getCompanies();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: companies,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<CompanyLight> comps = snapshot.data as List<CompanyLight>;

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
