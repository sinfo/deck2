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
  MemberService memberService = MemberService();
  late Future<List<Member>> members;

  @override
  void initState() {
    // FIXME: Add a global way to keep current event
    members = memberService.getMembers(event: 29);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: members,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Member> membs = snapshot.data as List<Member>;
            return ListView(
              children:
                  membs.map((e) => MemberCompaniesRow(member: e)).toList(),
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      );
}

class MemberCompaniesRow extends StatelessWidget {
  final Member member;
  final CompanyService companyService = CompanyService();
  late Future<List<CompanyLight>> companies;

  MemberCompaniesRow({Key? key, required this.member}) : super(key: key) {
    this.companies =
        companyService.getCompanies(event: 29, member: this.member.id);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: companies,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<CompanyLight> comps = snapshot.data as List<CompanyLight>;

          return Scaffold(
            body: GridView.count(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.all(10),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
              children: comps.map((e) => ListViewCard(company: e)).toList(),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                //TODO: on tap
                // Add your onPressed code here!
              },
              child: const Icon(Icons.add),
              backgroundColor: Color.fromRGBO(92, 127, 242, 1),
            ),
          );
        } else {
          return CircularProgressIndicator();
        }
      });
}
