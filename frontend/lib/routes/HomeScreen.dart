import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/drawer.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/company/CompanyTable.dart';
import 'package:frontend/routes/MemberListWidget.dart';
import 'package:frontend/routes/meeting/MeetingCard.dart';
import 'package:frontend/routes/speaker/SpeakerTable.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;
  GoogleSignIn googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");
  late PageController _pageController;

  @override
  void initState() {
    _pageController =
        PageController(initialPage: _currentIndex, keepPage: true);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Member? user = Provider.of<Member?>(context);
    return Scaffold(
      appBar: CustomAppBar(),
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                label: 'Speakers',
                icon: Icon(
                  Icons.star,
                )),
            BottomNavigationBarItem(
                label: 'Home',
                icon: Icon(
                  Icons.home,
                )),
            BottomNavigationBarItem(
                label: 'Companies',
                icon: Icon(
                  Icons.work,
                )),
            //FIXME: o item aqui em baixo foi colocado apenas para processo de development
            BottomNavigationBarItem(
                label: 'Members',
                icon: Icon(
                  Icons.people,
                )),
          ],
          onTap: (newIndex) {
            setState(() {
              _currentIndex = newIndex;
              _pageController.animateToPage(_currentIndex,
                  duration: Duration(milliseconds: 800), curve: Curves.easeOut);
            });
          }),
      body: SizedBox.expand(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: <Widget>[
            Center(
                child: Consumer<EventNotifier>(
              builder: (context, value, child) => SpeakerTable(),
            )),
            Center(
              child: MeetingList(),
            ),
            Center(
              child: Consumer<EventNotifier>(
                  builder: (context, value, child) => CompanyTable()),
            ),
            Center(child: MemberListWidget()),
          ],
        ),
      ),
      drawer: DeckDrawer(image: user != null ? user.image : ''),
      floatingActionButton: _fabAtIndex(_currentIndex),
    );
  }

  Widget? _fabAtIndex(int index) {
    switch (index) {
      case 0:
        {
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.ShowAllSpeakers,
              );
            },
            label: const Text('Show All Speakers'),
            icon: const Icon(Icons.add),
            backgroundColor: Color(0xff5C7FF2),
          );
        }
      case 1:
        {
          return null;
        }
      case 2:
        {
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.ShowAllCompanies,
              );
            },
            label: const Text('Show All Companies'),
            icon: const Icon(Icons.add),
            backgroundColor: Color(0xff5C7FF2),
          );
        }
    }
  }
}

class MeetingList extends StatefulWidget {
  const MeetingList({Key? key}) : super(key: key);

  @override
  _MeetingListState createState() => _MeetingListState();
}

class _MeetingListState extends State<MeetingList>
    with AutomaticKeepAliveClientMixin {
  final MeetingService _service = MeetingService();
  late final Future<List<Meeting>> _meetings;

  @override
  void initState() {
    _meetings = _service.getMeetings();
    super.initState();
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: _meetings,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Meeting> meets = snapshot.data as List<Meeting>;
          return ListView(
            children: meets.map((e) => MeetingCard(meeting: e)).toList(),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
