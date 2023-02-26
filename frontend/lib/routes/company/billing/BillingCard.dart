import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/models/billing.dart';
import 'package:frontend/routes/company/billing/editBillingForm.dart';
import 'package:intl/intl.dart';

class BillingCard extends StatefulWidget {
  Billing billing;
  final String id;
  final bool small;
  final void Function(String) onDelete;

  BillingCard(
      {Key? key,
      required this.billing,
      required this.id,
      required this.small,
      required this.onDelete})
      : super(key: key);

  @override
  _BillingCardState createState() => _BillingCardState();
}

class _BillingCardState extends State<BillingCard>
    with AutomaticKeepAliveClientMixin {
  late NumberFormat formatter;

  @override
  void initState() {
    super.initState();
    formatter = new NumberFormat("00");
  }

  @override
  bool get wantKeepAlive => true;

  void _editBillingModal(context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
            heightFactor: 0.7,
            child: Container(
              child: EditBillingForm(
                  billing: widget.billing,
                  onBillingEdit: (context, _billing) {
                    billingChangedCallback(context, billing: _billing);
                  }),
            ));
      },
    );
  }

  void _deleteBillingDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog('Warning',
            'Are you sure you want to delete SINFO ${widget.billing.event} billing?',
            () {
          widget.onDelete(widget.billing.id);
        });
      },
    );
  }

  Future<void> billingChangedCallback(BuildContext context,
      {Billing? billing}) async {
    setState(() {
      widget.billing = billing!;
    });
  }

  Widget getStatusRow(bool val, String description) {
    return Wrap(
      children: [
        val
            ? Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.cancel, color: Colors.red),
        Text(description, style: TextStyle(fontSize: 16))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "SINFO " + widget.billing.event.toString() + " billing",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                        onPressed: () {
                          _editBillingModal(context);
                        },
                        color: const Color(0xff5c7ff2),
                        icon: Icon(Icons.edit)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                        onPressed: () {
                          _deleteBillingDialog(context);
                        },
                        color: Colors.red,
                        icon: Icon(Icons.delete)),
                  ),
                ],
              )
            ],
          ),
          Divider(
            color: Colors.grey[600],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Icon(Icons.request_quote, size: 48),
                      Text(
                        widget.billing.invoiceNumber,
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Invoice Number",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Icon(Icons.schedule, size: 48),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm')
                            .format(widget.billing.emission),
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Billing emission date",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.monetization_on, size: 48),
                    Text(
                      (widget.billing.value ~/ 100).toString() +
                          "." +
                          formatter.format(widget.billing.value % 100),
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      "Cost",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: [
              getStatusRow(widget.billing.status.invoice, "Invoice"),
              getStatusRow(widget.billing.status.proForma, "ProForma"),
              getStatusRow(widget.billing.status.paid, "Paid"),
              getStatusRow(widget.billing.status.receipt, "Receipt"),
            ],
          ),
          widget.billing.notes != ""
              ? Flexible(
                  child: Text("Billing notes: " + widget.billing.notes,
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 18)))
              : Container(),
        ],
      ),
    );
  }
}
