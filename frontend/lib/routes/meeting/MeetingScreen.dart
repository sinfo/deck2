import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/routes/meeting/MeetingsNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/meetingService.dart';
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

  void _addMember(context) {
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
        return FloatingActionButton.extended(
          onPressed: () {
            _addMember(context);
          },
          label: const Text('Add New Member'),
          icon: const Icon(Icons.edit),
          backgroundColor: Color(0xff5C7FF2),
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
            appBar: CustomAppBar(disableEventChange: true),
            body: DefaultTabController(
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
            floatingActionButton: _fabAtIndex(context));
      });
    });
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
          const SnackBar(content: Text('Error downloading minutes')),
        );
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading')),
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
                                            child: Icon(Icons.calendar_today,
                                                color: Colors.white),
                                          ),
                                          TextSpan(
                                            text: ' ' +
                                                DateFormat.d()
                                                    .format(meeting.begin) +
                                                ' ' +
                                                DateFormat.MMMM()
                                                    .format(meeting.begin)
                                                    .toUpperCase(),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: _infoFontSize),
                                          ),
                                        ])),
                                        RichText(
                                            text: TextSpan(children: [
                                          WidgetSpan(
                                            child: Icon(Icons.schedule,
                                                color: Colors.white),
                                          ),
                                          TextSpan(
                                            text: ' ' +
                                                DateFormat.Hm().format(
                                                    meeting.begin.toLocal()) +
                                                ' - ' +
                                                DateFormat.Hm().format(
                                                    meeting.end.toLocal()),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: _infoFontSize),
                                          ),
                                        ])),
                                        RichText(
                                            text: TextSpan(children: [
                                          WidgetSpan(
                                            child: Icon(Icons.place,
                                                color: Colors.white),
                                          ),
                                          TextSpan(
                                            text: ' ' + meeting.place,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: _infoFontSize),
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
                                                    primary: meeting
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
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            primary: const Color(
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
