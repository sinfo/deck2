import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/routes/company/CompanyTableNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/components/filterbar.dart';
import 'package:frontend/models/participation.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class CompanyTable extends StatefulWidget {
  const CompanyTable({Key? key}) : super(key: key);

  @override
  _CompanyTableState createState() => _CompanyTableState();
}

class _CompanyTableState extends State<CompanyTable>
    with AutomaticKeepAliveClientMixin {
  final MemberService _memberService = MemberService();
  final CompanyService _companyService = CompanyService();
  late ParticipationStatus _filter;

  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _filter = ParticipationStatus.NO_STATUS;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    int event = Provider.of<EventNotifier>(context).event.id;

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
      body: FutureBuilder(
        key: ValueKey(event),
        future: Future.wait([
          _memberService.getMembers(event: event),
          _companyService.getCompanies(event: event)
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
            CompanyTableNotifier notifier =
                Provider.of<CompanyTableNotifier>(context);
            List<List<Object>> data = snapshot.data as List<List<Object>>;
            notifier.companies = data[1] as List<Company>;
            List<Member> membs = data[0] as List<Member>;
            Member me = Provider.of<Member?>(context)!;
            membs.sort((a, b) => a.name!.compareTo(b.name!));
            int index = membs.indexWhere((element) => element.id == me.id);
            if (index != -1) {
              membs.insert(0, membs.removeAt(index));
            }

            return RefreshIndicator(
              onRefresh: () => Future.delayed(Duration.zero, () {
                setState(() {});
              }),
              child: ListView.builder(
                itemCount: membs.length,
                itemBuilder: (context, index) =>
                    MemberCompanyRow(member: membs[index], filter: _filter),
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
                itemBuilder: (context, index) => MemberCompanyRow.fake(),
                addAutomaticKeepAlives: true,
                physics: const AlwaysScrollableScrollPhysics(),
              ),
            );
          }
        },
      ),
    );
  }

  onSelected(ParticipationStatus filter) {
    setState(() {
      _filter = filter;
    });
  }
}

class MemberCompanyRow extends StatelessWidget {
  final Member member;
  final ParticipationStatus filter;
  const MemberCompanyRow({Key? key, required this.member, required this.filter})
      : super(key: key);

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
    int event = Provider.of<EventNotifier>(context).event.id;

    List<Company> companies = Provider.of<CompanyTableNotifier>(context)
        .getByMember(member.id, event, filter);
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
                        this.member.image!,
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
                    this.member.name,
                    style: TextStyle(fontSize: small ? 14 : 18),
                  ),
                  subtitle: Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                ),
                small
                    ? Container(
                        height: companies.length == 0 ? 0 : 175,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: companies
                              .map((e) => ListViewCard(small: true, company: e))
                              .toList(),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: companies.length == 0 ? 0 : null,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                children: companies
                                    .map((e) =>
                                        ListViewCard(small: false, company: e))
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
