import 'package:flutter/material.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/eventService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';

enum SortingMethod {
  RANDOM,
  NUM_PARTICIPATIONS,
  LAST_PARTICIPATION,
}

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  CustomAppBar(
      {Key? key, required this.disableEventChange, this.popUpMenuButton})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize;
  final bool disableEventChange;

  final PopupMenuButton<SortingMethod>? popUpMenuButton;

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  EventService _eventService = EventService();
  late Future<List<int>> _eventIds;
  late Future<List<Company>> companies;
  late Future<List<Speaker>> speakers;
  late Future<List<Member>> members;

  CompanyService companyService = new CompanyService();
  SpeakerService speakerService = new SpeakerService();
  MemberService memberService = new MemberService();

  final _searchController = TextEditingController();

  _CustomAppBarState();

  @override
  void initState() {
    super.initState();
    if (!widget.disableEventChange) {
      _eventIds = _eventService.getEventIds();
    }
  }

  Widget _buildEventSelector(BuildContext context) {
    EventNotifier notifier = Provider.of<EventNotifier>(context);
    int current = notifier.event.id;
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
                  Event newEvent = await _eventService.getEvent(eventId: newId);
                  notifier.event = newEvent;
                }
              },
              value: current,
              items: ids
                  .map<DropdownMenuItem<int>>((e) => DropdownMenuItem<int>(
                      value: e, child: Text('SINFO ${e.toString()}')))
                  .toList(),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
  //   IconButton(
  //             icon: Image.asset('assets/logo_deck.png'),
  //             iconSize: 50,
  //             onPressed: () {},
  //           ),
  //           if (!widget.disableEventChange) _buildEventSelector(context),

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AppBar(
        title: SizedBox(
          height: kToolbarHeight * 0.8,
          child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Provider.of<ThemeNotifier>(context).isDark
                    ? null
                    : Colors.white,
                hintText: 'Search Company, Speaker or Member',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.length != 0
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                        icon: Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: (newQuery) {
                setState(() {});
                if (_searchController.text.length > 1) {
                  this.companies =
                      companyService.getCompanies(name: _searchController.text);
                  this.speakers =
                      speakerService.getSpeakers(name: _searchController.text);
                  this.members =
                      memberService.getMembers(name: _searchController.text);
                }
              }),
        ),
        actions: getPopUpMenuButton(),
      ),
      ...getResults(MediaQuery.of(context).size.height / 2)
    ]);
  }

  List<Widget>? getPopUpMenuButton() {
    List<Widget>? actions = [];
    if (widget.popUpMenuButton != null) {
      actions.add(widget.popUpMenuButton!);
    }
    return actions;
  }

  List<Widget> getResults(double height) {
    if (_searchController.text.length > 1) {
      return [
        FutureBuilder(
            future: Future.wait([this.speakers, this.companies, this.members]),
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
            })
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
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (BuildContext context, int index) {
              return results[index];
            }));
  }

  List<Widget> getListCards(
      List<Speaker> speakers, List<Company> companies, List<Member> members) {
    List<Widget> results = [];
    if (speakers.length != 0) {
      results.add(getDivider("Speakers"));
      results.addAll(speakers.map((e) => SearchResultWidget(speaker: e)));
    }
    if (companies.length != 0) {
      results.add(getDivider("Companies"));
      results.addAll(companies.map((e) => SearchResultWidget(company: e)));
    }
    if (members.length != 0) {
      results.add(getDivider("Members"));
      results.addAll(members.map((e) => SearchResultWidget(member: e)));
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
              margin: EdgeInsets.fromLTRB(0, 8, 0, 0),
            ),
            Divider(
              color: Colors.grey,
              thickness: 1,
            ),
          ],
        ));
  }
}

class SearchResultWidget extends StatelessWidget {
  final Company? company;
  final Speaker? speaker;
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
        child: ListTile(
          tileColor: Theme.of(context).cardColor,
          leading: CircleAvatar(
            foregroundImage: NetworkImage(getImageURL()),
            backgroundImage: AssetImage(
              'assets/noImage.png',
            ),
          ),
          title: Text(getName()),
        ),
      ),
    );
  }

  String getImageURL() {
    if (this.company != null) {
      return this.company!.companyImages.internal;
    } else if (this.speaker != null) {
      return this.speaker!.imgs!.internal!;
    } else if (this.member != null) {
      return this.member!.image!;
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
      return this.member!.name;
    } else {
      //ERROR case
      return "";
    }
  }
}
