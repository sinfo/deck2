import 'package:flutter/material.dart';
import 'package:frontend/components/SearchResultWidget.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/services/eventService.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/speakerService.dart';

enum SortingMethod {
  RANDOM,
  NUM_PARTICIPATIONS,
  LAST_PARTICIPATION,
}

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool disableEventChange;

  @override
  final Size preferredSize;

  CustomAppBar({Key? key, required this.disableEventChange})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  _CustomAppBarState createState() => _CustomAppBarState(disableEventChange);
}

class _CustomAppBarState extends State<CustomAppBar> {
  late Future<List<Company>> companies;
  late Future<List<Speaker>> speakers;
  late Future<List<Member>> members;
  late Future<List<int>> _eventIds;
  final bool disableEventChange;

  EventService _eventService = EventService();
  CompanyService companyService = new CompanyService();
  SpeakerService speakerService = new SpeakerService();
  MemberService memberService = new MemberService();

  final _searchController = TextEditingController();

  _CustomAppBarState(this.disableEventChange);

  @override
  void initState() {
    super.initState();
    if (!disableEventChange) {
      _eventIds = _eventService.getEventIds();
    }
  }

  @override
  Widget build(BuildContext context) {
    EventNotifier notifier = Provider.of<EventNotifier>(context);
    int current = notifier.event.id;
    return Column(children: [
      AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(children: [
          InkWell(
            child: SizedBox(
              height: kToolbarHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                child: Image.asset(
                  'assets/logo_deck.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          if (!disableEventChange)
            Padding(
              padding: const EdgeInsets.fromLTRB(4.0, 8.0, 24.0, 8.0),
              child: FutureBuilder(
                future: _eventIds,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<int> ids = snapshot.data as List<int>;
                    return DropdownButton<int>(
                      icon: const Icon(
                        Icons.arrow_downward,
                        color: Colors.white,
                      ),
                      iconSize: 24,
                      elevation: 16,
                      dropdownColor: Colors.grey,
                      style: const TextStyle(color: Colors.white),
                      underline: Container(
                        height: 2,
                        color: Colors.white,
                      ),
                      onChanged: (int? newId) async {
                        if (newId == null || newId == current) {
                          return;
                        } else {
                          Event newEvent =
                              await _eventService.getEvent(eventId: newId);
                          notifier.event = newEvent;
                        }
                      },
                      value: current,
                      items: ids
                          .map<DropdownMenuItem<int>>((e) =>
                              DropdownMenuItem<int>(
                                  value: e,
                                  child: Text('SINFO ${e.toString()}')))
                          .toList(),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          Expanded(
              child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Provider.of<ThemeNotifier>(context).isDark
                        ? Colors.grey[800]
                        : Colors.white,
                    hintText: 'Search Company, Speaker or Member',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.length != 0
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: Icon(Icons.clear),
                          )
                        : null,
                  ),
                  onChanged: (newQuery) {
                    setState(() {});
                    if (_searchController.text.length > 1) {
                      this.companies = companyService.getCompanies(
                          name: _searchController.text);
                      this.speakers = speakerService.getSpeakers(
                          name: _searchController.text);
                      this.members = memberService.getMembers(
                          name: _searchController.text);
                    }
                  })),
        ]),
      ),
      ...getResults(MediaQuery.of(context).size.height / 2)
    ]);
  }

  List<Widget> getResults(double height) {
    if (_searchController.text.length > 1) {
      return [
        Container(
            decoration: new BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: FutureBuilder(
                future:
                    Future.wait([this.speakers, this.companies, this.members]),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<dynamic> data = snapshot.data as List<dynamic>;

                    List<Speaker> speaksMatched = data[0] as List<Speaker>;
                    List<Company> compsMatched = data[1] as List<Company>;
                    List<Member> membsMatched = data[2] as List<Member>;
                    return searchResults(
                        speaksMatched, compsMatched, membsMatched, height);
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                }))
      ];
    } else {
      return [];
    }
  }

  Widget searchResults(List<Speaker> speakers, List<Company> companies,
      List<Member> members, double listHeight) {
    List<Widget> results = getListCards(speakers, companies, members);
    return Container(
        constraints: BoxConstraints(maxHeight: listHeight),
        child: Material(
            color: Theme.of(context).cardColor,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (BuildContext context, int index) {
                  return results[index];
                })));
  }

  List<Widget> getListCards(
      List<Speaker> speakers, List<Company> companies, List<Member> members) {
    List<Widget> results = [];
    if (speakers.length != 0) {
      results.add(getDivider("Speakers"));
      results.addAll(speakers.map(
          (e) => SearchResultWidget(speaker: e, index: speakers.indexOf(e))));
    }
    if (companies.length != 0) {
      results.add(getDivider("Companies"));
      results.addAll(companies.map(
          (e) => SearchResultWidget(company: e, index: companies.indexOf(e))));
    }
    if (members.length != 0) {
      results.add(getDivider("Members"));
      results.addAll(members.map(
          (e) => SearchResultWidget(member: e, index: members.indexOf(e))));
    }
    return results;
  }

  Widget getDivider(String name) {
    return Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              child: Text(name, style: TextStyle(fontSize: 18)),
              margin: EdgeInsets.fromLTRB(0, 8, 0, 4),
            ),
          ],
        ));
  }
}
