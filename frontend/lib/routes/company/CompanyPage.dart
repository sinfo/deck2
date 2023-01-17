import 'package:flutter/material.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/routes/company/CompanyListWidget.dart';
import 'package:frontend/routes/company/CompanyTable.dart';
import 'package:frontend/routes/company/packages/ItemPackagePage.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({Key? key}) : super(key: key);

  @override
  _CompanyPageState createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  bool get wantKeepAlive => true;

  Widget? _fabAtIndex(BuildContext context, int index) {
    print(index);
    switch (index) {
      case 0:
      case 1:
        {
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.AddCompany,
              );
            },
            label: const Text('Create New Company'),
            icon: const Icon(Icons.business),
          );
        }
      case 2:
        {
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.AddPackage,
              );
            },
            label: const Text('Create New Package'),
            icon: const Icon(Icons.sell),
          );
        }
    }
  }

  changeIndex(int index) {
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Scaffold(
        body: Column(
          children: [
            TabBar(
              isScrollable: small,
              controller: _tabController,
              tabs: [
                Tab(text: 'Companies by member'),
                Tab(text: 'All companies'),
                Tab(text: 'Items and Packages'),
              ],
              onTap: changeIndex,
            ),
            Expanded(
              child: TabBarView(controller: _tabController, children: [
                CompanyTable(),
                CompanyListWidget(),
                ItemPackagePage()
              ]),
            ),
          ],
        ),
        floatingActionButton: _fabAtIndex(context, _index),
      );
    });
  }
}
