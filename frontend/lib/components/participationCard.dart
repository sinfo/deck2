import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/participation.dart';

enum CardType {
  MEMBER,
  SPEAKER,
  COMPANY,
}

class ParticipationCard extends StatefulWidget {
  final Participation participation;
  final bool small;
  final CardType type;
  ParticipationCard({
    Key? key,
    required this.participation,
    required this.small,
    required this.type,
  }) : super(key: key);

  @override
  _ParticipationCardState createState() => _ParticipationCardState();
}

class _ParticipationCardState extends State<ParticipationCard> {
  late bool _expanded = false;

  Widget _buildExpandedSpeaker(Member m) {
    SpeakerParticipation p = widget.participation as SpeakerParticipation;

    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: widget.small ? 25 : 35,
                  height: widget.small ? 25 : 35,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(m.image),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(m.name!),
                ),
              ],
            ),
            Divider(),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: p.feedback != null && p.feedback!.length != 0
                    ? Text('Feedback: ${p.feedback}')
                    : Text(
                        'Add feedback',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )),
            if (p.room != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Room: ${p.room!.cost ?? ''}'),
              )
          ],
        ),
        InkWell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('see less'),
          ),
          onTap: () {
            setState(() {
              _expanded = false;
            });
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 450,
        margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
        padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(5)),
        child: FutureBuilder(
          future: widget.participation.member,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Member m = snapshot.data as Member;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SINFO ${widget.participation.event}',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            STATUSSTRING[widget.participation.status]!,
                            style: TextStyle(
                              color: widget.participation.status ==
                                      ParticipationStatus.GIVEN_UP
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                        decoration: BoxDecoration(
                            color: STATUSCOLOR[widget.participation.status],
                            borderRadius: BorderRadius.circular(5)),
                      )
                    ],
                  ),
                  Divider(
                    color: Colors.grey[600],
                  ),
                  if (!_expanded)
                    Stack(
                      alignment: AlignmentDirectional.bottomEnd,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: widget.small ? 25 : 35,
                              height: widget.small ? 25 : 35,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.network(
                                  m.image,
                                  errorBuilder: (BuildContext context,
                                      Object exception,
                                      StackTrace? stackTrace) {
                                    return Image.asset(
                                      'assets/noImage.png',
                                      fit: BoxFit.fill,
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(m.name!),
                            ),
                          ],
                        ),
                        InkWell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('see more'),
                          ),
                          onTap: () {
                            setState(() {
                              _expanded = true;
                            });
                          },
                        )
                      ],
                    )
                  else if (widget.type == CardType.SPEAKER)
                    _buildExpandedSpeaker(m)
                ],
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        ));
  }
}
