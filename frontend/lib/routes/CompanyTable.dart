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
            return ListView.builder(
              itemCount: membs.length,
              itemBuilder: (context, index) {
                return MemberRow(member: membs[index]);
              },
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

class _MemberRowState extends State<MemberRow> {
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
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(children: [
              CircleAvatar(
                backgroundImage: NetworkImage(this.member.image),
              ),
              Text(this.member.name!),
            ]),
            Divider(
              color: Colors.grey,
              height: 20,
              thickness: 1,
            ),
            FutureBuilder(
              future: _companies,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<CompanyLight> comps =
                      snapshot.data as List<CompanyLight>;
                  return Container(
                    height: comps.length == 0 ? 0 : 300,
                    child: GridView.count(
                      crossAxisCount: 1,
                      scrollDirection: Axis.horizontal,
                      children: comps
                          .map((e) => ListViewCard(
                                company: e,
                              ))
                          .toList(),
                    ),
                  );
                } else {
                  return Container(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(),
                  );
                }
              },
            )
          ],
        ),
      );
}
