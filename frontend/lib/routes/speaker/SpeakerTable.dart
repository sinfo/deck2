import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:frontend/components/filterbar.dart';
import 'package:frontend/models/participation.dart';

class SpeakerTable extends StatefulWidget {
  SpeakerTable({Key? key}) : super(key: key);

  @override
  _SpeakerTableState createState() => _SpeakerTableState();
}

class _SpeakerTableState extends State<SpeakerTable> {
  final MemberService _memberService = MemberService();
  late Future<List<Member>> members;
  late String _filter;

  @override
  void initState() {
    super.initState();
    members =
        _memberService.getMembers(event: App.localStorage.getInt("event"));
    _filter = "ALL";
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: members,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Member> membs = snapshot.data as List<Member>;
            membs.sort((a, b) => a.name!.compareTo(b.name!));
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

  onSelected(String filter) {
    setState(() {
      _filter = filter;
    });
  }
}

class MemberSpeakerRow extends StatefulWidget {
  final Member member;
  String filter;
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
    _speakers =
        _speakerService.getSpeakers(eventId: 29, member: this.member.id);
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildBigTile(String _filter) {
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
          title: Container(
            child: Text(this.member.name!),
            margin: EdgeInsets.all(8),
          ),
          subtitle: Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ),
        Row(
          children: [
            FutureBuilder(
              future: _speakers,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Speaker> spks = snapshot.data as List<Speaker>;
                  List<Speaker> spkscpy = filterListByStatus(spks, _filter);
                  return Container(
                    height: spkscpy.length == 0 ? 0 : null,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: spkscpy
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
        )
      ],
    );
  }

  Widget _buildSmallTile(String _filter) {
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
        Row(
          children: [
            FutureBuilder(
              future: _speakers,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Speaker> spks = snapshot.data as List<Speaker>;
                  List<Speaker> spkscpy = filterListByStatus(spks, _filter);
                  return Container(
                    height: spkscpy.length == 0 ? 0 : 125,
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
    String _filter = widget.filter;
    return Container(
      margin: EdgeInsets.all(10),
      child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 1500) {
              return _buildSmallTile(_filter);
            } else {
              return _buildBigTile(_filter);
            }
          })),
    );
  }
}
