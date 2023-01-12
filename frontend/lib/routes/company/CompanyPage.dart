import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/routes/company/CompanyListWidget.dart';
import 'package:frontend/routes/company/CompanyTable.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({Key? key}) : super(key: key);

  @override
  _CompanyPageState createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage>
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
              Tab(text: 'Companies by member'),
              Tab(text: 'All companies'),
            ],
          ),
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              CompanyTable(),
              CompanyListWidget()
            ]),
          ),
        ],
      );
    });
  }
}
