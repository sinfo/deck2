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

          return Scaffold(
              body: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width ~/ CARD_WIDTH,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                children: comps
                    .map((e) => CompanyCard(
                          company: e,
                        ))
                    .toList(),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  debugPrint("Floating Action Button tapped!");
                },
                child: const Icon(Icons.add),
                backgroundColor: Color(0xff5C7FF2),
              ));
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
    return InkWell(
      onTap: () {
        debugPrint(this.company.name + " card tapped!");
      },
      child: Column(children: <Widget>[
        Expanded(
            child: Stack(children: <Widget>[
          Image.network(this.company.companyImages.internal, fit: BoxFit.cover),
          DecoratedBox(
              decoration: BoxDecoration(
                  color: Color(0xffEDA460),
                  borderRadius: BorderRadius.circular(3)),
              child: Padding(
                padding: EdgeInsets.all(4.0),
                child:
                    Text("Suggestion", style: TextStyle(color: Colors.white)),
              ))
        ])),
        SizedBox(
            width: double.infinity,
            child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xffF1F1F1)),
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                        child: Text(this.company.name,
                            style: TextStyle(fontWeight: FontWeight.bold)))))),
      ]),
    );
  }
}
