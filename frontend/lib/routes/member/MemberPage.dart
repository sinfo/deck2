import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/routes/member/MemberListWidget.dart';
import 'package:frontend/routes/teams/TeamsTable.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({Key? key}) : super(key: key);

  @override
  _MemberPageState createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Column(
        children: [
          TabBar(
            isScrollable: small,
            controller: _tabController,
            tabs: [
              Tab(text: 'Members by team'),
              Tab(text: 'All members'),
            ],
          ),
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              TeamTable(),
              MemberListWidget()
            ]),
          ),
        ],
      );
    });
  }
}
