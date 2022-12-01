import 'package:flutter/material.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/models/company.dart';

class BillingInfoScreen extends StatefulWidget {
  final CompanyBillingInfo? billingInfo;

  const BillingInfoScreen({Key? key, this.billingInfo}) : super(key: key);

  @override
  _BillingInfoScreenState createState() => _BillingInfoScreenState();
}

class _BillingInfoScreenState extends State<BillingInfoScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.billingInfo == null) {
      return Container(
        child: Center(child: Text('Company without Billing Info :(')),
      );
    } else {
      String body = "";
      widget.billingInfo!.name != null
          ? body += "Name: " + widget.billingInfo!.name! + "\n"
          : "";
      widget.billingInfo!.address != null
          ? body += "Address: " + widget.billingInfo!.name! + "\n"
          : "";
      widget.billingInfo!.tin != null
          ? body += "NIF/Contribuinte: " + widget.billingInfo!.tin! + "\n"
          : "";
      return EditableCard(
          title: "Billing Information",
          body: body,
          bodyEditedCallback: (newBillingInfo) {
            // TODO: Finish this
            print(newBillingInfo);
            return Future.delayed(Duration.zero);
          });
    }
  }
}
