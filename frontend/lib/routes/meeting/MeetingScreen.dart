import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/components/threads/addThreadForm.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/threads/threadCard/threadCard.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/thread.dart';
import 'package:frontend/routes/meeting/AddMeetingMemberForm.dart';
import 'package:frontend/routes/meeting/MeetingsNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _addThreadModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: AddThreadForm(
            meeting: widget.meeting,
            onAddMeeting: (thread_text) {
              meetingChangedCallback(context,
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
                            MeetingParticipants(
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

class MeetingParticipants extends StatelessWidget {
  Meeting meeting;
  final bool small;
  final void Function(BuildContext, Meeting?)? onEditMeeting;

  MeetingParticipants(
      {Key? key,
      required this.meeting,
      required this.small,
      required this.onEditMeeting})
      : super(key: key);

  double cardWidth = 200;
  MemberService _memberService = MemberService();
  MeetingService _meetingService = MeetingService();
  ScrollController _controller = ScrollController();

  void _deleteMeetingParticipant(context, id, type, name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog('Warning',
            'Are you sure you want to delete ${name} from meeting ${meeting.title}?',
            () async {
          Meeting? m = await _meetingService.deleteMeetingParticipant(
              id: meeting.id, memberID: id, type: type);
          if (m != null) {
            MeetingsNotifier notifier =
                Provider.of<MeetingsNotifier>(context, listen: false);
            notifier.edit(m);

            onEditMeeting!(context, m);

            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Done', style: TextStyle(color: Colors.white)),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('An error occured.',
                      style: TextStyle(color: Colors.white))),
            );
          }
        });
      },
    );
  }

  Widget MeetingMembersGrid(List<Future<Member?>> _members, String type) {
    if (_members != []) {
      return FutureBuilder(
          future: Future.wait(_members),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Member?> membs = snapshot.data as List<Member?>;
              membs.sort((a, b) => a!.name.compareTo(b!.name));

              cardWidth = small ? 125 : 200;

              return GridView.builder(
                  controller: _controller,
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width ~/ cardWidth,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: membs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Column(children: [
                      ListViewCard(small: small, member: membs[index]),
                      ElevatedButton.icon(
                          onPressed: () => _deleteMeetingParticipant(context,
                              membs[index]!.id, type, membs[index]!.name),
                          icon: Icon(Icons.delete),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          label: const Text("Delete participant")),
                    ]);
                  });
            } else {
              return Center(child: CircularProgressIndicator());
            }
          });
    } else {
      return Text("Meeting without this kind of members");
    }
  }

  Widget Separator(_text) {
    return Column(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          child: Text(_text, style: TextStyle(fontSize: small ? 14 : 18)),
          margin: EdgeInsets.fromLTRB(0, 8, 8, 0),
        ),
        Divider(thickness: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Future<Member?>> _futureMembers = [];
    if (meeting.participants.membersIds != []) {
      _futureMembers = meeting.participants.membersIds!
          .map((memberID) => _memberService.getMember(memberID))
          .toList();
    }

    List<Future<Member?>> _futureCompanyReps = [];
    if (meeting.participants.companyRepIds != []) {
      _futureCompanyReps = meeting.participants.companyRepIds!
          .map((memberID) => _memberService.getMember(memberID))
          .toList();
    }

    return SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
                child: Column(children: [
              Separator("Members"),
              Container(
                  child: Center(
                      child: MeetingMembersGrid(_futureMembers, "MEMBER"))),
              Separator("Company Reps"),
              Container(
                  child: Center(
                      child: MeetingMembersGrid(
                          _futureCompanyReps, "COMPANYREP"))),
            ]))));
  }
}

class MeetingsCommunications extends StatelessWidget {
  final Future<List<Thread>?> communications;
  final bool small;
  final void Function(String) onCommunicationDeleted;

