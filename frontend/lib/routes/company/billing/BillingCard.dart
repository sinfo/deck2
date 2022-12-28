import 'package:flutter/material.dart';
import 'package:frontend/models/billing.dart';
import 'package:frontend/models/package.dart';

class BillingCard extends StatefulWidget {
  Billing billing;
  Package package;
  final String id;
  final int event;
  BillingCard(
      {Key? key,
      required this.billing,
      required this.package,
      required this.event,
      required this.id})
      : super(key: key);

  @override
  _BillingCardState createState() => _BillingCardState();
}

class _BillingCardState extends State<BillingCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> billingChangedCallback(BuildContext context,
      {Billing? billing, Package? package}) async {
    setState(() {
      if (billing != null) {
        widget.billing = billing;
      }
      if (package != null) {
        widget.package = package;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(5)),
        child: Text("TODO")
      ),
    );
  }
}
