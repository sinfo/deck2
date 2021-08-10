import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/ListViewCard.dart';
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

  @override
  void initState() {
    super.initState();
    //TODO: Dynamic event
    members = _memberService.getMembers(event: 29);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: members,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Member> membs = snapshot.data as List<Member>;
            membs.sort((a, b) => a.name!.compareTo(b.name!));
            return ListView(
              children: membs.map((e) => MemberRow(member: e)).toList(),
              addAutomaticKeepAlives: true,
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      );
}

class MemberRow extends StatefulWidget {
  final Member member;
  MemberRow({Key? key, required this.member}) : super(key: key);

  @override
  _MemberRowState createState() => _MemberRowState(member: member);
}

class _MemberRowState extends State<MemberRow>
    with AutomaticKeepAliveClientMixin {
  Member member;
  CompanyService _companyService = CompanyService();
  late Future<List<CompanyLight>> _companies;
  _MemberRowState({required this.member});

  @override
  void initState() {
    super.initState();
    _companies =
        _companyService.getCompanies(event: 29, member: this.member.id);
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildWrap(List<CompanyLight> comps) {
    return Container(
      height: comps.length == 0 ? 0 : null,
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: comps.map((e) => ListViewCard(company: e)).toList(),
      ),
    );
  }

  Widget _buildListView(List<CompanyLight> comps) {
    return Container(
      height: comps.length == 0 ? 0 : 125,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: comps.map((e) => ListViewCard(company: e)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              ClipRRect(
                  borderRadius: BorderRadius.all(
                      Radius.circular(5.0)), //add border radius here
                  child: LayoutBuilder(builder: (context, constraints) {
                    MediaQueryData data = MediaQuery.of(context);

                    if (data.orientation == Orientation.portrait ||
                        data.size.width < 1500) {
                      return Image.network(
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
                      );
                    } else {
                      return Image.network(
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
                      );
                    }
                  })),
              Container(
                child: LayoutBuilder(builder: (context, constraints) {
                  MediaQueryData data = MediaQuery.of(context);

                  if (data.orientation == Orientation.portrait ||
                      data.size.width < 1500) {
                    return Text(this.member.name!,
                        style: TextStyle(fontSize: 12));
                  } else {
                    return Text(this.member.name!,
                        style: TextStyle(fontSize: 18));
                  }
                }),
                margin: EdgeInsets.all(8),
              )
            ]),
            LayoutBuilder(builder: (context, constraints) {
              MediaQueryData data = MediaQuery.of(context);

              if (data.orientation == Orientation.portrait ||
                  data.size.width < 1500) {
                return Divider(
                  color: Colors.grey,
                  height: 10,
                  thickness: 1,
                );
              } else {
                return Divider(
                  color: Colors.grey,
                  height: 20,
                  thickness: 1,
                );
              }
            }),
            FutureBuilder(
              future: _companies,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<CompanyLight> comps =
                      snapshot.data as List<CompanyLight>;
                  return LayoutBuilder(builder: (context, constraints) {
                    MediaQueryData data = MediaQuery.of(context);

                    if (data.orientation == Orientation.portrait ||
                        data.size.width < 1500) {
                      return _buildListView(comps);
                    } else {
                      return _buildWrap(comps);
                    }
                  });
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
        ),
      );
}
