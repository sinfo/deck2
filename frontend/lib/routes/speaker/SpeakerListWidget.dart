import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/speakerService.dart';

final Map<SortingMethod, String> SORT_STRING = {
  SortingMethod.NUM_PARTICIPATIONS: 'Sort By Number Of Participations',
  SortingMethod.LAST_PARTICIPATION: 'Sort By Last Participation',
};

final int MAX_SPEAKERS = 40;

class SpeakerListWidget extends StatefulWidget {
  const SpeakerListWidget({Key? key}) : super(key: key);

  @override
  _SpeakerListWidgetState createState() => _SpeakerListWidgetState();
}

class _SpeakerListWidgetState extends State<SpeakerListWidget> {
  SpeakerService speakerService = new SpeakerService();
  late Future<List<Speaker>> speakers;
  List<Speaker> speakersLoaded = [];
  SortingMethod _sortMethod = SortingMethod.RANDOM;
  int numRequests = 0;
  ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
    this.speakers = speakerService.getSpeakers(
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
    this.speakers = speakerService.getSpeakers(
        maxSpeaksInRequest: MAX_SPEAKERS,
        numRequestsBackend: numRequests,
        sortMethod: _sortMethod);
    numRequests++;
  }

  void storeSpeakersLoaded() async {
    this.speakersLoaded.addAll(await this.speakers);
  }

  Widget speakerGrid() {
    return FutureBuilder<List<Speaker>>(
        future: speakers,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Speaker> speak = speakersLoaded + snapshot.data!;
            return LayoutBuilder(builder: (context, constraints) {
              double cardWidth = 200;
              bool isSmall = false;
              if (constraints.maxWidth < App.SIZE) {
                cardWidth = 125;
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
                    return ListViewCard(
                        small: isSmall,
                        speaker: speak[index],
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
    CustomAppBar appBar = CustomAppBar(
      disableEventChange: true,
    );
    return Scaffold(
      body: Stack(children: [
        Container(
            margin: EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
            child: speakerGrid()),
        appBar,
      ]),
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
