import 'package:flutter/material.dart';
import 'package:frontend/models/billing.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/routes/company/billing/BillingCard.dart';

class ParticipationBillingWidget extends StatelessWidget {
  final CompanyParticipation participation;
  final String id;
  final bool small;
  final void Function(String) onDelete;

  ParticipationBillingWidget(
      {Key? key,
      required this.participation,
      required this.small,
      required this.id,
      required this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: participation.billing,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error' + snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.done) {
          Billing? bill = snapshot.data as Billing?;

          if (bill == null) {
            return Container();
          }
          return BillingCard(
            billing: bill,
            small: small,
            id: id,
            onDelete: onDelete,
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
