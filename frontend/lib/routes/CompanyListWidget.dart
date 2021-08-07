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
  static const int CARD_WIDTH = 200;

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

          return GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width ~/ CARD_WIDTH,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: const EdgeInsets.all(20),
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
    return Card(
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () {
          debugPrint(this.company.name + " card tapped!");
        },
        child: Column(
          children: <Widget>[
            Image.network(this.company.companyImages.internal,
                loadingBuilder: (context, child, progress) {
              return progress == null ? child : CircularProgressIndicator();
            }, width: 95, height: 95),
            Text(this.company.name,
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
