import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/GridLayout.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/components/searchDelegate.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';

enum SortingMethod {
  RANDOM,
  NUM_PARTICIPATIONS,
  LAST_PARTICIPATION,
}

final Map<SortingMethod, String> SORT_STRING = {
  SortingMethod.NUM_PARTICIPATIONS: 'Sort By Number Of Participations',
  SortingMethod.LAST_PARTICIPATION: 'Sort By Last Participation',
};

class CompanyListWidget extends StatefulWidget {
  const CompanyListWidget({Key? key}) : super(key: key);

  @override
  _CompanyListWidgetState createState() => _CompanyListWidgetState();
}

class _CompanyListWidgetState extends State<CompanyListWidget> {
  CompanyService companyService = new CompanyService();
  late Future<List<CompanyLight>> companies;
  SortingMethod _sortMethod = SortingMethod.RANDOM;

  @override
  void initState() {
    super.initState();
    this.companies = companyService.getCompaniesLight();
  }

  Widget companyGrid() {
    return FutureBuilder<List<CompanyLight>>(
        future: companies,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (_sortMethod == SortingMethod.NUM_PARTICIPATIONS) {
              snapshot.data!.sort((a, b) =>
                  b.numParticipations!.compareTo(a.numParticipations!));
            } else if (_sortMethod == SortingMethod.LAST_PARTICIPATION) {
              snapshot.data!.sort((a, b) {
                if (a.numParticipations! > 0 &&
                    b.numParticipations! > 0) {
                  return b.lastParticipation!
                      .compareTo(a
                          .lastParticipation!);
                } else {
                  //We return first the company with participations and then the
                  //company with no participations in case one of the companies
                  //does not have participations
                  return b.numParticipations!
                      .compareTo(a.numParticipations!);
                }
              });
            }
            return GridLayout(companies: snapshot.data!);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
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
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search company',
              onPressed: () async {
                showSearch(
                    context: context,
                    delegate: CustomSearchDelegate(companies: await companies));
              },
            ),
            PopupMenuButton<SortingMethod>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort Companies',
              onSelected: (SortingMethod sort) {
                setState(() {
                  _sortMethod = sort;
                });
              },
              itemBuilder: (BuildContext context) {
                return SORT_STRING.keys.map((SortingMethod choice) {
                  return PopupMenuItem<SortingMethod>(
                    value: choice,
                    child: Center(child: Text(SORT_STRING[choice]!)),
                  );
                }).toList();
              },
            ),
          ]),
      body: companyGrid(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            Routes.AddCompany,
          );
        },
        label: const Text('Create New Company'),
        icon: const Icon(Icons.business),
        backgroundColor: Color(0xff5C7FF2),
      ),
    );
  }
}
