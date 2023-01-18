import 'package:flutter/material.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/speaker/speakerNotifier.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';

final Map<SortingMethod, String> SORT_STRING = {
  SortingMethod.RANDOM: 'Sort Randomly',
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
        maxSpeaksInRequest: MAX_SPEAKERS,
        numRequestsBackend: numRequests,
        sortMethod: _sortMethod);
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

  Future<void> speakerChangedCallback(BuildContext context,
      {Future<Speaker?>? fs, Speaker? speaker}) async {
    Speaker? s;
    if (fs != null) {
      s = await fs;
    } else if (speaker != null) {
      s = speaker;
    }
    if (s != null) {
      Provider.of<SpeakerTableNotifier>(context, listen: false).edit(s);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Done.', style: TextStyle(color: Colors.white))),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occured.',
                style: TextStyle(color: Colors.white))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              return Column(
                children: [
                  DropdownButton<SortingMethod>(
                    value: _sortMethod,
                    icon: const Icon(Icons.sort),
                    elevation: 16,
                    underline: Container(
                        height: 2, color: Theme.of(context).cardColor),
                    onChanged: (SortingMethod? sort) {
                      setState(() {
                        _sortMethod = sort!;
                        this.speakersLoaded.clear();
                        numRequests = 0;
                        this.speakers = speakerService.getSpeakers(
                            maxSpeaksInRequest: MAX_SPEAKERS,
                            sortMethod: sort,
                            numRequestsBackend: numRequests);
                        numRequests++;
                      });
                    },
                    items: SORT_STRING.keys
                        .map<DropdownMenuItem<SortingMethod>>(
                            (SortingMethod value) {
                      return DropdownMenuItem<SortingMethod>(
                        value: value,
                        child: Center(child: Text(SORT_STRING[value]!)),
                      );
                    }).toList(),
                  ),
                  Expanded(
                      child: GridView.builder(
                          controller: _controller,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                              participationsInfo: true,
                              onChangeParticipationStatus:
                                  (ParticipationStatus status) async {
                                await speakerChangedCallback(
                                  context,
                                  fs: speakerService.updateParticipationStatus(
                                      id: speak[index].id, newStatus: status),
                                );
                              },
                            );
                          })),
                ],
              );
            });
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
