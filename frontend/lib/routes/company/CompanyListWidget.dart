import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/ListViewCard2.dart';
import 'package:frontend/components/companySearchDelegate.dart';
import 'package:frontend/components/router.dart';
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

final int MAX_COMP = 30;

class CompanyListWidget extends StatefulWidget {
  const CompanyListWidget({Key? key}) : super(key: key);

  @override
  _CompanyListWidgetState createState() => _CompanyListWidgetState();
}

class _CompanyListWidgetState extends State<CompanyListWidget> {
  CompanyService companyService = new CompanyService();
  late Future<List<CompanyLight>> companies;
  List<CompanyLight> companiesLoaded = [];
  SortingMethod _sortMethod = SortingMethod.RANDOM;
  int numRequests = 0;
  ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
    this.companies = companyService.getCompaniesLight(
        maxCompInRequest: MAX_COMP, numRequestsBackend: numRequests);
    numRequests++;
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      setState(() {
        _loadMoreCompanies();
      });
    }
  }

  void _loadMoreCompanies() {
    storeCompaniesLoaded();
    this.companies = companyService.getCompaniesLight(
        maxCompInRequest: MAX_COMP,
        numRequestsBackend: numRequests,
        sortMethod: _sortMethod);
    numRequests++;
  }

  void storeCompaniesLoaded() async {
    this.companiesLoaded.addAll(await this.companies);
  }

  Widget companyGrid() {
    return FutureBuilder<List<CompanyLight>>(
        future: companies,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<CompanyLight> comp = companiesLoaded + snapshot.data!;
            return LayoutBuilder(builder: (context, constraints) {
              double cardWidth = 250;
              bool isSmall = false;
              if (constraints.maxWidth < 1500) {
                cardWidth = 200;
                isSmall = true;
              }
              return GridView.builder(
                  controller: _controller,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width ~/ cardWidth,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: comp.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListViewCard2(
                        small: isSmall,
                        companyLight: comp[index],
                        participationsInfo: true);
                  });
            });
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
              onPressed: () {
                showSearch(context: context, delegate: CompanySearchDelegate());
              },
            ),
            PopupMenuButton<SortingMethod>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort Companies',
              onSelected: (SortingMethod sort) {
                setState(() {
                  _sortMethod = sort;
                  this.companiesLoaded.clear();
                  numRequests = 0;
                  this.companies = companyService.getCompaniesLight(
                      maxCompInRequest: MAX_COMP,
                      sortMethod: sort,
                      numRequestsBackend: numRequests);
                  numRequests++;
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
