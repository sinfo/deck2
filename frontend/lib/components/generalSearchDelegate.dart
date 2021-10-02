import 'package:flutter/material.dart';
import 'package:frontend/components/GridLayout.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/speakerService.dart';

class GeneralSearchDelegate extends SearchDelegate {
  late Future<List<CompanyLight>> companies;
  late Future<List<SpeakerLight>> speakers;
  late Future<List<Member>> members;

  CompanyService companyService = new CompanyService();
  SpeakerService speakerService = new SpeakerService();
  MemberService memberService = new MemberService();

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
    this.speakers = speakerService.getSpeakersLight(name: query);
    this.members = memberService.getMembers(name: query);
    return searchResults(companies, speakers, members);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length > 1) {
      this.companies = companyService.getCompaniesLight(name: query);
      this.speakers = speakerService.getSpeakersLight(name: query);
      this.members = memberService.getMembers(name: query);
      return searchResults(companies, speakers, members);
    } else {
      return Center(child: Text("No Results yet :)"));
    }
  }

  Widget searchResults(Future<List<CompanyLight>> companies,
      Future<List<SpeakerLight>> speakers, Future<List<Member>> members) {
    return FutureBuilder(
        future: Future.wait([this.speakers, this.companies, this.members]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<dynamic> data = snapshot.data as List<dynamic>;

            List<SpeakerLight> speaksMatched = data[0] as List<SpeakerLight>;
            List<CompanyLight> compsMatched = data[1] as List<CompanyLight>;
            List<Member> membsMatched = data[2] as List<Member>;
            return GridLayout(
                speakers: speaksMatched,
                companies: compsMatched,
                members: membsMatched);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }

  @override
  String get searchFieldLabel {
    return 'Search Company, Speaker or Member';
  }
}
