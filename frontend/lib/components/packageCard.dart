import 'package:flutter/material.dart';
import 'package:frontend/models/package.dart';

class PackageCard extends StatefulWidget {
  Package package;

  PackageCard({Key? key, required this.package}) : super(key: key);

  @override
  _PackageCardState createState() => _PackageCardState();
}

class _PackageCardState extends State<PackageCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Package: " + widget.package.name!,
              style: TextStyle(fontSize: 16)),
          Text(
              "Price: " +
                  (widget.package.price! ~/ 100).toString() +
                  "," +
                  (widget.package.price! % 100).toString(),
              style: TextStyle(fontSize: 16)),
          Text("VAT: " + widget.package.vat.toString(),
              style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
