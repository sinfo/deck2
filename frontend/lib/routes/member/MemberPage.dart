import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/routes/member/MemberListWidget.dart';
import 'package:frontend/routes/teams/TeamsTable.dart';
import 'package:frontend/services/authService.dart';
import 'package:provider/provider.dart';

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
    CustomAppBar _appBar = CustomAppBar(disableEventChange: true);
    return Scaffold(
      body: Stack(children: [
        Container(
            margin: EdgeInsets.fromLTRB(0, _appBar.preferredSize.height, 0, 0),
            child: LayoutBuilder(builder: (context, constraints) {
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
                    child: TabBarView(
                        controller: _tabController,
                        children: [TeamTable(), MemberListWidget()]),
                  ),
                ],
              );
            })),
        _appBar,
      ]),
      floatingActionButton: FutureBuilder(
          future: Provider.of<AuthService>(context).role,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Role r = snapshot.data as Role;

              if (r == Role.ADMIN || r == Role.COORDINATOR) {
                return FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        Routes.AddMember,
                      );
                    },
                    label: const Text('Create New Member'),
                    icon: const Icon(Icons.edit));
              } else
                return Container();
            } else
              return Container();
          }),
    );
  }
}
