import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/components/filterbar.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/memberService.dart';

class CompanyTable extends StatefulWidget {
  CompanyTable({Key? key}) : super(key: key);

  @override
  _CompanyTableState createState() => _CompanyTableState();
}

class _CompanyTableState extends State<CompanyTable> {
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
            return 
              Column(
                children: <Widget>[
                  FilterBar(onSelected: (value) => onSelected(value)),
                  Expanded(
                    child: ListView(
                      children: membs
                          .map((e) =>
                              MemberCompaniesRow(member: e, filter: _filter))
                          .toList(),
                      addAutomaticKeepAlives: true,
                    ),
                  ),
                ],
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

class MemberCompaniesRow extends StatefulWidget {
  final Member member;
  String filter;
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
  late Future<List<CompanyLight>> _companies;
  _MemberCompaniesRowState({required this.member, required this.filter});

  @override
  void initState() {
    super.initState();
    _companies =
        _companyService.getCompaniesLight(event: 29, member: this.member.id);
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildBigTile(String _filter) {
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
          future: _companies,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<CompanyLight> comps = snapshot.data as List<CompanyLight>;
              List<CompanyLight> compscpy = filterListByStatus(comps, _filter);
              return Container(
                height: compscpy.length == 0 ? 0 : null,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: compscpy
                      .map((e) => ListViewCard(small: false, company: e))
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

  Widget _buildSmallTile(String _filter) {
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
          future: _companies,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<CompanyLight> comps = snapshot.data as List<CompanyLight>;
              List<CompanyLight> compscpy = filterListByStatus(comps, _filter);
              return Container(
                height: compscpy.length == 0 ? 0 : 200,
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

  List<CompanyLight> filterListByStatus(List comps, String _filter) {
    List<CompanyLight> compscpy = [];
    if (_filter != "ALL") {
      for (CompanyLight c in comps) {
        String s = c.participationStatus!.toUpperCase();
        if (s == _filter) compscpy.add(c);
      }
    } else {
      compscpy = List.from(comps);
    }
    return compscpy;
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
