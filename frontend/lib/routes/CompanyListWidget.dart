import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';

final Map<String, Color> partColor = {
  'SUGGESTED': Color(0xffEDA460),
  'SELECTED': Colors.deepPurple,
  'ON_HOLD': Colors.blueGrey,
  'CONTACTED': Colors.yellow,
  'IN_CONVERSATIONS': Colors.lightBlue,
  'ACCEPTED': Colors.lightGreen,
  'REJECTED': Colors.red,
  'GIVEN_UP': Colors.black,
  'ANNOUNCED': Colors.green.shade700
};

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

          return Stack(children: <Widget>[
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width ~/ CARD_WIDTH,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 0.85,
              children: comps
                  .map((e) => CompanyCard(
                        company: e,
                      ))
                  .toList(),
            ),
            Positioned(
                bottom: 15,
                right: 15,
                child: FloatingActionButton(
                  onPressed: () {
                    //Redirect to create a company!!!
                    debugPrint("Floating Action Button tapped!");
                  },
                  child: const Icon(Icons.add),
                  backgroundColor: Color(0xff5C7FF2),
                ))
          ]);
        } else {
          return CircularProgressIndicator();
        }
      });
}

class CompanyCard extends StatelessWidget {
  final CompanyLight company;
  const CompanyCard({Key? key, required this.company}) : super(key: key);

  String partName(String participationStatus) {
    int i;
    for (i = 0; i < participationStatus.length; i++) {
      if (participationStatus[i] == '_') {
        break;
      }
    }
    //Assuming that last character is not _
    if (i == participationStatus.length) {
      return participationStatus.substring(0, 1) +
          participationStatus.substring(1).toLowerCase();
    } else {
      return participationStatus.substring(0, 1) +
          participationStatus.substring(1, i).toLowerCase() +
          ' ' +
          participationStatus.substring(i + 1, i + 2) +
          participationStatus.substring(i + 2).toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        //CompanyScreen(this.company)
        debugPrint(this.company.name + " card tapped!");
      },
      child: Column(children: <Widget>[
        Stack(children: <Widget>[
          Image.network(this.company.companyImages.internal, fit: BoxFit.cover),
          DecoratedBox(
              decoration: BoxDecoration(
                  color: partColor[this.company.status],
                  borderRadius: BorderRadius.circular(3)),
              child: Padding(
                padding: EdgeInsets.all(4.0),
                child: Text(partName(this.company.status),
                    style: TextStyle(color: Colors.white)),
              ))
        ]),
        DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xffF1F1F1)),
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                    child: Text(this.company.name,
                        style: TextStyle(fontWeight: FontWeight.bold))))),
      ]),
    );
  }
}
