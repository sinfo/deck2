import 'package:flutter/material.dart';
import 'package:frontend/components/GridLayout.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/speakerService.dart';

class SpeakerSearchDelegate extends SearchDelegate {
  late Future<List<SpeakerLight>> speakers;
  SpeakerService speakerService = new SpeakerService();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    this.speakers = speakerService.getSpeakersLight(name: query);
    return FutureBuilder<List<SpeakerLight>>(
        future: this.speakers,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.length > 0) {
              return Center(
                  child: Text("Found Speaker!. Still in progress :)"));
              // Navigator.push(
              //                   context, MaterialPageRoute(
              //                     builder: (context) => CompanyScreen(PUT ID HERE!!!)),);
            } else {
              return Center(child: Text("Speaker Not Found :("));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length > 1) {
      this.speakers = speakerService.getSpeakersLight(name: query);
      return FutureBuilder(
          future: this.speakers,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<SpeakerLight> speaksMatched =
                  snapshot.data as List<SpeakerLight>;
              if (speaksMatched.length > 0) {
                return GridLayout(speakers: speaksMatched);
              } else {
                return Center(child: Text("No Results"));
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          });
    } else {
      return Center(child: Text("No Results yet :)"));
    }
  }

  @override
  String get searchFieldLabel {
    return 'Search Speaker By Name';
  }
}
