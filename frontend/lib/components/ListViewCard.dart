import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/routes/company/CompanyScreen.dart';
import 'package:frontend/routes/member/MemberScreen.dart';
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
import 'package:provider/provider.dart';

class ListViewCard extends StatelessWidget {
  final Member? member;
  final Company? company;
  final Speaker? speaker;
  final bool small;
  final bool? participationsInfo;
  late final ParticipationStatus _status;
  late final Color _color;
  late final String _imageUrl;
  late final String _title;
  late final int? _numParticipations;
  late final int? _lastParticipation;
  late final String _tag;
  late Widget _screen;

  ListViewCard(
      {Key? key,
      required this.small,
      this.member,
      this.company,
      this.speaker,
      this.participationsInfo})
      : super(key: key) {
    int? event = App.localStorage.getInt("event");
    if (event != null) {
      if (company != null) {
        _initCompany(event);
      } else if (speaker != null) {
        _initSpeaker(event);
      } else if (member != null) {
        _initMember(event);
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
  }

  void _initCompany(int event) {
    _tag = company!.id + event.toString();
    _screen = CompanyScreen(company: company!);
    CompanyParticipation? participation = company!.participations!
        .firstWhereOrNull((element) => element.event == event);
    _status = participation != null
        ? participation.status
        : ParticipationStatus.NO_STATUS;
    _imageUrl = company!.companyImages.internal;
    _title = company!.name;
    _color = STATUSCOLOR[_status]!;

    _numParticipations = company!.numParticipations;
    _lastParticipation = company!.lastParticipation;
  }

  void _initSpeaker(int event) {
    _tag = speaker!.id + event.toString();
    _screen = SpeakerScreen(speaker: speaker!);
    SpeakerParticipation? participation =
        speaker!.participations!.firstWhereOrNull(
      (element) => element.event == event,
    );
    _status = participation != null
        ? participation.status
        : ParticipationStatus.NO_STATUS;
    _imageUrl = speaker!.imgs!.speaker!;
    _title = speaker!.name;
    _color = STATUSCOLOR[_status]!;

    _numParticipations = speaker!.numParticipations;
    _lastParticipation = speaker!.lastParticipation;
  }

  Widget getParticipationInfo(double fontsize) {
    if (participationsInfo != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontsize,
                fontWeight: FontWeight.bold,
              )),
          Text('$_numParticipations participations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontsize,
                fontWeight: FontWeight.bold,
              )),
          Text(
              _numParticipations! > 0
                  ? 'Participated in SINFO $_lastParticipation'
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
        Text(_title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontsize,
              fontWeight: FontWeight.bold,
            ))
      ]);
    }
  }

  List<Widget> getStatus(double fontsize) {
    if (STATUSSTRING[_status] != null &&
        STATUSSTRING[_status] != STATUSSTRING[ParticipationStatus.NO_STATUS]) {
      return [
        Container(
          padding: EdgeInsets.all(6),
          margin: EdgeInsets.fromLTRB(15, 15, 0, 0),
          decoration: BoxDecoration(
            color: _color,
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          child: Text(
            STATUSSTRING[_status]!,
            style: TextStyle(
                fontSize: fontsize,
                color: _status == ParticipationStatus.GIVEN_UP
                    ? Colors.white
                    : Colors.black),
          ),
        ),
      ];
    } else {
      return [];
    }
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
  Widget build(BuildContext context) {
    if (company != null || speaker != null || member != null) {
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
                        _screen,
                  ));
            },
            child: Container(
              height: small ? 175 : 225,
              width: small ? 125 : 200,
              margin: EdgeInsets.all(small ? 5 : 10),
              alignment: Alignment.topCenter,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: _color, width: small ? 1 : 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Hero(
                      tag: _tag,
                      child: Image.network(
                        _imageUrl,
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
                      height: participationsInfo != null
                          ? small
                              ? 72
                              : 70
                          : small
                              ? 42
                              : 40,
                      child: getParticipationInfo(14)),
                ],
              ),
            ),
          ),
          ...getStatus(small ? 10 : 14)
        ],
      );

      if (speaker != null) {
        return Consumer<SpeakerTableNotifier>(
          builder: (a, b, c) => body,
        );
      } else
        return body;
    } else {
      return UnknownScreen();
    }
  }
}
