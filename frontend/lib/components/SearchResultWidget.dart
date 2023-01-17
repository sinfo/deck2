import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/company/CompanyScreen.dart';
import 'package:frontend/routes/member/MemberScreen.dart';
import 'package:frontend/routes/speaker/SpeakerScreen.dart';

class SearchResultWidget extends StatelessWidget {
  final Company? company;
  final Speaker? speaker;
  final Member? member;
  final int? index;
  final Function? getMemberData;
  SearchResultWidget(
      {Key? key,
      this.company,
      this.speaker,
      this.member,
      this.index,
      this.getMemberData});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          if (getMemberData != null && member != null) {
            getMemberData!(member!.id, member!.name);
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              if (company != null) {
                return CompanyScreen(company: company!);
              } else if (speaker != null) {
                return SpeakerScreen(speaker: speaker!);
              }
              return MemberScreen(member: member!);
            }));
          }
        },
        child: Center(
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(300.0),
                child: Image.network(
                  getImageURL(),
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                      return Image.asset(
                        'assets/noImage.png'
                      );
                  }
                ),
              )
            ),
            title: Text(getName()),
          ),
        ));
  }

  String getImageURL() {
    if (this.company != null) {
      return this.company!.companyImages.internal;
    } else if (this.speaker != null) {
      return this.speaker!.imgs!.internal!;
    } else if (this.member != null) {
      return this.member!.image!;
    } else {
      //ERROR case
      return "";
    }
  }

  String getName() {
    if (this.company != null) {
      return this.company!.name;
    } else if (this.speaker != null) {
      return this.speaker!.name;
    } else if (this.member != null) {
      return this.member!.name;
    } else {
      //ERROR case
      return "";
    }
  }
}
