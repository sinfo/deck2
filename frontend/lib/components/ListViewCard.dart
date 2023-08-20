import 'dart:html';

import 'package:flutter/material.dart';
import 'package:frontend/routes/company/CompanyScreen.dart';
import 'package:frontend/routes/company/CompanyTableNotifier.dart';
import 'package:frontend/routes/members_teams/member/MemberScreen.dart';
import 'package:frontend/routes/speaker/speakerNotifier.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/speaker/SpeakerScreen.dart';
import 'package:frontend/routes/UnknownScreen.dart';
import 'package:collection/collection.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class ListViewCard extends StatefulWidget {
  final Member? member;
  final Company? company;
  final Speaker? speaker;
  final bool small;
  final bool? participationsInfo;
  late ParticipationStatus _status;
  late Color _color;
  late final String _imageUrl;
  late final String _title;
  late final int? _numParticipations;
  late final int? _lastParticipation;
  late final String _tag;
  late final String? _id;
  late final bool? _editable;
  late Widget _screen;
  final Future<void> Function(int, BuildContext)? onChangeParticipationStatus;
  int? latestEvent;

  ListViewCard(
      {Key? key,
      this.latestEvent,
      required this.small,
      this.member,
      this.company,
      this.speaker,
      this.participationsInfo,
      this.onChangeParticipationStatus})
      : super(key: key) {
    {
      int? event = App.localStorage.getInt("event");
      if (event != null) {
        if (company != null) {
          _initCompany(event, this.latestEvent);
        } else if (speaker != null) {
          _initSpeaker(event, this.latestEvent);
        } else if (member != null) {
          _initMember(event);
        }
      }
    }
  }

  void _initMember(int event) {
    _tag = member!.id + event.toString();
    _imageUrl = member!.image!;
    _title = member!.name;
    _color = Colors.indigo;
    _screen = MemberScreen(member: member!);
    _status = ParticipationStatus.NO_STATUS;
    _editable = false;
  }

  void _initCompany(int event, int? latestEvent) {
    _tag = company!.id + event.toString();
    _screen = CompanyScreen(company: company!);
    CompanyParticipation? participation = company!.participations!
        .firstWhereOrNull((element) => element.event == event);
    if (participation != null) {
      _editable = latestEvent == event;
    } else {
      _editable = false;
    }
    _status = participation != null
        ? participation.status
        : ParticipationStatus.NO_STATUS;
    _imageUrl = company!.companyImages.internal;
    _title = company!.name;
    _color = STATUSCOLOR[_status]!;
    _id = company!.id;

    _numParticipations = company!.numParticipations;
    _lastParticipation = company!.lastParticipation;
  }

  void _initSpeaker(int event, int? latestEvent) {
    _tag = speaker!.id + event.toString();
    _screen = SpeakerScreen(speaker: speaker!);
    SpeakerParticipation? participation =
        speaker!.participations!.firstWhereOrNull(
      (element) => element.event == event,
    );
    if (participation != null) {
      _editable = latestEvent == event;
    } else {
      _editable = false;
    }
    _status = participation != null
        ? participation.status
        : ParticipationStatus.NO_STATUS;

    _imageUrl = speaker!.imgs!.internal!;
    _title = speaker!.name;
    _color = STATUSCOLOR[_status]!;
    _id = speaker!.id;

    _numParticipations = speaker!.numParticipations;
    _lastParticipation = speaker!.lastParticipation;
  }

  static Widget fakeCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < App.SIZE) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(5),
              ),
              child: SizedBox(
                height: 175,
                width: 125,
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(5),
              ),
              child: SizedBox(
                height: 225,
                width: 200,
              ),
            ),
          );
        }
      },
    );
  }

  @override
  _ListViewCardState createState() => _ListViewCardState();
}

class _ListViewCardState extends State<ListViewCard> {
  final CompanyService _companyService = CompanyService();
  final SpeakerService _speakerService = SpeakerService();

  @override
  void initState() {
    super.initState();
  }

