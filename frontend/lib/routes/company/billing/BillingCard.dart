import 'package:flutter/material.dart';
import 'package:frontend/models/billing.dart';
import 'package:intl/intl.dart';

class BillingCard extends StatefulWidget {
  Billing billing;
  final String id;
  final bool small;
  BillingCard(
      {Key? key, required this.billing, required this.id, required this.small})
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

  Widget getStatusRow(bool val, String description) {
    return Row(
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
              Text("SINFO " + widget.billing.event.toString() + " billing",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: widget.small ? 16 : 22,
                      fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                        onPressed: () {
                          // _editFlightModal(context);
                        },
                        color: const Color(0xff5c7ff2),
                        icon: Icon(Icons.edit)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                        onPressed: () {
                          // _deleteFlightDialog(context);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  getStatusRow(widget.billing.status.invoice, "Invoice"),
                  getStatusRow(widget.billing.status.proForma, "ProForma"),
                  getStatusRow(widget.billing.status.paid, "Paid"),
                  getStatusRow(widget.billing.status.receipt, "Receipt"),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.request_quote, color: Colors.black, size: 48),
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
              Column(
                children: [
                  Icon(Icons.schedule, color: Colors.black, size: 48),
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
              Column(
                children: [
                  Icon(Icons.monetization_on, color: Colors.black, size: 48),
                  Text(
                    (widget.billing.value ~/ 100).toString() +
                        "," +
                        (widget.billing.value % 100).toString(),
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
          widget.billing.notes != ""
              ? Text("Billing notes: " + widget.billing.notes,
                  textAlign: TextAlign.left, style: TextStyle(fontSize: 18))
              : Container(),
        ],
      ),
    );
  }
}
