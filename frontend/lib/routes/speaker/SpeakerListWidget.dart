import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/ListViewCard2.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/components/speakerSearchDelegate.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/speakerService.dart';

enum SortingMethod {
  RANDOM,
  NUM_PARTICIPATIONS,
  LAST_PARTICIPATION,
}

final Map<SortingMethod, String> SORT_STRING = {
  SortingMethod.NUM_PARTICIPATIONS: 'Sort By Number Of Participations',
  SortingMethod.LAST_PARTICIPATION: 'Sort By Last Participation',
};

final int MAX_SPEAKERS = 30;

class SpeakerListWidget extends StatefulWidget {
  const SpeakerListWidget({Key? key}) : super(key: key);

  @override
  _SpeakerListWidgetState createState() => _SpeakerListWidgetState();
}

class _SpeakerListWidgetState extends State<SpeakerListWidget> {
  SpeakerService speakerService = new SpeakerService();
  late Future<List<SpeakerLight>> speakers;
  List<SpeakerLight> speakersLoaded = [];
  SortingMethod _sortMethod = SortingMethod.RANDOM;
  int numRequests = 0;
  ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
    this.speakers = speakerService.getSpeakersLight(
        maxSpeaksInRequest: MAX_SPEAKERS, numRequestsBackend: numRequests);
    numRequests++;
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      setState(() {
        _loadMoreSpeakers();
      });
    }
  }

  void _loadMoreSpeakers() {
    storeSpeakersLoaded();
    this.speakers = speakerService.getSpeakersLight(
        maxSpeaksInRequest: MAX_SPEAKERS,
        numRequestsBackend: numRequests,
        sortMethod: _sortMethod);
    numRequests++;
  }

  void storeSpeakersLoaded() async {
    this.speakersLoaded.addAll(await this.speakers);
  }

  Widget speakerGrid() {
    return FutureBuilder<List<SpeakerLight>>(
        future: speakers,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<SpeakerLight> speak = speakersLoaded + snapshot.data!;
            return LayoutBuilder(builder: (context, constraints) {
              double cardWidth = 250;
              bool isSmall = false;
              if (constraints.maxWidth < 1500) {
                cardWidth = 200;
                isSmall = true;
              }
              return GridView.builder(
                  controller: _controller,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width ~/ cardWidth,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: speak.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListViewCard2(
                        small: isSmall,
                        speakerLight: speak[index],
                        participationsInfo: true);
                  });
            });
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: GestureDetector(
              child: Image.asset(
            'assets/logo-branco2.png',
            height: 100,
            width: 100,
          )),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search speaker',
              onPressed: () {
                showSearch(context: context, delegate: SpeakerSearchDelegate());
              },
            ),
            PopupMenuButton<SortingMethod>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort Speakers',
              onSelected: (SortingMethod sort) {
                setState(() {
                  _sortMethod = sort;
                  this.speakersLoaded.clear();
                  numRequests = 0;
                  this.speakers = speakerService.getSpeakersLight(
                      maxSpeaksInRequest: MAX_SPEAKERS,
                      sortMethod: sort,
                      numRequestsBackend: numRequests);
                  numRequests++;
                });
              },
              itemBuilder: (BuildContext context) {
                return SORT_STRING.keys.map((SortingMethod choice) {
                  return PopupMenuItem<SortingMethod>(
                    value: choice,
                    child: Center(child: Text(SORT_STRING[choice]!)),
                  );
                }).toList();
              },
            ),
          ]),
      body: speakerGrid(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            Routes.AddSpeaker,
          );
        },
        label: const Text('Create New Speaker'),
        icon: const Icon(Icons.person_add),
        backgroundColor: Color(0xff5C7FF2),
      ),
    );
  }
}