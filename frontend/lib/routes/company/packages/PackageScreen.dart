import 'package:flutter/material.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/routes/company/packages/PackageInfoCard.dart';
import 'package:frontend/routes/company/packages/PackageNotifier.dart';
import 'package:frontend/services/packageService.dart';
import 'package:provider/provider.dart';

class PackageScreen extends StatefulWidget {
  const PackageScreen({Key? key}) : super(key: key);

  @override
  _PackageScreenState createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen>
    with AutomaticKeepAliveClientMixin {
  PackageService _packageService = PackageService();

  @override
  void initState() {
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  List<Future> getPackages(Event event) {
    List<Future> futures = [];
    for (EventPackage evPackage in event.eventPackagesId) {
      futures.add(_packageService.getPackage(evPackage.packageID));
    }
    return futures;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Event event = Provider.of<EventNotifier>(context).event;
    PackageNotifier notifier = Provider.of<PackageNotifier>(context);
    return FutureBuilder(
        future: Future.wait(getPackages(event)),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<dynamic> futurePacks = snapshot.data as List<dynamic>;
            List<Package> packs = [];

            for(int i = 0; i < futurePacks.length; i++) {
              Package p = futurePacks[i] as Package;
              packs.add(p);
            }
            
            notifier.loadPackages(packs);

            return LayoutBuilder(builder: (context, constraints) {
              bool small = constraints.maxWidth < App.SIZE;
              return ListView(
                children: event.eventPackagesId
                    .map((p) => PackageInfoCard(
                        eventPackage: p,
                        pack: notifier.getPackage(p.packageID)!,
                        small: small))
                    .toList(),
              );
            });
          } else {
            return Container(child: Center(child: CircularProgressIndicator()));
          }
        });
  }
}
