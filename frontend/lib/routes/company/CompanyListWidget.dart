import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  List<String> compNames = [];
  SortingMethod _sortMethod = SortingMethod.RANDOM;

  @override
  void initState() {
    super.initState();
    this.companies = companyService.getCompaniesLight();
  }

  Widget companyGrid(double width) {
    return FutureBuilder<List<CompanyLight>>(
        future: companies,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (_sortMethod == SortingMethod.NUM_PARTICIPATIONS) {
              snapshot.data!.sort((a, b) =>
                  b.participations!.length.compareTo(a.participations!.length));
            } else if (_sortMethod == SortingMethod.LAST_PARTICIPATION) {
              snapshot.data!.sort((a, b) {
                if (a.participations!.length > 0 &&
                    b.participations!.length > 0) {
                  return b.participations![b.participations!.length - 1].event
                      .compareTo(a
                          .participations![a.participations!.length - 1].event);
                } else {
                  //We return first the company with participations and then the company with no participations
                  //in case one of the companies does not have participations
                  return b.participations!.length
                      .compareTo(a.participations!.length);
                }
              });
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width ~/ width,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 0.75,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) {
                compNames.add(snapshot.data![index].name);
                return CompanyCard(
                    company: snapshot.data![index], cardWidth: width);
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    double card_width;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 1500) {
        card_width = 200;
      } else {
        card_width = 250;
      }
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
                  showSearch(
                      context: context,
                      delegate: CustomSearchDelegate(compNames));
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
        body: companyGrid(card_width),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            /*
                  TODO when AddCompany() screen is finished

                  Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddCompany()),
                  );*/
          },
          label: const Text('Add New Company'),
          icon: const Icon(Icons.business),
          backgroundColor: Color(0xff5C7FF2),
        ),
      );
    });
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final List<String> companyNames;

  CustomSearchDelegate(this.companyNames);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    var company = companyNames
        .where((element) => element.toLowerCase() == query.toLowerCase());
    /*return company.isEmpty ? Navigator.push(
                              context, MaterialPageRoute(
                                builder: (context) => CompanyScreen()),); : 
                                Center(child: Text('Company Not Found...'));*/
    debugPrint(company.isEmpty.toString());

    //TODO after CompanyScreen() done
    return Center(child: Text('Company Not Found...'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final companiesSuggested = query.isEmpty
        ? companyNames
        : companyNames
            .where((p) => p.contains(RegExp(query, caseSensitive: false)))
            .toList();

    return ListView.builder(
      itemBuilder: (context, index) => ListTile(
        onTap: () {
          /*
                  TODO when CompanyScreen() screen is finished

                  Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddCompany()),
                  );*/
        },
        title: RichText(
          text: TextSpan(
              text: companiesSuggested[index].substring(0, query.length),
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                    text: companiesSuggested[index].substring(query.length),
                    style: TextStyle(color: Colors.grey))
              ]),
        ),
      ),
      itemCount: companiesSuggested.length,
    );
  }
}

class CompanyCard extends StatelessWidget {
  final CompanyLight company;
  final double cardWidth;
  CompanyCard({Key? key, required this.company, required this.cardWidth})
      : super(key: key) {}

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.all(10),
        child: cardWidth == 200
            ? _buildSmallCard(context)
            : _buildBigCard(context),
      );

  Widget _buildSmallCard(BuildContext context) {
    return Container(
      height: 225,
      width: 200,
      margin: EdgeInsets.all(5),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).primaryColor),
      ),
      child: InkWell(
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5)),
                  child: Image.network(
                    company.companyImages.internal,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      return progress == null
                          ? child
                          : Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (BuildContext context, Object exception,
                        StackTrace? stackTrace) {
                      return Image.asset(
                        'assets/noImage.png',
                        fit: BoxFit.fill,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 6),
              Text(company.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(height: 16),
            ],
          ),
          onTap: () {
            /*
                  TODO when CompanyScreen() screen is finished

                  Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddCompany()),
                  );*/
          }),
    );
  }

  Widget _buildBigCard(BuildContext context) {
    return Container(
      height: 275,
      width: 250,
      margin: EdgeInsets.all(10),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
      ),
      child: InkWell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Image.network(
                  company.companyImages.internal,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : CircularProgressIndicator();
                  },
                  errorBuilder: (BuildContext context, Object exception,
                      StackTrace? stackTrace) {
                    return Image.asset(
                      'assets/noImage.png',
                      fit: BoxFit.fill,
                    );
                  },
                ),
              ),
              SizedBox(height: 12.5),
              Text(company.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    //fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(height: 12.5),
            ],
          ),
          onTap: () {
            /*
                  TODO when CompanyScreen() screen is finished

                  Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddCompany()),
              );*/
          }),
    );
  }
}
