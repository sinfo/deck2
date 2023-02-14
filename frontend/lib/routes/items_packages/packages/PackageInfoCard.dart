import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/routes/items_packages/packages/EditPackageForm.dart';
import 'package:frontend/routes/items_packages/packages/PackageNotifier.dart';
import 'package:frontend/services/eventService.dart';
import 'package:frontend/services/packageService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PackageInfoCard extends StatelessWidget {
  EventPackage eventPackage;
  Package pack;
  final bool small;
  NumberFormat formatter = new NumberFormat("00");

  PackageInfoCard(
      {Key? key,
      required this.eventPackage,
      required this.small,
      required this.pack})
      : super(key: key);

  Widget getItemRepresentation(PackageItem pi) {
    return FutureBuilder(
        future: pi.item,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Item? i = snapshot.data as Item?;

            return Container(
                margin: EdgeInsets.fromLTRB(17, 0, 17, 4),
                child: Row(
                  children: [
                    Expanded(
                        child: Text("\u2022 " + i!.name,
                            style: TextStyle(fontSize: 18))),
                    Expanded(
                        child: Text(
                            "Quantity: " +
                                pi.quantity.toString() +
                                " Public: " +
                                pi.public.toString(),
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 18)))
                  ],
                ));
          } else {
            return LinearProgressIndicator();
          }
        });
  }

  void _deletePackageDialog(mainContext) {
    showDialog(
      context: mainContext,
      builder: (BuildContext secondaryContext) {
        return BlurryDialog(
            'Warning', 'Are you sure you want to delete package ${pack.name}?',
            () {
          _deletePackage(secondaryContext);
        });
      },
    );
  }

  void _deletePackage(context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Deleting package...', style: TextStyle(color: Colors.white))),
    );

    EventService _eventService = EventService();
    Event? e = await _eventService.removePackageFromEvent(template: pack.id);

    if (e != null) {
      EventNotifier eventNotifier =
          Provider.of<EventNotifier>(context, listen: false);

      eventNotifier.event = e;

      PackageService _packageService = PackageService();
      Package? p = await _packageService.deletePackage(pack.id);
      if (p != null) {
        PackageNotifier notifier =
            Provider.of<PackageNotifier>(context, listen: false);
        notifier.remove(p);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Done', style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occured.',
                  style: TextStyle(color: Colors.white))),
        );
      }
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: package not deleted from current event',
                style: TextStyle(color: Colors.white))),
      );
    }
  }

  void _editPackageModal(context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
            heightFactor: 0.7,
            child: Container(
              child: EditPackageForm(eventPackage: eventPackage, package: pack),
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Public Name: " + eventPackage.publicName,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: small ? 16 : 22,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                          onPressed: () {
                            _editPackageModal(context);
                          },
                          color: const Color(0xff5c7ff2),
                          icon: Icon(Icons.edit)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                          onPressed: () {
                            // TODO FIXME: delete package
                            // _deletePackageDialog(context);
                          },
                          color: Colors.red,
                          icon: Icon(Icons.delete)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          color: eventPackage.available
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                        padding: EdgeInsets.all(small ? 4.0 : 8.0),
                        child: Text(
                          eventPackage.available
                              ? "Package available"
                              : "Package not available",
                          style: TextStyle(
                              fontSize: small ? 12 : 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
            Divider(
              color: Colors.grey[600],
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(Icons.monetization_on, size: 48),
                      Text(
                        (pack.price ~/ 100).toString() +
                            "." +
                            formatter.format(pack.price % 100),
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Price',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.receipt_long, size: 48),
                      Text(
                        pack.vat.toString() + '%',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'VAT (IVA)',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              if (pack.items != null && pack.items!.length > 0)
                Text("Items:",
                    textAlign: TextAlign.left, style: TextStyle(fontSize: 18)),
              ...pack.items!
                  .map((item) => getItemRepresentation(item))
                  .toList(),
              Text("\nPrivate name: " + pack.name,
                  textAlign: TextAlign.left, style: TextStyle(fontSize: 18))
            ]),
          ],
        ),
      ),
    );
  }
}
