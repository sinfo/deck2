import 'package:flutter/material.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/components/addThreadForm.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/participationCard.dart';
import 'package:frontend/components/threadCard.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/routes/meeting/EditMeetingForm.dart';
import 'package:frontend/routes/meeting/MeetingsNotifier.dart';
import 'package:frontend/routes/speaker/speakerNotifier.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MeetingScreen extends StatefulWidget {
  Meeting meeting;

  MeetingScreen({Key? key, required this.meeting}) : super(key: key);

  @override
  _MeetingScreenState createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MeetingService _meetingService;

  @override
  void initState() {
    super.initState();
    _meetingService = MeetingService();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabIndex);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabIndex() {
    setState(() {});
  }

  Future<void> meetingChangedCallback(BuildContext context,
      {Future<Meeting?>? fm, Meeting? meeting}) async {
    Meeting? m;
    if (fm != null) {
      m = await fm;
    } else if (meeting != null) {
      m = meeting;
    }
    if (m != null) {
      Provider.of<MeetingsNotifier>(context, listen: false).edit(m);
      setState(() {
        widget.meeting = m!;
      });
    }
  }

  void _addThreadModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(child: Text("In Progress...")
            // child: AddThreadForm(
            //     meeting: widget.meeting,
            //     onEditMeeting: (context, _meeting) {
            //       meetingChangedCallback(context, meeting: _meeting);
            //     }),
            );
      },
    );
  }

  Widget? _fabAtIndex(BuildContext context) {
    int latestEvent = Provider.of<EventNotifier>(context).latest.id;
    int index = _tabController.index;
    switch (index) {
      case 0:
        return null;
      case 1:
        {
          return FloatingActionButton.extended(
            onPressed: () {
              _addThreadModal(context);
            },
            label: const Text('Add Communication'),
            icon: const Icon(Icons.add),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Consumer<MeetingsNotifier>(builder: (context, notif, child) {
        return Scaffold(
          appBar: CustomAppBar(disableEventChange: true),
          body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                MeetingBanner(meeting: widget.meeting),
                TabBar(
                  isScrollable: small,
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Participations'),
                    Tab(text: 'Communications'),
                  ],
                ),
                Expanded(
                  child: TabBarView(controller: _tabController, children: [
                    Container(
                      child: Center(child: Text('Work in progress :)')),
                    ),
                    Container(
                      child: Center(child: Text('Work in progress :)')),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        );
      });
    });
  }
}

class MeetingBanner extends StatelessWidget {
  final Meeting meeting;

  const MeetingBanner({Key? key, required this.meeting}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _titleFontSize = 32, _infoFontSize = 20;
    double lum = 0.2;
    var matrix = <double>[
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]; // Greyscale matrix. Lum represents level of luminosity
    return LayoutBuilder(
      builder: (context, constraints) {
        bool small = constraints.maxWidth < App.SIZE;
        return Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  colorFilter: Provider.of<ThemeNotifier>(context).isDark
                      ? ColorFilter.matrix(matrix)
                      : null,
                  image: AssetImage('assets/banner_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: small ? 4 : 20, vertical: small ? 5 : 25),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(small ? 8 : 12),
                        child: Column(
                          children: [
                            Container(
                                margin: EdgeInsets.only(bottom: 25),
                                child: Text(
                                  meeting.title.toUpperCase(),
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _titleFontSize),
                                  overflow: TextOverflow.ellipsis,
                                )),
                            // Row(
                            //   children: [
                            //     Column(
                            //       children: [
                            //         Text(
                            //           DateFormat.d().format(meeting.begin) +
                            //               ' ' +
                            //               DateFormat.MMMM()
                            //                   .format(meeting.begin)
                            //                   .toUpperCase(),
                            //           style: TextStyle(
                            //               color: Colors.white,
                            //               fontSize: _infoFontSize),
                            //         ),
                            //         Text(
                            //           DateFormat.jm()
                            //                   .format(meeting.begin.toLocal()) +
                            //               ' - ' +
                            //               DateFormat.jm()
                            //                   .format(meeting.end.toLocal()),
                            //           style: TextStyle(
                            //               color: Colors.white,
                            //               fontSize: _infoFontSize),
                            //         ),
                            //         Text(
                            //           meeting.place,
                            //           style: TextStyle(
                            //               color: Colors.white,
                            //               fontSize: _infoFontSize),
                            //         ),
                            //       ],
                            //     ),
                            //     Text("HIII"),
                            //   ],
                            // )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
