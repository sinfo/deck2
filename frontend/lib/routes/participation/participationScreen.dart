import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/speaker.dart';

class ParticipationScreen extends StatelessWidget {
  final SpeakerParticipation participation;
  final Speaker speaker;
  const ParticipationScreen(
      {Key? key, required this.participation, required this.speaker})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(disableEventChange: true),
      body: ListView(
        children: [
          ParticipationBanner(participation: participation, speaker: speaker),
          EditableCard(
            title: 'Feedback',
            body: participation.feedback ?? '',
            bodyEditedCallback: (s) {
              print('edited feedback');
              return Future.delayed(Duration.zero);
            },
          ),
        ],
      ),
    );
  }
}

class ParticipationBanner extends StatelessWidget {
  final SpeakerParticipation participation;
  final Speaker speaker;
  const ParticipationBanner(
      {Key? key, required this.participation, required this.speaker})
      : super(key: key);

  Widget _buildSmallBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/banner_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 20.0, 8.0),
              child: SizedBox(
                height: 100,
                width: 100,
                child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 4,
                        color: STATUSCOLOR[participation.status]!,
                      )),
                  child: CircleAvatar(
                    foregroundImage: NetworkImage(
                      speaker.imgs!.speaker ??
                          (speaker.imgs!.internal ??
                              (speaker.imgs!.company ?? "")),
                    ),
                    backgroundImage: AssetImage('assets/noImage.png'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker.name,
                      style: Theme.of(context).textTheme.headline6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(speaker.title!,
                        style: Theme.of(context).textTheme.subtitle1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/banner_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 20.0, 8.0),
              child: SizedBox(
                height: 150,
                width: 150,
                child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 4,
                        color: STATUSCOLOR[participation.status]!,
                      )),
                  child: CircleAvatar(
                    foregroundImage: NetworkImage(
                      speaker.imgs!.speaker ??
                          (speaker.imgs!.internal ??
                              (speaker.imgs!.company ?? "")),
                    ),
                    backgroundImage: AssetImage('assets/noImage.png'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker.name,
                      style: Theme.of(context).textTheme.headline5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(speaker.title!,
                        style: Theme.of(context).textTheme.subtitle1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < App.SIZE) {
          return _buildSmallBanner(context);
        } else {
          return _buildBigBanner(context);
        }
      },
    );
  }
}
