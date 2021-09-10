import 'package:flutter/material.dart';
import 'package:frontend/components/GridLayout.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/companyService.dart';

class CompanySearchDelegate extends SearchDelegate {
  late Future<List<CompanyLight>> companies;
  CompanyService companyService = new CompanyService();

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
    this.companies = companyService.getCompaniesLight(name: query);
    return FutureBuilder<List<CompanyLight>>(
        future: this.companies,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.length > 0) {
              return Center(
                  child: Text("Found Company!. Still in progress :)"));
              // Navigator.push(
              //                   context, MaterialPageRoute(
              //                     builder: (context) => CompanyScreen(PUT ID HERE!!!)),);
            } else {
              return Center(child: Text("Company Not Found :("));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length > 1) {
      this.companies = companyService.getCompaniesLight(name: query);
      return FutureBuilder(
          future: this.companies,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<CompanyLight> compsMatched =
                  snapshot.data as List<CompanyLight>;
              if (compsMatched.length > 0) {
                return GridLayout(companies: compsMatched);
              } else {
                return Center(child: Text("No Results"));
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          });
    } else {
      return Center(child: Text("No Results yet :)"));
    }
  }

  @override
  String get searchFieldLabel {
    return 'Search Company By Name';
  }
}
