import 'package:flutter/material.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/participationCard.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/models/participation.dart';
import 'package:provider/provider.dart';

class ParticipationList extends StatelessWidget {
  final Company company;
  final Future<void> Function(Map<String, dynamic>) onParticipationChanged;
  final Future<void> Function(ParticipationStatus) onChangePartStatus;
  final Future<void> Function(Package) onChangeCompanyPack;
  final void Function() onParticipationDeleted;
  final void Function() onParticipationAdded;
  const ParticipationList({
    Key? key,
    required this.company,
    required this.onParticipationChanged,
    required this.onParticipationAdded,
    required this.onParticipationDeleted,
    required this.onChangePartStatus,
    required this.onChangeCompanyPack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool small = constraints.maxWidth < App.SIZE;
        if (company.participations != null) {
          if (company
                  .participations![company.participations!.length - 1].event ==
              Provider.of<EventNotifier>(context).latest.id) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: ListView(
                  children: company.participations!.reversed
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ParticipationCard(
                              participation: e,
                              small: small,
                              type: CardType.COMPANY,
                              onEdit: onParticipationChanged,
                              onDelete: onParticipationDeleted,
                              onChangeParticipationStatus: onChangePartStatus,
                              onChangeCompanyPackage: onChangeCompanyPack,
                            ),
                          ))
                      .toList(),
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ParticipationCard.addParticipationCard(
                          onParticipationAdded),
                    ),
                    ...company.participations!.reversed
                        .map((e) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ParticipationCard(
                                  participation: e,
                                  small: small,
                                  type: CardType.COMPANY),
                            ))
                        .toList(),
                  ],
                ),
              ),
            );
          }
        } else {
          return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ParticipationCard.addParticipationCard(onParticipationAdded)
              )
            );
        }
      },
    );
  }
}
