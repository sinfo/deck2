import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/filterbar.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class CompanyTable extends StatefulWidget {
  CompanyTable({Key? key}) : super(key: key);

  @override
  _CompanyTableState createState() => _CompanyTableState();
}

class _CompanyTableState extends State<CompanyTable>
    with AutomaticKeepAliveClientMixin {
  final MemberService _memberService = MemberService();
  late String _filter;
  late Future<List<Member>> _members;

  @override
  void initState() {
    super.initState();
    _members =
        _memberService.getMembers(event: App.localStorage.getInt('event'));
    _filter = "ALL";
  }

  @override
  bool get wantKeepAlive => true;

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
            body: ListView.builder(
              itemCount: membs.length,
              itemBuilder: (context, index) =>
                  MemberCompaniesRow(member: membs[index], filter: _filter),
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

class MemberCompaniesRow extends StatefulWidget {
  final Member member;
  final String filter;
  MemberCompaniesRow({Key? key, required this.member, required this.filter})
      : super(key: key);

  @override
  _MemberCompaniesRowState createState() =>
      _MemberCompaniesRowState(member: member, filter: filter);
}

class _MemberCompaniesRowState extends State<MemberCompaniesRow>
    with AutomaticKeepAliveClientMixin {
  Member member;
  String filter;
  CompanyService _companyService = CompanyService();
  late Future<List<Company>> _companies;
  _MemberCompaniesRowState({required this.member, required this.filter});
  int? size = null;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _companies = _companyService.getCompanies(
        event: App.localStorage.getInt('event'), member: this.member.id);
  }

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
          title: Text(this.member.name!, style: TextStyle(fontSize: 18)),
          subtitle: Divider(
            color: Colors.grey,
            thickness: 1,
          ),
          onTap: () {
            print('pressedMember');
          },
        ),
        FutureBuilder(
          future: _companies,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Company> comps = snapshot.data as List<Company>;
              List<Company> compscpy =
                  filterListByStatus(comps, _filter, event);
              compscpy.sort((a, b) => STATUSORDER[a.participations!
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
                      height: compscpy.length == 0 ? 0 : null,
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: compscpy
                            .map((e) => ListViewCard(small: false, company: e))
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
          future: _companies,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Company> comps = snapshot.data as List<Company>;
              List<Company> compscpy =
                  filterListByStatus(comps, _filter, event);
              compscpy.sort((a, b) => STATUSORDER[a.participations!
                      .firstWhere((element) => element.event == event)
                      .status]!
                  .compareTo(STATUSORDER[b.participations!
                      .firstWhere((element) => element.event == event)
                      .status]!));
              return Container(
                height: compscpy.length == 0 ? 0 : 175,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: compscpy
                      .map((e) => ListViewCard(small: true, company: e))
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

  List<Company> filterListByStatus(List comps, String _filter, int event) {
    List<Company> compscpy = [];
    if (_filter != "ALL") {
      for (Company c in comps) {
        CompanyParticipation p =
            c.participations!.firstWhere((element) => element.event == event);
        String s = STATUSSTRING[p.status]!;
        if (s == _filter) compscpy.add(c);
      }
    } else {
      compscpy = List.from(comps);
    }
    return compscpy;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    String _filter = widget.filter;
    ThemeData t = Provider.of<ThemeNotifier>(context).theme;
    return Container(
        margin: EdgeInsets.all(10),
        child: Theme(
          data: t.copyWith(dividerColor: Colors.transparent),
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < App.SIZE) {
              return _buildSmallTile(context, _filter);
            } else {
              return _buildBigTile(context, _filter);
            }
          }),
        ));
  }
}
