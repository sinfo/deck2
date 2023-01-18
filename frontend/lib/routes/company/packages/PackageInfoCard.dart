import 'package:flutter/material.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/routes/company/packages/PackageNotifier.dart';
import 'package:provider/provider.dart';

class PackageInfoCard extends StatelessWidget {
  EventPackage eventPackage;
  final bool small;
  PackageInfoCard({Key? key, required this.eventPackage, required this.small})
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
                            // TODO FIXME: edit package
                            // _editPackageModal(context);
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
            FutureBuilder(
              future: eventPackage.package,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  PackageNotifier notifier =
                      Provider.of<PackageNotifier>(context);

                  Package p = snapshot.data as Package;
                  notifier.add(p);

                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.monetization_on, size: 48),
                                Text(
                                  (p.price ~/ 100).toString() +
                                      "," +
                                      (p.price % 100).toString(),
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
                                  p.vat.toString() + '%',
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
                        if (p.items != null && p.items!.length > 0)
                          Text("Items:",
                              textAlign: TextAlign.left,
                              style: TextStyle(fontSize: 18)),
                        ...p.items!
                            .map((item) => getItemRepresentation(item))
                            .toList(),
                        Text("\nPrivate name: " + p.name,
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 18))
                      ]);
                } else {
                  return Container(
                      child: Center(child: CircularProgressIndicator()));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
