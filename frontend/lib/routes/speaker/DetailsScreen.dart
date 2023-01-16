import 'package:flutter/material.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/speakerService.dart';

class DetailsScreen extends StatefulWidget {
  final Speaker speaker;
  const DetailsScreen({Key? key, required this.speaker}) : super(key: key);

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
    with AutomaticKeepAliveClientMixin {
  final _speakerService = SpeakerService();

  @override
  bool get wantKeepAlive => true;

  Future<void> _editSpeaker(
      BuildContext context, String updatedValue, bool isBio) async {
    Speaker? s;
    if (isBio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating Bio...')),
      );
      s = await _speakerService.updateSpeaker(
          id: widget.speaker.id, bio: updatedValue);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating Notes...')),
      );
      s = await _speakerService.updateSpeaker(
          id: widget.speaker.id, notes: updatedValue);
    }

    if (s != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Done'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occured.')),
      );
    }
  }

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
              bodyEditedCallback: (newBio) => _editSpeaker(context, newBio, true),
              isSingleline: false,
              textInputType: TextInputType.multiline,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
            child: EditableCard(
              title: 'Notes',
              body: widget.speaker.notes ?? "",
              bodyEditedCallback: (newNotes) => _editSpeaker(context, newNotes, false),
              isSingleline: false,
              textInputType: TextInputType.multiline,
            ),
          ),
        ],
      )),
    );
  }
}
