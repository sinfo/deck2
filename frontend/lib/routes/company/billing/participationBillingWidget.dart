import 'package:flutter/material.dart';
import 'package:frontend/models/billing.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/routes/company/billing/BillingCard.dart';

class ParticipationBillingWidget extends StatelessWidget {
  final CompanyParticipation participation;
  final String id;
  final bool small;

  ParticipationBillingWidget(
      {Key? key,
      required this.participation,
      required this.small,
      required this.id})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder(
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
            return Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('SINFO ${participation.event}'),
                ),
              ),
              Divider(),
              BillingCard(
                billing: bill,
                id: id,
              ),
            ]);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
