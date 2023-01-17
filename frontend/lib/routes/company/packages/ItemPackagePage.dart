import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/main.dart';
import 'package:frontend/routes/company/packages/AddItemForm.dart';
import 'package:frontend/routes/company/packages/AddPackageForm.dart';
import 'package:frontend/routes/company/packages/ItemScreen.dart';
import 'package:frontend/routes/company/packages/PackageScreen.dart';

class ItemPackagePage extends StatefulWidget {
  const ItemPackagePage({Key? key}) : super(key: key);

  @override
  _ItemPackagePageState createState() => _ItemPackagePageState();
}

class _ItemPackagePageState extends State<ItemPackagePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  CustomAppBar appBar = CustomAppBar(disableEventChange: true);
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabIndex);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabIndex() {
    setState(() {
      _index = _tabController.index;
    });
  }

  Widget? _fabAtIndex(BuildContext context) {
    switch (_index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AddItemForm()));
          },
          label: const Text('Create new Item'),
          icon: const Icon(Icons.add_shopping_cart),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AddPackageForm()));
          },
          label: const Text('Create new Package'),
          icon: const Icon(Icons.add_business),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
          Container(
              margin: EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
              child: LayoutBuilder(builder: (context, constraints) {
                bool small = constraints.maxWidth < App.SIZE;
                return Column(
                  children: [
                    TabBar(
                      isScrollable: small,
                      controller: _tabController,
                      tabs: [
                        Tab(text: 'Items'),
                        Tab(text: 'Packages'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                          controller: _tabController,
                          children: [ItemScreen(), PackageScreen()]),
                    ),
                  ],
                );
              })),
          appBar,
        ]),
        floatingActionButton: _fabAtIndex(context));
  }
}
