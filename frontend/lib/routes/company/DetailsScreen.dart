import 'package:flutter/material.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/models/company.dart';

class DetailsScreen extends StatelessWidget {
  final Company company;
  const DetailsScreen({Key? key, required this.company}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: EditableCard(
              title: 'Description',
              body: company.description ?? "",
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
              title: 'Site',
              body: company.site ?? "",
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