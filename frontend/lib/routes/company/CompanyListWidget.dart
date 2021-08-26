import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/routes/UnknownScreen.dart';
import 'package:frontend/services/companyService.dart';

class CompanyListWidget extends StatefulWidget {
  const CompanyListWidget({Key? key}) : super(key: key);

  @override
  _CompanyListWidgetState createState() => _CompanyListWidgetState();
}

class _CompanyListWidgetState extends State<CompanyListWidget> {
  CompanyService companyService = new CompanyService();
  late Future<List<Company>> companies;
  List<String> compNames = [];

  @override
  void initState() {
    super.initState();
    this.companies = companyService.getCompanies();
  }

  Widget companyGrid(List<Company> comps, double width) {
    return Material(
        child: GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width ~/ width,
      crossAxisSpacing: 5,
      mainAxisSpacing: 5,
      childAspectRatio: 0.75,
      children: comps
          .map((e) => CompanyCard(
                company: e,
              ))
          .toList(),
    ));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: companies,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Company> comps = snapshot.data as List<Company>;
          double card_width;

          for (int i = 0; i < comps.length; i++) {
            compNames.add(comps[i].name);
          }

          return LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 1500) {
              card_width = 100;
            } else {
              card_width = 150;
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
                      )
                    ]),
                bottomNavigationBar: BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    currentIndex: 2,
                    // Give a custom drawer header
                    items: <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                          label: 'Speakers',
                          icon: Icon(
                            Icons.star,
                          )),
                      BottomNavigationBarItem(
                          label: 'Home',
                          icon: Icon(
                            Icons.home,
                          )),
                      BottomNavigationBarItem(
                          label: 'Companies',
                          icon: Icon(
                            Icons.work,
                          )),
                      //FIXME: o item aqui em baixo foi colocado apenas para processo de development
                      BottomNavigationBarItem(
                          label: 'Members',
                          icon: Icon(
                            Icons.people,
                          )),
                    ],
                    onTap: (newIndex) {
                      Navigator.of(context).pop();
                      //_pageAtIndex(newIndex);
                    }),
                body: companyGrid(comps, card_width));
          });
        } else {
          return CircularProgressIndicator();
        }
      });
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
    return Center(
      child: Text(query),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    //TODO

    final companiesSuggested = query.isEmpty
        ? companyNames
        : companyNames
            .where((p) => p.contains(RegExp(query, caseSensitive: false)))
            .toList();

    return ListView.builder(
      itemBuilder: (context, index) => ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return UnknownScreen();
          })); // CompanyScreen(company: this.company)),
        },
        trailing: Icon(Icons.remove_red_eye),
        title: RichText(
          text: TextSpan(
              text: companiesSuggested[index].substring(0, query.length),
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
  final Company company;
  late String _imageUrl;
  late String _title;
  CompanyCard({Key? key, required this.company}) : super(key: key) {
    _initCompany(29);
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.all(10),
        child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 1500) {
                return _buildSmallCard(context);
              } else {
                return _buildBigCard(context);
              }
            })),
      );

  void _initCompany(int event) {
    _imageUrl = company.companyImages.internal;
    _title = company.name;
  }

  Widget _buildSmallCard(BuildContext context) {
    return Container(
      height: 125,
      width: 100,
      margin: EdgeInsets.all(5),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Color(0xff000000)),
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
                    _imageUrl,
                    fit: BoxFit.fill,
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
              Text(_title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(height: 16),
            ],
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return UnknownScreen();
            } // CompanyScreen(company: this.company)),
                ));
          }),
    );
  }

  Widget _buildBigCard(BuildContext context) {
    return Container(
      height: 175,
      width: 150,
      margin: EdgeInsets.all(10),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Color(0xff000000), width: 2),
      ),
      child: Expanded(
        child: InkWell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Image.network(
                    _imageUrl,
                    fit: BoxFit.fill,
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
                Text(_title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      //fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 12.5),
              ],
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return UnknownScreen();
              } // CompanyScreen(company: this.company)),
                  ));
            }),
      ),
    );
  }
}
