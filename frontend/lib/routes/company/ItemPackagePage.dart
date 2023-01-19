import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/routes/company/items/AddItemForm.dart';
import 'package:frontend/routes/company/packages/AddPackageForm.dart';
import 'package:frontend/routes/company/items/ItemScreen.dart';
import 'package:frontend/routes/company/packages/PackageScreen.dart';
import 'package:frontend/services/authService.dart';
import 'package:provider/provider.dart';

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
    return FutureBuilder(
        future: Provider.of<AuthService>(context).role,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Role r = snapshot.data as Role;

            if (r == Role.ADMIN || r == Role.COORDINATOR) {
              switch (_index) {
                case 0:
                  return FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(context, SlideRoute(page: AddItemForm()));
                    },
                    label: const Text('Create new Item'),
                    icon: const Icon(Icons.add_shopping_cart),
                  );
                case 1:
                  return FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddPackageForm()));
                    },
                    label: const Text('Create new Package'),
                    icon: const Icon(Icons.add_business),
                  );
                default:
                  return Container();
              }
            } else {
              return Container();
            }
          } else {
            return Container();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    int eventId = Provider.of<EventNotifier>(context).event.id;
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
                        Tab(text: 'SINFO ${eventId} Items'),
                        Tab(text: 'SINFO ${eventId} Packages'),
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
