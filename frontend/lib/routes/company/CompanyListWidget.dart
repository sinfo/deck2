import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';

final double CARD_WIDTH = 200;

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
          List<Company> comps = snapshot.data as List<Company>;

          return Material(
              child: GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width ~/ CARD_WIDTH,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 0.75,
            children: comps
                .map((e) => CompanyCard(
                      company: e,
                    ))
                .toList(),
          ));
        } else {
          return CircularProgressIndicator();
        }
      });
}

class CompanyCard extends StatelessWidget {
  final Company company;
  const CompanyCard({Key? key, required this.company}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        /*Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CompanyScreen(company: this.company)),
        );*/
        debugPrint(this.company.name + " card tapped!");
      },
      child: Container(
        width: 200,
        height: 250,
        child: Column(children: <Widget>[
          Image.network(this.company.companyImages.internal,
              width: 200,
              height: 200, loadingBuilder: (context, child, progress) {
            return progress == null
                ? child
                : SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator());
          }, errorBuilder: (context, exception, stackTrace) {
            return Image.asset(
              'assets/noImage.png',
              width: 200,
              height: 200,
            );
          }),
          SizedBox(
            width: 200,
            height: 50,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xffF1F1F1)),
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                      child: Text(this.company.name,
                          style: TextStyle(fontWeight: FontWeight.bold)))))
          ),
        ]),
      ),
    );
  }
}