  MeetingsCommunications(
      {Key? key,
      required this.communications,
      required this.small,
      required this.onCommunicationDeleted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder(
        future: communications,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error');
          }
          if (snapshot.connectionState == ConnectionState.done) {
            List<Thread>? threads = snapshot.data as List<Thread>?;
            if (threads == null) {
              threads = [];
            }
            threads.sort((a, b) => b.posted.compareTo(a.posted));
            return ListView(controller: ScrollController(), children: [
              ...threads
                  .map(
                    (thread) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ThreadCard(
                        thread: thread,
                        small: small,
                        onCommunicationDeleted: onCommunicationDeleted,
                      ),
                    ),
                  )
                  .toList(),
            ]);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class MeetingBanner extends StatelessWidget {
  final Meeting meeting;
  final void Function(BuildContext, Meeting?) onEdit;
  final MeetingService _meetingService = MeetingService();

  MeetingBanner({Key? key, required this.meeting, required this.onEdit})
      : super(key: key);

  void _uploadMeetingMinute(context) async {
    if (meeting.minute!.isNotEmpty) {
      Uri uri = Uri.parse(meeting.minute!);
      if (!await launchUrl(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error downloading minutes',
                  style: TextStyle(color: Colors.white))),
        );
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Uploading', style: TextStyle(color: Colors.white))),
        );

        PlatformFile minute = result.files.first;

        Meeting? m = await _meetingService.uploadMeetingMinute(
            id: meeting.id, minute: minute);

        if (m != null) {
          MeetingsNotifier notifier =
              Provider.of<MeetingsNotifier>(context, listen: false);
          notifier.edit(m);

          onEdit(context, m);

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Done', style: TextStyle(color: Colors.white)),
              duration: Duration(seconds: 2),
            ),
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
    }
  }

  void _deleteMeetingMinuteDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog('Warning',
            'Are you sure you want to delete meeting minutes of ${meeting.title}?',
            () {
          _deleteMeetingMinute(context);
        });
      },
    );
  }

  void _deleteMeetingMinute(context) async {
    Meeting? m = await _meetingService.deleteMeetingMinute(meeting.id);
    if (m != null) {
      MeetingsNotifier notifier =
          Provider.of<MeetingsNotifier>(context, listen: false);
      notifier.edit(m);

      onEdit(context, m);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Done', style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
        ),
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
                                  style: TextStyle(fontSize: _titleFontSize),
                                  overflow: TextOverflow.ellipsis,
                                )),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: small
                                        ? 0
                                        : MediaQuery.of(context).size.width /
                                            10),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                            text: TextSpan(children: [
                                          WidgetSpan(
                                            child: Icon(Icons.calendar_today),
                                          ),
                                          TextSpan(
                                            text: ' ' +
                                                DateFormat.d()
                                                    .format(meeting.begin) +
                                                ' ' +
                                                DateFormat.MMMM()
                                                    .format(meeting.begin)
                                                    .toUpperCase() +
                                                ' ' +
                                                DateFormat.y()
                                                    .format(meeting.begin)
                                                    .toUpperCase(),
                                            style: TextStyle(
                                                fontSize: _infoFontSize,
                                                color:
                                                    Provider.of<ThemeNotifier>(
                                                                context)
                                                            .isDark
                                                        ? Colors.white
                                                        : Colors.black),
                                          ),
                                        ])),
                                        RichText(
                                            text: TextSpan(children: [
                                          WidgetSpan(
                                            child: Icon(Icons.schedule),
                                          ),
                                          TextSpan(
                                            text: ' ' +
                                                DateFormat.Hm().format(
                                                    meeting.begin.toLocal()) +
                                                ' - ' +
                                                DateFormat.Hm().format(
                                                    meeting.end.toLocal()),
                                            style: TextStyle(
                                                fontSize: _infoFontSize,
                                                color:
                                                    Provider.of<ThemeNotifier>(
                                                                context)
                                                            .isDark
                                                        ? Colors.white
                                                        : Colors.black),
                                          ),
                                        ])),
                                        RichText(
                                            text: TextSpan(children: [
                                          WidgetSpan(
                                            child: Icon(Icons.place),
                                          ),
                                          TextSpan(
                                            text: ' ' + meeting.place,
                                            style: TextStyle(
                                                fontSize: _infoFontSize,
                                                color:
                                                    Provider.of<ThemeNotifier>(
                                                                context)
                                                            .isDark
                                                        ? Colors.white
                                                        : Colors.black),
                                          ),
                                        ])),
                                        RichText(
                                            text: TextSpan(children: [
                                          WidgetSpan(
                                            child: Icon(
                                                Icons.format_list_numbered),
                                          ),
                                          TextSpan(
                                            text: ' ' +
                                                meeting.kind.toLowerCase(),
                                            style: TextStyle(
                                                fontSize: _infoFontSize,
                                                color:
                                                    Provider.of<ThemeNotifier>(
                                                                context)
                                                            .isDark
                                                        ? Colors.white
                                                        : Colors.black),
                                          ),
                                        ])),
                                      ],
                                    ),
                                    Expanded(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                          if (DateTime.now()
                                              .isAfter(meeting.begin))
                                            ElevatedButton.icon(
                                                onPressed: () =>
                                                    _uploadMeetingMinute(
                                                        context),
                                                icon: Icon(Icons.article),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: meeting
                                                            .minute!.isNotEmpty
                                                        ? const Color(
                                                            0xFF5C7FF2)
                                                        : Colors.green),
                                                label: meeting
                                                        .minute!.isNotEmpty
                                                    ? const Text("Minutes")
                                                    : const Text(
                                                        "Add Minutes")),
                                          if (DateTime.now()
                                                  .isAfter(meeting.begin) &&
                                              meeting.minute!.isNotEmpty)
                                            Container(
                                                margin: const EdgeInsets.only(
                                                    top: 5.0),
                                                child: ElevatedButton.icon(
                                                    onPressed: () =>
                                                        _deleteMeetingMinuteDialog(
                                                            context),
                                                    icon: Icon(Icons.article),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                const Color(
                                                                    0xFFF25C5C)),
                                                    label: const Text(
                                                        "Delete Minutes")))
                                        ])),
                                  ],
                                ))
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
