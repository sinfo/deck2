import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/routes/speaker/SpeakerListWidget.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/speakerService.dart';

class SpeakerTable extends StatefulWidget {
  SpeakerTable({Key? key}) : super(key: key);

  @override
  _SpeakerTableState createState() => _SpeakerTableState();
}

class _SpeakerTableState extends State<SpeakerTable> {
  final MemberService _memberService = MemberService();
  late Future<List<Member>> members;

  @override
  void initState() {
    super.initState();
    members =
        _memberService.getMembers(event: App.localStorage.getInt("event"));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: members,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Member> membs = snapshot.data as List<Member>;
            membs.sort((a, b) => a.name!.compareTo(b.name!));
            return Stack(children: <Widget>[
              ListView(
                children:
                    membs.map((e) => MemberSpeakerRow(member: e)).toList(),
                addAutomaticKeepAlives: true,
              ),
              Positioned(
                  bottom: 15,
                  right: 15,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SpeakerListWidget()),
                      );
                    },
                    label: const Text('Show All Speakers'),
                    icon: const Icon(Icons.add),
                    backgroundColor: Color(0xff5C7FF2),
                  ))
            ]);
          } else {
            return CircularProgressIndicator();
          }
        },
      );
}

class MemberSpeakerRow extends StatefulWidget {
  final Member member;
  MemberSpeakerRow({Key? key, required this.member}) : super(key: key);

  @override
  _MemberSpeakerRowState createState() =>
      _MemberSpeakerRowState(member: member);
}

class _MemberSpeakerRowState extends State<MemberSpeakerRow>
    with AutomaticKeepAliveClientMixin {
  Member member;
  SpeakerService _speakerService = SpeakerService();
  late Future<List<Speaker>> _speakers;
  _MemberSpeakerRowState({required this.member});

  @override
  void initState() {
    super.initState();
    _speakers =
        _speakerService.getSpeakers(eventId: 29, member: this.member.id);
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildBigTile() {
    return ExpansionTile(
      maintainState: true,
      iconColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      initiallyExpanded: true,
      textColor: Colors.black,
      expandedAlignment: Alignment.topLeft,
      title: Column(
        children: [
          Row(children: [
            ClipRRect(
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
            Container(
              child: Text(this.member.name!, style: TextStyle(fontSize: 18)),
              margin: EdgeInsets.all(8),
            )
          ]),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ],
      ),
      children: [
        FutureBuilder(
          future: _speakers,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Speaker> comps = snapshot.data as List<Speaker>;
              return Container(
                height: comps.length == 0 ? 0 : null,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: comps
                      .map((e) => ListViewCard(small: false, speaker: e))
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

  Widget _buildSmallTile() {
    return ExpansionTile(
      iconColor: Colors.transparent,
      initiallyExpanded: true,
      textColor: Colors.black,
      expandedAlignment: Alignment.topLeft,
      title: Column(
        children: [
          Row(children: [
            ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
                child: Image.network(
                  this.member.image,
                  width: 25,
                  height: 25,
                  errorBuilder: (BuildContext context, Object exception,
                      StackTrace? stackTrace) {
                    return Image.asset(
                      'assets/noImage.png',
                      width: 25,
                      height: 25,
                    );
                  },
                )),
            Container(
              child: Text(this.member.name!, style: TextStyle(fontSize: 12)),
              margin: EdgeInsets.all(8),
            )
          ]),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ],
      ),
      children: [
        FutureBuilder(
          future: _speakers,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Speaker> comps = snapshot.data as List<Speaker>;
              comps.forEach((element) {
                print(element.name);
              });
              return Container(
                height: comps.length == 0 ? 0 : 125,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: comps
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

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.all(10),
        child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 1500) {
                return _buildSmallTile();
              } else {
                return _buildBigTile();
              }
            })),
      );
}
