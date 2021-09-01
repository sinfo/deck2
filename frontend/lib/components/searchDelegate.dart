import 'package:flutter/material.dart';
import 'package:frontend/components/GridLayout.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/speaker.dart';

class CustomSearchDelegate extends SearchDelegate {
  final List<CompanyLight>? companies;
  final List<Speaker>? speakers;

  CustomSearchDelegate({this.companies, this.speakers});

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
    if (companies != null) {
      var company = companies!.where(
          (element) => element.name.toLowerCase() == query.toLowerCase());
      /*return company.isEmpty ? Navigator.push(
                              context, MaterialPageRoute(
                                builder: (context) => CompanyScreen()),); : 
                                Center(child: Text('Company Not Found...'));*/
      debugPrint(company.isEmpty.toString());

      //TODO after CompanyScreen() done
      return Center(child: Text('Company Not Found? ${company.isEmpty.toString()}'));
    } else {
      var speaker = speakers!.where(
          (element) => element.name.toLowerCase() == query.toLowerCase());
      /*return speaker.isEmpty ? Navigator.push(
                              context, MaterialPageRoute(
                                builder: (context) => SpeakerScreen()),); : 
                                Center(child: Text('Company Not Found...'));*/
      debugPrint(speaker.isEmpty.toString());

      //TODO after SpeakerScreen() done
      return Center(child: Text('Speaker Not Found? ${speaker.isEmpty.toString()}'));
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (companies != null) {
      final companiesSuggested = query.isEmpty
          ? companies
          : companies!
              .where(
                  (p) => p.name.contains(RegExp(query, caseSensitive: false)))
              .toList();

      return GridLayout(companies: companiesSuggested);
    } else {
      final speakersSuggested = query.isEmpty
          ? speakers
          : speakers!
              .where(
                  (p) => p.name.contains(RegExp(query, caseSensitive: false)))
              .toList();

      return GridLayout(speakers: speakersSuggested);
    }
  }

  @override
  String get searchFieldLabel {
    if(companies != null) {
      return 'Search Company By Name';
    } else {
      return 'Search Speaker By Name';
    }
  }
}
