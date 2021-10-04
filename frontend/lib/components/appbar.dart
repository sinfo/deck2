import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/speakerService.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  CustomAppBar({Key? key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize;

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late Future<List<CompanyLight>> companies;
  late Future<List<SpeakerLight>> speakers;
  late Future<List<Member>> members;
  String query = "";

  CompanyService companyService = new CompanyService();
  SpeakerService speakerService = new SpeakerService();
  MemberService memberService = new MemberService();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AppBar(
        title: TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search Company, Speaker or Member',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (newQuery) {
              setState(() {
                this.query = newQuery;
              });
              if (this.query.length > 1) {
                this.companies =
                    companyService.getCompaniesLight(name: this.query);
                this.speakers =
                    speakerService.getSpeakersLight(name: this.query);
                this.members = memberService.getMembers(name: this.query);
              }
            }),
      ),
      ...getResults()
    ]);
  }

  List<Widget> getResults() {
    if (this.query.length > 1) {
      return [
        FutureBuilder(
            future: Future.wait([this.speakers, this.companies, this.members]),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<dynamic> data = snapshot.data as List<dynamic>;

                List<SpeakerLight> speaksMatched =
                    data[0] as List<SpeakerLight>;
                List<CompanyLight> compsMatched = data[1] as List<CompanyLight>;
                List<Member> membsMatched = data[2] as List<Member>;
                return searchResults(speaksMatched, compsMatched, membsMatched);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            })
      ];
    } else {
      return [];
    }
  }

  Widget searchResults(List<SpeakerLight> speakers,
      List<CompanyLight> companies, List<Member> members) {
    List<Widget> results = getListCards(speakers, companies, members);
    return ListView.builder(
        shrinkWrap: true,
        itemCount: results.length,
        itemBuilder: (BuildContext context, int index) {
          return results[index];
        });
  }

  List<Widget> getListCards(List<SpeakerLight> speakers,
      List<CompanyLight> companies, List<Member> members) {
    List<Widget> results = [];
    if (speakers.length != 0) {
      results.addAll(speakers.map((e) => SearchResultWidget(speaker: e)));
    }
    if (companies.length != 0) {
      results.addAll(companies.map((e) => SearchResultWidget(company: e)));
    }
    if (members.length != 0) {
      results.addAll(members.map((e) => SearchResultWidget(member: e)));
    }
    return results;
  }
}

class SearchResultWidget extends StatelessWidget {
  final CompanyLight? company;
  final SpeakerLight? speaker;
  final Member? member;
  const SearchResultWidget({Key? key, this.company, this.speaker, this.member})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          print("HIIII");
          // Navigator.push(context, MaterialPageRoute(builder: (context) {
          //   return UnknownScreen();
          // })); // TODO: Company, Speaker or Member screen
        },
        child: Center(
          child: Card(
            margin: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: CircleAvatar(
                    foregroundImage: NetworkImage(getImageURL()),
                    backgroundImage: AssetImage(
                      'assets/noImage.png',
                    ),
                  ),
                  title: Text(getName()),
                ),
              ],
            ),
          ),
        ));
  }

  String getImageURL() {
    if (this.company != null) {
      return this.company!.companyImages.internal;
    } else if (this.speaker != null) {
      return this.speaker!.speakerImages.internal!;
    } else if (this.member != null) {
      return this.member!.image;
    } else {
      //ERROR case
      return "";
    }
  }

  String getName() {
    if (this.company != null) {
      return this.company!.name;
    } else if (this.speaker != null) {
      return this.speaker!.name;
    } else if (this.member != null) {
      return this.member!.name!;
    } else {
      //ERROR case
      return "";
    }
  }
}
