import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/routes/speaker/SpeakerListWidget.dart';
import 'package:frontend/routes/speaker/SpeakerTable.dart';

class SpeakerPage extends StatefulWidget {
  const SpeakerPage({Key? key}) : super(key: key);

  @override
  _SpeakerPageState createState() => _SpeakerPageState();
}

class _SpeakerPageState extends State<SpeakerPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Column(
        children: [
          TabBar(
            isScrollable: small,
            controller: _tabController,
            tabs: [
              Tab(text: 'Speakers by member'),
              Tab(text: 'All speakers'),
            ],
          ),
          Expanded(
            child: TabBarView(
                controller: _tabController,
                children: [SpeakerTable(), SpeakerListWidget()]),
          ),
        ],
      );
    });
  }
}
