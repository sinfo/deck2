import 'package:flutter/material.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/routes/company/CompanyTableNotifier.dart';
import 'package:frontend/services/companyService.dart';
import 'package:provider/provider.dart';

final Map<SortingMethod, String> SORT_STRING = {
  SortingMethod.RANDOM: 'Sort Randomly',
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
  late Future<List<Company>> companies;
  List<Company> companiesLoaded = [];
  SortingMethod _sortMethod = SortingMethod.RANDOM;
  int numRequests = 0;
  ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
    this.companies = companyService.getCompanies(
        maxCompInRequest: MAX_COMP,
        numRequestsBackend: numRequests,
        sortMethod: _sortMethod);
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
    this.companies = companyService.getCompanies(
        maxCompInRequest: MAX_COMP,
        numRequestsBackend: numRequests,
        sortMethod: _sortMethod);
    numRequests++;
  }

  void storeCompaniesLoaded() async {
    this.companiesLoaded.addAll(await this.companies);
  }

  Future<void> companyChangedCallback(BuildContext context,
      {Future<Company?>? fs, Company? company}) async {
    Company? s;
    if (fs != null) {
      s = await fs;
    } else if (company != null) {
      s = company;
    }

    if (s != null) {
      Provider.of<CompanyTableNotifier>(context, listen: false).edit(s);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Done.', style: TextStyle(color: Colors.white))),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occured.',
                style: TextStyle(color: Colors.white))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int latestEvent = Provider.of<EventNotifier>(context).latest.id;
    return FutureBuilder<List<Company>>(
        future: companies,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Company> comp = companiesLoaded + snapshot.data!;
            return LayoutBuilder(builder: (context, constraints) {
              double cardWidth = 200;
              bool isSmall = false;
              if (constraints.maxWidth < App.SIZE) {
                cardWidth = 125;
                isSmall = true;
              }
              return Column(
                children: [
                  DropdownButton<SortingMethod>(
                    value: _sortMethod,
                    icon: const Icon(Icons.sort),
                    elevation: 16,
                    underline: Container(
                        height: 2, color: Theme.of(context).cardColor),
                    onChanged: (SortingMethod? sort) {
                      setState(() {
                        _sortMethod = sort!;
                        this.companiesLoaded.clear();
                        numRequests = 0;
                        this.companies = companyService.getCompanies(
                            maxCompInRequest: MAX_COMP,
                            sortMethod: sort,
                            numRequestsBackend: numRequests);
                        numRequests++;
                      });
                    },
                    items: SORT_STRING.keys
                        .map<DropdownMenuItem<SortingMethod>>(
                            (SortingMethod value) {
                      return DropdownMenuItem<SortingMethod>(
                        value: value,
                        child: Center(child: Text(SORT_STRING[value]!)),
                      );
                    }).toList(),
                  ),
                  Expanded(
                      child: GridView.builder(
                          controller: _controller,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.of(context).size.width ~/ cardWidth,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: comp.length,
                          itemBuilder: (BuildContext context, int index) {
                            return ListViewCard(
                              latestEvent: latestEvent,
                              small: isSmall,
                              company: comp[index],
                              participationsInfo: true,
                              onChangeParticipationStatus:
                                  (step, context) async {
                                companyChangedCallback(
                                  context,
                                  fs: companyService.stepParticipationStatus(
                                      id: comp[index].id, step: step),
                                );
                              },
                            );
                          })),
                ],
              );
            });
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
