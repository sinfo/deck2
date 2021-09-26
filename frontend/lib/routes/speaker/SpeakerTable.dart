import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/routes/speaker/SpeakerListWidget.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:frontend/components/filterbar.dart';
import 'package:frontend/models/participation.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class SpeakerTable extends StatefulWidget {
  SpeakerTable({Key? key}) : super(key: key);

  @override
  _SpeakerTableState createState() => _SpeakerTableState();
}

class _SpeakerTableState extends State<SpeakerTable>
    with AutomaticKeepAliveClientMixin {
  final MemberService _memberService = MemberService();
  late String _filter;
  late Future<List<Member>> _members;

  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _members =
        _memberService.getMembers(event: App.localStorage.getInt('event'));
    _filter = "ALL";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    int event = Provider.of<EventNotifier>(context).event.id;
    return FutureBuilder(
      key: ValueKey(event),
      future: _members,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Member> membs = snapshot.data as List<Member>;
          Member me =
              Member.fromJson(json.decode(App.localStorage.getString('me')!));
          membs.sort((a, b) => a.name!.compareTo(b.name!));
          int index = membs.indexWhere((element) => element.id == me.id);
          membs.insert(0, membs.removeAt(index));
          return NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                  child: FilterBar(onSelected: (value) => onSelected(value)),
                ),
              ),
            ],
            body: ListView(
              children: membs
                  .map((e) => MemberSpeakerRow(member: e, filter: _filter))
                  .toList(),
              addAutomaticKeepAlives: true,
            ),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  onSelected(String filter) {
    setState(() {
      _filter = filter;
    });
  }
}

class MemberSpeakerRow extends StatefulWidget {
  final Member member;
  final String filter;
  MemberSpeakerRow({Key? key, required this.member, required this.filter})
      : super(key: key);

  @override
  _MemberSpeakerRowState createState() =>
      _MemberSpeakerRowState(member: member, filter: filter);
}

class _MemberSpeakerRowState extends State<MemberSpeakerRow>
    with AutomaticKeepAliveClientMixin {
  Member member;
  String filter;
  SpeakerService _speakerService = SpeakerService();
  late Future<List<Speaker>> _speakers;
  _MemberSpeakerRowState({required this.member, required this.filter});

  @override
  void initState() {
    super.initState();
    _speakers = _speakerService.getSpeakers(
        eventId: App.localStorage.getInt('event'), member: this.member.id);
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildBigTile(BuildContext context, String _filter) {
    int event = Provider.of<EventNotifier>(context).event.id;
    return Column(
      children: [
        ListTile(
          leading: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
              child: Image.network(
                this.member.image,
                width: 50,
                height: 50,
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return Image.asset(
                    'assets/noImage.png',
                    width: 50,
                    height: 50,
                  );
                },
              )),
          title: Text(
            this.member.name!,
            style: TextStyle(fontSize: 18),
          ),
          subtitle: Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ),
        FutureBuilder(
          future: _speakers,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Speaker> spks = snapshot.data as List<Speaker>;
              List<Speaker> spkscpy = filterListByStatus(spks, _filter);
              spkscpy.sort((a, b) => STATUSORDER[a.participations!
                      .firstWhere((element) => element.event == event)
                      .status]!
                  .compareTo(STATUSORDER[b.participations!
                      .firstWhere((element) => element.event == event)
                      .status]!));
              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: spkscpy.length == 0 ? 0 : null,
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: spkscpy
                            .map((e) => ListViewCard(small: false, speaker: e))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Shimmer.fromColors(
                baseColor: Colors.grey[400]!,
                highlightColor: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        child: Wrap(
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: [
                              for (int i = 0; i < 8; i++)
                                ListViewCard.fakeCard()
                            ]),
                      ),
                    ),
                  ],
                ),
              );

              // return ListView.builder(
              //   itemCount: 10,
              //   // Important code
              //   itemBuilder: (context, index) => Shimmer.fromColors(
              //       baseColor: Colors.grey[400]!,
              //       highlightColor: Colors.white,
              //       child: ListViewCard.fakeCard()),
              // );
            }
          },
        )
      ],
    );
  }

  Widget _buildSmallTile(BuildContext context, String _filter) {
    int event = Provider.of<EventNotifier>(context).event.id;
    return Column(
      children: [
        ListTile(
          leading: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
              child: Image.network(
                this.member.image,
                width: 40,
                height: 40,
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return Image.asset(
                    'assets/noImage.png',
                    width: 40,
                    height: 40,
                  );
                },
              )),
          title: Text(this.member.name!),
          subtitle: Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ),
        FutureBuilder(
          future: _speakers,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Speaker> spks = snapshot.data as List<Speaker>;
              List<Speaker> spkscpy = filterListByStatus(spks, _filter);
              spkscpy.sort((a, b) => STATUSORDER[a.participations!
                      .firstWhere((element) => element.event == event)
                      .status]!
                  .compareTo(STATUSORDER[b.participations!
                      .firstWhere((element) => element.event == event)
                      .status]!));
              return Container(
                height: spkscpy.length == 0 ? 0 : 175,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: spkscpy
                      .map((e) => ListViewCard(small: true, speaker: e))
                      .toList(),
                ),
              );
            } else {
              return Container(
                child: Center(
                  child: Container(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }
          },
        )
      ],
    );
  }

  List<Speaker> filterListByStatus(List spks, String _filter) {
    List<Speaker> spkscpy = [];
    if (_filter != "ALL") {
      for (Speaker s in spks) {
        Participation p =
            s.participations!.firstWhere((element) => element.event == 29);
        if (p.status.toString().split('.').last ==
            _filter) //TODO: find a better way to do this
          spkscpy.add(s);
      }
    } else {
      spkscpy = List.from(spks);
    }
    return spkscpy;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    String _filter = widget.filter;
    return Container(
      margin: EdgeInsets.all(10),
      child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < App.SIZE) {
              return _buildSmallTile(context, _filter);
            } else {
              return _buildBigTile(context, _filter);
            }
          })),
    );
  }
}
