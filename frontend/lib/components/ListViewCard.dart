import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/SpeakerScreen.dart';
import 'package:frontend/routes/UnknownScreen.dart';

class ListViewCard extends StatelessWidget {
  final Member? member;
  final Company? company;
  final CompanyLight? companyLight;
  final Speaker? speaker;
  final SpeakerLight? speakerLight;
  final bool small;
  final bool? participationsInfo;
  late final ParticipationStatus _status;
  late final Color _color;
  late Color? _textColor = null;
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
      this.companyLight,
      this.speaker,
      this.speakerLight,
      this.participationsInfo})
      : super(key: key) {
    int? event = App.localStorage.getInt("event");
    if (event != null) {
      if (company != null) {
        _initCompany(event);
      } else if (speaker != null) {
        _initSpeaker(event);
      } else if (companyLight != null) {
        _initCompanyLight();
      } else if (speakerLight != null) {
        _initSpeakerLight();
      }
    }
  }

  void _initCompanyLight() {
    _numParticipations = companyLight!.numParticipations;
    _lastParticipation = companyLight!.lastParticipation;
    _status = companyLight!.participationStatus;
    _imageUrl = companyLight!.companyImages.internal;
    _title = companyLight!.name;
    _color = STATUSCOLOR[_status]!;
  }

  void _initCompany(int event) {
    _tag = company!.id + event.toString();
    CompanyParticipation participation = company!.participations!
        .firstWhere((element) => element.event == event);
    _status = participation.status;
    _imageUrl = company!.companyImages.internal;
    _title = company!.name;
    _color = STATUSCOLOR[_status]!;
  }

  void _initSpeaker(int event) {
    _tag = speaker!.id + event.toString();
    _screen = SpeakerScreen(speaker: speaker!);
    Participation participation = speaker!.participations!
        .firstWhere((element) => element.event == event);
    _status = participation.status!;
    _imageUrl = speaker!.imgs!.speaker!;
    _title = speaker!.name;
    _color = STATUSCOLOR[_status]!;
  }

  void _initSpeakerLight() {
    _numParticipations = speakerLight!.numParticipations;
    _lastParticipation = speakerLight!.lastParticipation;
    _status = speakerLight!.participationStatus;
    _imageUrl = speakerLight!.speakerImages.internal!;
    _title = speakerLight!.name;
    _color = STATUSCOLOR[_status]!;
  }

  Widget _buildSmallCard(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 175,
          width: 125,
          margin: EdgeInsets.all(5),
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: _color),
          ),
          child: InkWell(
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5)),
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
                  ),
                  SizedBox(
                      height: participationsInfo != null ? 72 : 50,
                      child: getParticipationInfo(14)),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return _screen;
                } // CompanyScreen(company: this.company)),
                    ));
              }),
        ),
        ...getStatus(10)
      ],
    );
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
    if (STATUSSTRING[_status] != null) {
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
            style: TextStyle(fontSize: fontsize, color: _textColor),
          ),
        ),
      ];
    } else {
      return [];
    }
  }

  Widget _buildBigCard(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 225,
          width: 200,
          margin: EdgeInsets.all(10),
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: _color, width: 2),
          ),
          child: InkWell(
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
                      height: participationsInfo != null ? 70 : 40,
                      child: getParticipationInfo(14)),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return _screen;
                } // CompanyScreen(company: this.company)),
                    ));
              }),
        ),
        ...getStatus(14)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (member != null) {
      return InkWell(
          child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5)),
                    child: Image(
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                      image: (member!.image == '')
                          ? AssetImage("assets/noImage.png") as ImageProvider
                          : NetworkImage(member!.image),
                      //image: NetworkImage(member.image),
                    ),
                  ),
                  SizedBox(height: 12.5),
                  Text(member!.name!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        //fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                      )),
                  Text(
                    'Role',
                    textAlign: TextAlign.center,
                  ),
                ],
              )),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return UnknownScreen();
            } //MemberScreen(member: this.member)),
                ));
          });
    } else if (company != null ||
        speaker != null ||
        companyLight != null ||
        speakerLight != null) {
      return small ? _buildSmallCard(context) : _buildBigCard(context);
    } else {
      return UnknownScreen();
    }
  }
}
