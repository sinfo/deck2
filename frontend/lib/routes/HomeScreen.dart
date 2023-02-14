import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/drawer.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/routes/company/CompanyPage.dart';
import 'package:frontend/routes/speaker/SpeakerPage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleSignIn googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
        initialPage:
            Provider.of<BottomNavigationBarProvider>(context, listen: false)
                .currentIndex,
        keepPage: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CustomAppBar appBar = CustomAppBar(disableEventChange: false);

    return Scaffold(
      bottomNavigationBar: CustomNavBar(
        onTapped: (newIndex) {
          Provider.of<BottomNavigationBarProvider>(context, listen: false)
              .currentIndex = newIndex;
          _pageController.animateToPage(newIndex,
              duration: Duration(milliseconds: 800), curve: Curves.ease);
        },
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  colorFilter: ColorFilter.mode(
                      Provider.of<ThemeNotifier>(context).isDark
                          ? Colors.grey.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.1),
                      BlendMode.srcATop),
                  fit: BoxFit.contain,
                  image: AssetImage('assets/logo_deck.png'),
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
            child: SizedBox.expand(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  Provider.of<BottomNavigationBarProvider>(context,
                          listen: false)
                      .currentIndex = index;
                },
                children: <Widget>[
                  Center(
                    child: const SpeakerPage(),
                  ),
                  Center(
                    child: const LandingPage(),
                  ),
                  Center(
                    child: const CompanyPage(),
                  )
                ],
              ),
            ),
          ),
          appBar,
        ],
      ),
      drawer: DeckDrawer(),
      floatingActionButton: _fabAtIndex(context,
          Provider.of<BottomNavigationBarProvider>(context).currentIndex),
    );
  }

  Widget? _fabAtIndex(BuildContext context, int index) {
    int currentEvent = Provider.of<EventNotifier>(context).event.id;
    int latestEvent = Provider.of<EventNotifier>(context).latest.id;
    bool disabled = currentEvent != latestEvent;
    if (disabled) {
      return null;
    }
    switch (index) {
      case 0:
        {
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.AddSpeaker,
              );
            },
            label: const Text('Create New Speaker'),
            icon: const Icon(Icons.person_add),
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
                Routes.AddCompany,
              );
            },
            label: const Text('Create New Company'),
            icon: const Icon(Icons.business),
          );
        }
      default:
        {
          return null;
        }
    }
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      child: Text("Welcome to deck2! In Progress..."),
    );
  }
}

class CustomNavBar extends StatelessWidget {
  final Function(int) onTapped;
  const CustomNavBar({Key? key, required this.onTapped}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex:
          Provider.of<BottomNavigationBarProvider>(context).currentIndex,
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
      ],
      onTap: onTapped,
    );
  }
}
