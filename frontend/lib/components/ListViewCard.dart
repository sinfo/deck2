import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/UnknownScreen.dart';
import 'package:provider/provider.dart';

final Map<ParticipationStatus, String> STATUSSTRING = {
  ParticipationStatus.ACCEPTED: 'ACCEPTED',
  ParticipationStatus.ANNOUNCED: 'ANNOUNCED',
  ParticipationStatus.CONTACTED: 'CONTACTED',
  ParticipationStatus.GIVEN_UP: 'GIVEN_UP',
  ParticipationStatus.IN_CONVERSATIONS: 'IN_CONVERSATIONS',
  ParticipationStatus.ON_HOLD: 'ON_HOLD',
  ParticipationStatus.REJECTED: 'REJECTED',
  ParticipationStatus.SELECTED: 'SELECTED',
  ParticipationStatus.SUGGESTED: 'SUGGESTED',
};

class ListViewCard extends StatelessWidget {
  final Member? member;
  final Company? company;
  final CompanyLight? companyLight;
  final Speaker? speaker;
  final SpeakerLight? speakerLight;
  final bool small;
  final bool? participationsInfo;
  late final String _status;
  late final Color _color;
  late final String _imageUrl;
  late final String _title;
  late final int? _numParticipations;
  late final int? _lastParticipation;

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
    _status = companyLight!.participationStatus!.toUpperCase();
    _imageUrl = companyLight!.companyImages.internal;
    _title = companyLight!.name;
    defineStatusColor(_status);
  }

  void _initCompany(int event) {
    CompanyParticipation participation = company!.participations!
        .firstWhere((element) => element.event == event);
    _status = participation.status.toUpperCase();
    _imageUrl = company!.companyImages.internal;
    _title = company!.name;
    defineStatusColor(_status);
  }

  void _initSpeaker(int event) {
    _numParticipations = speaker!.participations!.length;
    if (_numParticipations! > 0) {
      _lastParticipation =
          speaker!.participations![speaker!.participations!.length - 1].event;
    }
    if (_numParticipations! > 0 && _lastParticipation == event) {
      ParticipationStatus status = speaker!.participations!
          .firstWhere((element) => element.event == event)
          .status!;
      _status = STATUSSTRING[status]!;
    } else {
      _status = "";
    }
    _imageUrl = speaker!.imgs!.speaker!;
    _title = speaker!.name;
    defineStatusColor(_status);
  }

  void _initSpeakerLight() {
    _numParticipations = speakerLight!.numParticipations;
    _lastParticipation = speakerLight!.lastParticipation;
    _status = speakerLight!.participationStatus!.toUpperCase();
    _imageUrl = speakerLight!.speakerImages.internal!;
    _title = speakerLight!.name;
    defineStatusColor(_status);
  }

  void defineStatusColor(String status) {
    switch (status) {
      case "SUGGESTED":
      case "SELECTED":
        _color = Colors.orange;
        break;
      case "ON HOLD":
      case "CONTACTED":
        _color = Colors.yellow;
        break;
      case "IN CONVERSATIONS":
        _color = Colors.blue;
        break;
      case "ACCEPTED":
      case "ANNOUNCED":
        _color = Colors.green;
        break;
      case "REJECTED":
        _color = Colors.red;
        break;
      case "GIVE UP":
      default:
        _color = Colors.indigo;
        break;
    }
  }

  Widget _buildSmallCard(BuildContext context) {
    return Container(
      height: 225,
      width: 200,
      margin: EdgeInsets.all(5),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _color),
      ),
      child: Stack(
        children: [
          InkWell(
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5)),
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
                      height: participationsInfo != null ? 72 : 30,
                      child: getParticipationInfo(14)),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return UnknownScreen();
                } // CompanyScreen(company: this.company)),
                    ));
              }),
          ...getStatus(10)
        ],
      ),
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
          Text('${_numParticipations} participations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontsize,
                fontWeight: FontWeight.bold,
              )),
          Text(
              _numParticipations! > 0
                  ? 'Participated in SINFO ${_lastParticipation}'
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
    if (_status != "") {
      return [
        Container(
          padding: EdgeInsets.all(6),
          margin: EdgeInsets.fromLTRB(4, 8, 0, 0),
          decoration: BoxDecoration(
            color: _color,
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          child: Text(
            _status,
            style: TextStyle(fontSize: fontsize),
          ),
        ),
      ];
    } else {
      return [];
    }
  }

  Widget _buildBigCard(BuildContext context) {
    return Container(
      height: 275,
      width: 250,
      margin: EdgeInsets.all(10),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _color, width: 2),
      ),
      child: Stack(children: [
        InkWell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
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
                SizedBox(
                    height: participationsInfo != null ? 70 : 35,
                    child: getParticipationInfo(14)),
              ],
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return UnknownScreen();
              } // CompanyScreen(company: this.company)),
                  ));
            }),
        ...getStatus(14)
      ]),
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
    } else if (company != null || speaker != null || companyLight != null || speakerLight != null) {
      return small ? _buildSmallCard(context) : _buildBigCard(context);
    } else {
      return UnknownScreen();
    }
  }
}
