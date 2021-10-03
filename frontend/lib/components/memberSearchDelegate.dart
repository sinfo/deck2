import 'package:flutter/material.dart';
import 'package:frontend/components/GridLayout.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/memberService.dart';

class MemberSearchDelegate extends SearchDelegate {
  late Future<List<Member>> members;
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
    this.members = memberService.getMembers(name: query);
    return FutureBuilder<List<Member>>(
        future: this.members,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.length > 0) {
              return Center(
                  child: Text("Found Member!. Still in progress :)"));
              // Navigator.push(
              //                   context, MaterialPageRoute(
              //                     builder: (context) => CompanyScreen(PUT ID HERE!!!)),);
            } else {
              return Center(child: Text("Member Not Found :("));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length > 1) {
      this.members = memberService.getMembers(name: query);
      return FutureBuilder(
          future: this.members,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Member> membersMatched =
                  snapshot.data as List<Member>;
              if (membersMatched.length > 0) {
                return GridLayout(members: membersMatched);
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
    return 'Search Member By Name';
  }
}
