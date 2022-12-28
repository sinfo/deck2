import 'package:flutter/material.dart';
import 'package:frontend/models/billing.dart';

class BillingCard extends StatefulWidget {
  Billing billing;
  final String id;
  BillingCard({Key? key, required this.billing, required this.id})
      : super(key: key);

  @override
  _BillingCardState createState() => _BillingCardState();
}

class _BillingCardState extends State<BillingCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> billingChangedCallback(BuildContext context,
      {Billing? billing}) async {
    setState(() {
      widget.billing = billing!;
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
          child: Text(widget.billing.toString())),
    );
  }
}
