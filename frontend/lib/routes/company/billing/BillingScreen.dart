import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/routes/company/billing/AddBillingInfoForm.dart';
import 'package:frontend/routes/company/billing/EditBillingInfoForm.dart';
import 'package:frontend/routes/company/billing/participationBillingWidget.dart';

class BillingScreen extends StatefulWidget {
  final List<CompanyParticipation>? participations;
  final String id;
  final bool small;
  CompanyBillingInfo? billingInfo;

  BillingScreen(
      {Key? key,
      this.billingInfo,
      required this.participations,
      required this.small,
      required this.id})
      : super(key: key);

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String getBillingInfoRepr() {
    if (widget.billingInfo!.name != "" &&
        widget.billingInfo!.address != "" &&
        widget.billingInfo!.tin != "") {
      return "Name: " +
          widget.billingInfo!.name! +
          "\nAddress: " +
          widget.billingInfo!.address! +
          "\nTIN (NIF/Contribuinte): " +
          widget.billingInfo!.tin!;
    } else {
      return "No Billing Info :(";
    }
  }

  void _editBillingInfoModal(context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
            heightFactor: 0.7,
            child: Container(
              child: EditBillingInfoForm(
                  billingInfo: widget.billingInfo,
                  id: widget.id,
                  onBillingInfoEdit: (newBillingInfo) {
                    setState(() {
                      widget.billingInfo = newBillingInfo;
                    });
                  }),
            ));
      },
    );
  }

  Widget getBillingInfoAction() {
    if (widget.billingInfo!.name != "" &&
        widget.billingInfo!.address != "" &&
        widget.billingInfo!.tin != "") {
      return IconButton(
          onPressed: () {
            _editBillingInfoModal(context);
          },
          color: const Color(0xff5c7ff2),
          icon: Icon(Icons.edit));
    } else {
      return ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddBillingInfoForm(
                      id: widget.id,
                      onBillingInfoEdit: (newBillingInfo) {
                        setState(() {
                          widget.billingInfo = newBillingInfo;
                        });
                      }),
                ));
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff5c7ff2)),
          icon: Icon(Icons.add_circle_outline),
          label: Text("Add Billing Info"));
    }
  }

  Widget getBillingInfo() {
    return Container(
      width: 450,
      margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
      padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Billing Information (Dados de faturação)",
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: getBillingInfoAction()),
          ],
        ),
        Divider(
          color: Colors.grey[600],
        ),
        Text(getBillingInfoRepr(),
            textAlign: TextAlign.left, style: TextStyle(fontSize: 18)),
      ]),
    );
  }

  Widget getBillings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.participations!.reversed
              .where((element) => element.billingId != null)
              .map(
                (participation) => ParticipationBillingWidget(
                    participation: participation,
                    id: widget.id,
                    small: widget.small),
              )
              .toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
        padding: const EdgeInsets.all(8),
        child: ListView(children: [getBillingInfo(), getBillings()]));
  }
}
