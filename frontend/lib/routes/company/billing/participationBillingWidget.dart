import 'package:flutter/material.dart';
import 'package:frontend/models/billing.dart';
import 'package:frontend/models/package.dart';
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
        future: Future.wait([participation.billing, participation.package]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error');
          }
          if (snapshot.connectionState == ConnectionState.done) {
            List<dynamic> data = snapshot.data as List<dynamic>;

            Billing? bill = data[0] as Billing?;
            Package? pack = data[1] as Package?;

            if (bill == null || pack == null) {
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
                package: pack,
                event: participation.event,
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
