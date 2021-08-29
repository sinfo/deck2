import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/UnknownScreen.dart';

class ListViewCard extends StatelessWidget {
  final Member? member;
  final Company? company;
  final Speaker? speaker;
  final bool small;
  late String _status;
  late Color _color;
  late String _imageUrl;
  late String _title;

  ListViewCard(
      {Key? key, required this.small, this.member, this.company, this.speaker})
      : super(key: key) {
    int? event = App.localStorage.getInt("event");
    if (event != null) {
      if (company != null) {
        _initCompany(event);
      } else if (speaker != null) {
        _initSpeaker(event);
      }
    }
  }

  void _initCompany(int event) {
    CompanyParticipation participation = company!.participations!
        .firstWhere((element) => element.event == event);
    _status = participation.status.toUpperCase();
    _imageUrl = company!.companyImages.internal;
    _title = company!.name;
    switch (_status) {
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
        _color = Colors.black;
        break;
    }
  }

  void _initSpeaker(int event) {
    Participation participation = speaker!.participations!
        .firstWhere((element) => element.event == event);
    _imageUrl = speaker!.imgs!.speaker!;
    _title = speaker!.name!;
    switch (participation.status) {
      case ParticipationStatus.SUGGESTED:
        _status = "SUGGESTED";
        _color = Colors.orange;
        break;
      case ParticipationStatus.SELECTED:
        _status = "SELECTED";
        _color = Colors.orange;
        break;
      case ParticipationStatus.ON_HOLD:
        _status = "ON HOLD";
        _color = Colors.yellow;
        break;
      case ParticipationStatus.CONTACTED:
        _status = "CONTACTED";
        _color = Colors.yellow;
        break;
      case ParticipationStatus.IN_CONVERSATIONS:
        _status = "IN CONVERSATIONS";
        _color = Colors.blue;
        break;
      case ParticipationStatus.ACCEPTED:
        _status = "ACCEPTED";
        _color = Colors.green;
        break;
      case ParticipationStatus.ANNOUNCED:
        _status = "ANNOUNCED";
        _color = Colors.green;
        break;
      case ParticipationStatus.REJECTED:
        _status = "REJECTED";
        _color = Colors.red;
        break;
      case ParticipationStatus.GIVEN_UP:
        _status = "GIVEN UP";
        _color = Colors.black;
        break;
      default:
        _status = "";
        _color = Colors.white;
        break;
    }
  }

  Widget _buildSmallCard(BuildContext context) {
    return Container(
      height: 125,
      width: 100,
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
                        fit: BoxFit.fill,
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
                  SizedBox(height: 6),
                  Text(_title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      )),
                  SizedBox(height: 6),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return UnknownScreen();
                } // CompanyScreen(company: this.company)),
                    ));
              }),
          Container(
            padding: EdgeInsets.all(6),
            margin: EdgeInsets.fromLTRB(4, 8, 0, 0),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Text(
              _status,
              style: TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigCard(BuildContext context) {
    return Container(
      height: 175,
      width: 150,
      margin: EdgeInsets.all(10),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _color, width: 2),
      ),
      child: Stack(
        children: [
          InkWell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.network(
                      _imageUrl,
                      fit: BoxFit.fill,
                      errorBuilder: (BuildContext context, Object exception,
                          StackTrace? stackTrace) {
                        return Image.asset(
                          'assets/noImage.png',
                          fit: BoxFit.fill,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 12.5),
                  Text(_title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        //fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                      )),
                  SizedBox(height: 12.5),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return UnknownScreen();
                } // CompanyScreen(company: this.company)),
                    ));
              }),
          Container(
            padding: EdgeInsets.all(6),
            margin: EdgeInsets.fromLTRB(4, 8, 0, 0),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Text(
              _status,
              style: TextStyle(fontSize: 14),
            ),
          )
        ],
      ),
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
    } else if (company != null || speaker != null) {
      return small ? _buildSmallCard(context) : _buildBigCard(context);
    } else {
      return UnknownScreen();
    }
  }
}
