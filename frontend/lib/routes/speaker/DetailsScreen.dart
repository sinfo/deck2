import 'package:flutter/material.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/models/speaker.dart';

class DetailsScreen extends StatefulWidget {
  final Speaker speaker;
  const DetailsScreen({Key? key, required this.speaker}) : super(key: key);

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: EditableCard(
              title: 'Bio',
              body: widget.speaker.bio ?? "",
              bodyEditedCallback: (newBio) {
                //speaker.bio = newBio;
                //TODO replace bio with service call to change bio
                print('replaced bio');
                return Future.delayed(Duration.zero);
              },
              isSingleline: false,
              textInputType: TextInputType.multiline,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
            child: EditableCard(
              title: 'Notes',
              body: widget.speaker.notes ?? "",
              bodyEditedCallback: (newNotes) {
                //speaker.bio = newBio;
                //TODO replace bio with service call to change bio
                print('replaced notes');
                return Future.delayed(Duration.zero);
              },
              isSingleline: false,
              textInputType: TextInputType.multiline,
            ),
          ),
        ],
      )),
    );
  }
}
