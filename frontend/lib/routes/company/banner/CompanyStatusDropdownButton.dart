import 'package:flutter/material.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/services/companyService.dart';

class CompanyStatusDropdownButton extends StatelessWidget {
  final void Function(int, BuildContext) statusChangeCallback;
  final ParticipationStatus companyStatus;
  final String companyId;
  final CompanyService _companyService = CompanyService();

  CompanyStatusDropdownButton({
    Key? key,
    required this.statusChangeCallback,
    required this.companyStatus,
    required this.companyId,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _companyService.getNextParticipationSteps(id: companyId),
      builder: (context, snapshot) {
        List<ParticipationStep> steps = [
          ParticipationStep(next: companyStatus, step: 0)
        ];
        if (snapshot.hasData) {
          steps.addAll(snapshot.data as List<ParticipationStep>);
        }
        return Container(
          child: DropdownButton<ParticipationStep>(
            underline: Container(
              height: 3,
              decoration: BoxDecoration(color: STATUSCOLOR[companyStatus]),
            ),
            value: steps[0],
            style: Theme.of(context).textTheme.subtitle2,
            selectedItemBuilder: (BuildContext context) {
              return steps.map((e) {
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(child: Text(STATUSSTRING[e.next]!)),
                );
              }).toList();
            },
            items: steps
                .map((e) => DropdownMenuItem<ParticipationStep>(
                      value: e,
                      child: Text(STATUSSTRING[e.next] ?? ''),
                    ))
                .toList(),
            onChanged: (next) {
              if (next != null && next.step != 0) {
                statusChangeCallback(next.step, context);
              }
            },
          ),
        );
      },
    );
  }
}