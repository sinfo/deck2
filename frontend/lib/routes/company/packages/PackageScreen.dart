import 'package:flutter/material.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/routes/company/packages/PackageInfoCard.dart';
import 'package:frontend/routes/company/packages/PackageNotifier.dart';
import 'package:provider/provider.dart';

class PackageScreen extends StatefulWidget {
  const PackageScreen({Key? key}) : super(key: key);

  @override
  _PackageScreenState createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Event event = Provider.of<EventNotifier>(context).event;

    return Consumer<PackageNotifier>(builder: (context, cart, child) {
      return LayoutBuilder(builder: (context, constraints) {
        bool small = constraints.maxWidth < App.SIZE;
        return ListView(
          children: event
              .eventPackagesId
              .map((p) => PackageInfoCard(eventPackage: p, small: small))
              .toList(),
        );
      });
    });
  }
}
