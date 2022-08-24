import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';

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
    this.companies = companyService.getCompanies(
        maxCompInRequest: MAX_COMP,
        numRequestsBackend: numRequests,
        sortMethod: _sortMethod);
    numRequests++;
  }

  void storeCompaniesLoaded() async {
    this.companiesLoaded.addAll(await this.companies);
  }

  Widget companyGrid() {
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
                    return ListViewCard(
                        small: isSmall,
                        company: comp[index],
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
    List<Widget> popupMenuBtn = popUpMenuButton();
    CustomAppBar appBar =
        CustomAppBar(actions: popupMenuBtn, disableEventChange: true);
    return Scaffold(
      body: Stack(children: [
        Container(
            margin: EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
            child: companyGrid()),
        appBar,
      ]),
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

  List<Widget> popUpMenuButton() {
    return [
      PopupMenuButton<SortingMethod>(
        icon: const Icon(Icons.sort),
        tooltip: 'Sort Companies',
        onSelected: (SortingMethod sort) {
          setState(() {
            _sortMethod = sort;
            this.companiesLoaded.clear();
            numRequests = 0;
            this.companies = companyService.getCompanies(
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
      )
    ];
  }
}