  Widget getParticipationInfo(double fontsize) {
    if (widget.participationsInfo != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget._title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontsize,
                fontWeight: FontWeight.bold,
              )),
          Text(
              widget._numParticipations == 1
                  ? '${widget._numParticipations} participation'
                  : '${widget._numParticipations} participations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontsize,
                fontWeight: FontWeight.bold,
              )),
          Text(
              widget._numParticipations! > 0
                  ? 'Participated in SINFO ${widget._lastParticipation}'
                  : 'No Participation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontsize,
                fontWeight: FontWeight.bold,
              ))
        ],
      );
    } else {
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(widget._title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontsize,
              fontWeight: FontWeight.bold,
            ))
      ]);
    }
  }

  List<ParticipationStatus> getAllStatus() {
    List<ParticipationStatus> allStatus = STATUSSTRING.keys.toList();
    allStatus
        .removeWhere((element) => element == ParticipationStatus.NO_STATUS);
    return allStatus;
  }

  void changeState(ParticipationStatus newStatus) {
    setState(() {
      widget._status = newStatus;
      widget._color = STATUSCOLOR[newStatus]!;
    });
  }

  Widget Function(BuildContext, AsyncSnapshot<List<ParticipationStep>>)
      buildStatusButton() {
    return (context, snapshot) {
      List<ParticipationStep> steps = [
        ParticipationStep(next: widget._status, step: 0)
      ];
      if (snapshot.hasData) {
        steps.addAll(snapshot.data as List<ParticipationStep>);
      }
      return DecoratedBox(
        decoration: BoxDecoration(
            color: STATUSCOLOR[widget._status],
            borderRadius: BorderRadius.circular(5)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
          child: Container(
            child: DropdownButton<ParticipationStep>(
              icon: Icon(
                Icons.arrow_downward,
                color: widget._status == ParticipationStatus.GIVEN_UP
                    ? Colors.white
                    : Colors.black,
              ),
              underline: Container(
                height: 2,
                color: widget._status == ParticipationStatus.GIVEN_UP
                    ? Colors.white
                    : Colors.black,
              ),
              value: steps[0],
              style: Theme.of(context).textTheme.subtitle2,
              selectedItemBuilder: (BuildContext context) {
                return steps.map((e) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    constraints: const BoxConstraints(minWidth: 70),
                    child: Text(
                      STATUSSTRING[widget._status]!,
                      style: TextStyle(
                        color: widget._status == ParticipationStatus.GIVEN_UP
                            ? Colors.white
                            : Colors.black,
                        fontSize: 14,
                      ),
                    ),
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
                  widget.onChangeParticipationStatus!(next.step, context);
                }
              },
            ),
          ),
        ),
      );
    };
  }

  List<Widget> getStatus(double fontsize) {
    if (widget._editable! && widget.company != null) {
      return [
        FutureBuilder(
            future: _companyService.getNextParticipationSteps(id: widget._id!),
            builder: buildStatusButton())
      ];
    } else if (widget._editable! && widget.speaker != null) {
      return [
        FutureBuilder(
            future: _speakerService.getNextParticipationSteps(id: widget._id!),
            builder: buildStatusButton())
      ];
    } else {
      if (STATUSSTRING[widget._status] != null &&
          STATUSSTRING[widget._status] !=
              STATUSSTRING[ParticipationStatus.NO_STATUS]) {
        return [
          Container(
            padding: EdgeInsets.all(6),
            margin: EdgeInsets.fromLTRB(15, 15, 0, 0),
            decoration: BoxDecoration(
              color: widget._color,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Text(
              STATUSSTRING[widget._status]!,
              style: TextStyle(
                  fontSize: fontsize,
                  color: widget._status == ParticipationStatus.GIVEN_UP
                      ? Colors.white
                      : Colors.black),
            ),
          ),
        ];
      } else {
        return [];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.company != null ||
        widget.speaker != null ||
        widget.member != null) {
      Widget body = Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: () {
              Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 600),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        widget._screen,
                  ));
            },
            child: Container(
              height: widget.small ? 175 : 225,
              width: widget.small ? 125 : 200,
              margin: EdgeInsets.all(widget.small ? 5 : 10),
              alignment: Alignment.topCenter,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: widget._color, width: widget.small ? 1 : 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Hero(
                      tag: widget._tag,
                      child: Image.network(
                        widget._imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return Image.asset(
                            'assets/noImage.png',
                            fit: BoxFit.fill,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                      height: widget.participationsInfo != null
                          ? widget.small
                              ? 72
                              : 70
                          : widget.small
                              ? 42
                              : 40,
                      child: getParticipationInfo(14)),
                ],
              ),
            ),
          ),
          ...getStatus(widget.small ? 10 : 14)
        ],
      );

      if (widget.speaker != null) {
        return Consumer<SpeakerTableNotifier>(
          builder: (a, b, c) => body,
        );
      } else if (widget.company != null) {
        return Consumer<CompanyTableNotifier>(
          builder: (a, b, c) => body,
        );
      } else {
        return body;
      }
    } else {
      return UnknownScreen();
    }
  }
}
