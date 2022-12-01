import 'package:flutter/material.dart';
import 'package:frontend/components/participationCard.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/speaker.dart';

class ParticipationList extends StatefulWidget {
  final Speaker speaker;
  final Future<void> Function(Map<String, dynamic>) onParticipationChanged;
  final void Function() onParticipationDeleted;
  const ParticipationList({
    Key? key,
    required this.speaker,
    required this.onParticipationChanged,
    required this.onParticipationDeleted,
  }) : super(key: key);

  @override
  _ParticipationListState createState() => _ParticipationListState();
}

class _ParticipationListState extends State<ParticipationList>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        bool small = constraints.maxWidth < App.SIZE;
        if (widget.speaker.participations != null) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: ListView(
                controller: ScrollController(),
                children: widget.speaker.participations!.reversed
                    .map((e) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ParticipationCard(
                            participation: e,
                            small: small,
                            type: CardType.SPEAKER,
                            onEdit: widget.onParticipationChanged,
                            onDelete: widget.onParticipationDeleted,
                          ),
                        ))
                    .toList(),
              ),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}
