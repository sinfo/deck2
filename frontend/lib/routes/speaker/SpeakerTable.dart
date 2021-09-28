import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/speakerNotifier.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/components/ListViewCard.dart';
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
  final SpeakerService _speakerService = SpeakerService();
  late ParticipationStatus _filter;
  late Future<List<Speaker>> _speakers;
  late Future<List<Member>> _members;

  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    int event = App.localStorage.getInt('event')!;
    _filter = ParticipationStatus.NO_STATUS;
    _speakers = _speakerService.getSpeakers(eventId: event);
    _members = _memberService.getMembers(event: event);
  }

  @override
  Widget build(BuildContext context) {
    Key k = UniqueKey();
    super.build(context);
    int event = Provider.of<EventNotifier>(context).event.id;
    return FutureBuilder(
        key: ValueKey(event),
        future: _speakerService.getSpeakers(eventId: event),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            SpeakerTableNotifier notifier =
                Provider.of<SpeakerTableNotifier>(context);
            notifier.speakers = snapshot.data as List<Speaker>;
            return FutureBuilder(
              future: _members,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Member> membs = snapshot.data as List<Member>;
                  Member me = Member.fromJson(
                      json.decode(App.localStorage.getString('me')!));
                  membs.sort((a, b) => a.name!.compareTo(b.name!));
                  int index =
                      membs.indexWhere((element) => element.id == me.id);
                  membs.insert(0, membs.removeAt(index));
                  return NestedScrollView(
                    floatHeaderSlivers: true,
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                          child: FilterBar(
                              onSelected: (value) => onSelected(value)),
                        ),
                      ),
                    ],
                    body: ListView(
                      children: membs
                          .map((e) =>
                              MemberSpeakerRow(member: e, filter: _filter))
                          .toList(),
                      addAutomaticKeepAlives: true,
                    ),
                  );
                } else {
                  return CircularProgressIndicator(
                    key: k,
                  );
                }
              },
            );
          } else {
            return CircularProgressIndicator(
              key: k,
            );
          }
        });
  }

  onSelected(ParticipationStatus filter) {
    setState(() {
      _filter = filter;
    });
  }
}

class MemberSpeakerRow extends StatelessWidget {
  final Member member;
  final ParticipationStatus filter;
  SpeakerService _speakerService = SpeakerService();
  MemberSpeakerRow({Key? key, required this.member, required this.filter})
      : super(key: key);

  Widget _buildBigTile(BuildContext context, String _filter) {
    int event = Provider.of<EventNotifier>(context).event.id;
    List<Speaker> speakers = Provider.of<SpeakerTableNotifier>(context)
        .getByMember(member.id!, event, filter);
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
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                height: speakers.length == 0 ? 0 : null,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: speakers
                      .map((e) => ListViewCard(small: false, speaker: e))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // return ListView.builder(
  //   itemCount: 10,
  //   // Important code
  //   itemBuilder: (context, index) => Shimmer.fromColors(
  //       baseColor: Colors.grey[400]!,
  //       highlightColor: Colors.white,
  //       child: ListViewCard.fakeCard()),
  // );

  // return Shimmer.fromColors(
  //   baseColor: Colors.grey[400]!,
  //   highlightColor: Colors.white,
  //   child: Row(
  //     children: [
  //       Expanded(
  //         flex: 1,
  //         child: Container(
  //           child: Wrap(
  //               alignment: WrapAlignment.start,
  //               crossAxisAlignment: WrapCrossAlignment.start,
  //               children: [
  //                 for (int i = 0; i < 8; i++)
  //                   ListViewCard.fakeCard()
  //               ]),
  //         ),
  //       ),
  //     ],
  //   ),
  // );

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
          future: _speakerService.getSpeakers(
              eventId: App.localStorage.getInt('event'),
              member: this.member.id),
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
    int event = Provider.of<EventNotifier>(context).event.id;

    List<Speaker> speakers = Provider.of<SpeakerTableNotifier>(context)
        .getByMember(member.id!, event, filter);
    return Container(
      margin: EdgeInsets.all(10),
      child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: LayoutBuilder(builder: (context, constraints) {
            bool small = constraints.maxWidth < App.SIZE;

            return Column(
              children: [
                ListTile(
                  leading: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      child: Image.network(
                        this.member.image,
                        width: small ? 40 : 50,
                        height: small ? 40 : 50,
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return Image.asset(
                            'assets/noImage.png',
                            width: small ? 40 : 50,
                            height: small ? 40 : 50,
                          );
                        },
                      )),
                  title: Text(
                    this.member.name!,
                    style: TextStyle(fontSize: small ? 14 : 18),
                  ),
                  subtitle: Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                ),
                small
                    ? Container(
                        height: speakers.length == 0 ? 0 : 175,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: speakers
                              .map((e) => ListViewCard(small: true, speaker: e))
                              .toList(),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: speakers.length == 0 ? 0 : null,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                children: speakers
                                    .map((e) =>
                                        ListViewCard(small: false, speaker: e))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      )
              ],
            );
          })),
    );
  }
}
