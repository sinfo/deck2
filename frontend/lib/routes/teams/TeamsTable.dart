import 'package:flutter/material.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/routes/teams/TeamScreen.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/teamService.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class TeamTable extends StatefulWidget {
  TeamTable({Key? key}) : super(key: key);

  @override
  _TeamTableState createState() => _TeamTableState();
}

class _TeamTableState extends State<TeamTable>
    with AutomaticKeepAliveClientMixin {
  final TeamService _teamService = TeamService();
  late Future<List<Team>> teams;

  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return NestedScrollView(
      floatHeaderSlivers: true,
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
          ),
        ),
      ],
      body: FutureBuilder(
        future: Future.wait([
          _teamService.getTeams(
              event: Provider.of<EventNotifier>(context).event.id)
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('An error has occured. Please contact the admins'),
                  duration: Duration(seconds: 4),
                ),
              );
              return Center(
                  child: Icon(
                Icons.error,
                size: 200,
              ));
            }

            List<List<Object>> data = snapshot.data as List<List<Object>>;

            List<Team> tms = data[0] as List<Team>;

            tms.sort((a, b) => a.name!.compareTo(b.name!));

            return RefreshIndicator(
              onRefresh: () {
                return Future.delayed(Duration.zero, () {
                  setState(() {});
                });
              },
              child: ListView.builder(
                itemCount: tms.length,
                itemBuilder: (context, index) =>
                    TeamMemberRow(team: tms[index]),
                addAutomaticKeepAlives: true,
                physics: const AlwaysScrollableScrollPhysics(),
              ),
            );
          } else {
            return Shimmer.fromColors(
              baseColor: Colors.grey[400]!,
              highlightColor: Colors.white,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => TeamMemberRow.fake(),
                addAutomaticKeepAlives: true,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
              ),
            );
          }
        },
      ),
    );
  }
}

class TeamMemberRow extends StatelessWidget {
  final Team team;
  final MemberService _memberService = MemberService();
  TeamMemberRow({Key? key, required this.team}) : super(key: key);

  static Widget fake() {
    return Container(
      margin: EdgeInsets.all(10),
      child: LayoutBuilder(builder: (context, constraints) {
        bool small = constraints.maxWidth < App.SIZE;

        return Column(
          children: [
            ListTile(
              leading: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  child: Container(
                    color: Colors.grey,
                    child: SizedBox(
                      width: small ? 40 : 50,
                      height: small ? 40 : 50,
                    ),
                  )),
              subtitle: Divider(
                color: Colors.grey,
                thickness: 1,
              ),
            ),
            small
                ? Container(
                    height: 175,
                    child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: List.filled(8, ListViewCard.fakeCard())),
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          child: Wrap(
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              children:
                                  List.filled(8, ListViewCard.fakeCard())),
                        ),
                      ),
                    ],
                  )
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Future<Member?>> _futureMembers = team.members!
        .map((m) => _memberService.getMember(m.memberID!))
        .toList();

    return FutureBuilder(
        future: Future.wait(_futureMembers),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Member?> membs = snapshot.data as List<Member?>;
            membs.sort((a, b) => a!.name.compareTo(b!.name));

            return Container(
              margin: EdgeInsets.all(10),
              child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: LayoutBuilder(builder: (context, constraints) {
                    bool small = constraints.maxWidth < App.SIZE;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TeamScreen(
                                        team: team, members: membs)));
                          },
                          child: Column(
                            children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Text(this.team.name!,
                                    style:
                                        TextStyle(fontSize: small ? 14 : 18)),
                                margin: EdgeInsets.fromLTRB(0, 8, 8, 0),
                              ),
                              Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ],
                          ),
                        ),
                        small
                            ? Container(
                                height: membs.length == 0 ? 0 : 175,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: membs
                                      .map((e) =>
                                          ListViewCard(small: true, member: e))
                                      .toList(),
                                ),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      height: membs.length == 0 ? 0 : null,
                                      child: Wrap(
                                        alignment: WrapAlignment.start,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.start,
                                        children: membs
                                            .map((e) => ListViewCard(
                                                small: false, member: e))
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
        });
  }
}
