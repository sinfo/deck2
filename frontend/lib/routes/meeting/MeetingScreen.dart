import 'package:flutter/material.dart';
import 'package:frontend/components/threads/addThreadForm.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/routes/meeting/AddMeetingMemberForm.dart';
import 'package:frontend/routes/meeting/MeetingBanner.dart';
import 'package:frontend/routes/meeting/MeetingMembers.dart';
import 'package:frontend/routes/meeting/MeetingsCommunications.dart';
import 'package:frontend/routes/meeting/MeetingsNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/meetingService.dart';
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
  MeetingService _meetingService = MeetingService();
  CustomAppBar appBar = CustomAppBar(disableEventChange: true);

  @override
  void initState() {
    super.initState();
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

  void _addThreadModal(mainContext) {
    showModalBottomSheet(
      context: mainContext,
      builder: (context) {
        return Container(
          child: AddThreadForm(
            meeting: widget.meeting,
            onAddMeeting: (thread_text) {
              meetingChangedCallback(mainContext,
                  fm: _meetingService.addThread(
                      id: widget.meeting.id,
                      kind: 'MEETING',
                      text: thread_text));
            },
          ),
        );
      },
    );
  }

  void _addMember(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: AddMeetingMemberForm(
              meeting: widget.meeting,
              onEditMeeting: (context, _meeting) {
                meetingChangedCallback(context, meeting: _meeting);
              }),
        );
      },
    );
  }

  Widget? _fabAtIndex(BuildContext context) {
    int latestEvent = Provider.of<EventNotifier>(context).latest.id;
    int index = _tabController.index;
    switch (index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: () {
            _addMember(context);
          },
          label: const Text('Add New Member'),
          icon: const Icon(Icons.edit),
        );
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
            body: Stack(
              children: [
                Container(
                  margin:
                      EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        MeetingBanner(
                          meeting: widget.meeting,
                          onEdit: (context, _meeting) {
                            meetingChangedCallback(context, meeting: _meeting);
                          },
                        ),
                        TabBar(
                          isScrollable: small,
                          controller: _tabController,
                          tabs: [
                            Tab(text: 'Participants'),
                            Tab(text: 'Communications'),
                          ],
                        ),
                        Expanded(
                          child:
                              TabBarView(controller: _tabController, children: [
                            MeetingMembers(
                                meeting: widget.meeting,
                                small: small,
                                onEditMeeting: (context, _meeting) {
                                  meetingChangedCallback(context,
                                      meeting: _meeting);
                                }),
                            MeetingsCommunications(
                              communications: widget.meeting.communications,
                              small: small,
                              onCommunicationDeleted: (thread_ID) =>
                                  meetingChangedCallback(context,
                                      fm: _meetingService.deleteThread(
                                          id: widget.meeting.id,
                                          threadID: thread_ID)),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
                appBar,
              ],
            ),
            floatingActionButton: _fabAtIndex(context));
      });
    });
  }
}
