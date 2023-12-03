import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/flightInfo.dart';
import 'package:frontend/routes/flight/FlightsNotifier.dart';
import 'package:frontend/routes/flight/FlightCard.dart';
import 'package:frontend/services/flightInfoService.dart';
import 'package:provider/provider.dart';

class FlightPage extends StatefulWidget {
  const FlightPage({Key? key}) : super(key: key);

  @override
  _FlightPageState createState() => _FlightPageState();
}

class _FlightPageState extends State<FlightPage> with SingleTickerProviderStateMixin {
  late Future<List<FlightInfo>> _flights;
  FlightInfoService _flightInfoService = FlightInfoService();
  late TabController _tabController;

  @override
  void initState() {
    _flights = _flightInfoService.getFlights();
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    CustomAppBar _appBar = CustomAppBar(disableEventChange: true);
    return Scaffold(
      body: Stack(children: [
        Container(
          margin: EdgeInsets.fromLTRB(0, _appBar.preferredSize.height, 0, 0),
          child: FutureBuilder(
            future: _flights,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                FlightsNotifier notifier = Provider.of<FlightsNotifier>(context);

                notifier.flights = snapshot.data as List<FlightInfo>;

                return LayoutBuilder(builder: (context, constraints) {
                  bool small = constraints.maxWidth < App.SIZE;
                  return Column(
                    children: [
                      TabBar(
                        isScrollable: small,
                        controller: _tabController,
                        tabs: [
                          Tab(text: 'Upcoming'),
                          Tab(text: 'Past'),
                        ],
                      ),
                      Consumer<FlightsNotifier>(
                        builder: (context, cart, child) {
                          return Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                ListView(
                                  children: notifier
                                    .getUpcoming()
                                    .map((e) => FlightCard(flight: e))
                                    .toList()
                                ),
                                ListView(
                                  children: notifier
                                    .getPast()
                                    .map((e) => FlightCard(flight: e))
                                    .toList()
                                ),
                              ]
                            )
                          );
                        }
                      )
                    ]
                  );
                });
              } else {
                return CircularProgressIndicator();
              }
            }
          )
        ),
        _appBar,
      ])
    );
  }
}
