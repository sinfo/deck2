import 'package:flutter/material.dart';
import 'package:frontend/components/threads/participations/participationThreadsWidget.dart';
import 'package:frontend/models/participation.dart';

class CommunicationsList extends StatefulWidget {
  final List<Participation> participations;
  final bool small;
  final void Function(String) onCommunicationDeleted;

  CommunicationsList(
      {Key? key,
      required this.participations,
      required this.small,
      required this.onCommunicationDeleted})
      : super(key: key);

  @override
  _CommunicationsListState createState() => _CommunicationsListState();
}

class _CommunicationsListState extends State<CommunicationsList>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: widget.participations
            .where((part) =>
                part.communicationsId != null &&
                part.communicationsId!.length != 0)
            .length,
        vsync: this);
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

  @override
  bool get wantKeepAlive => true;

  List<Widget> getCommunicationList() {
    if (widget.participations
            .where((part) =>
                part.communicationsId != null &&
                part.communicationsId!.length != 0)
            .length > 0) {
      return [
        TabBar(
          isScrollable: true,
          controller: _tabController,
          tabs: widget.participations
              .where((part) =>
                  part.communicationsId != null &&
                  part.communicationsId!.length != 0)
              .map((part) => Tab(text: "SINFO ${part.event}"))
              .toList(),
        ),
        Expanded(
            child: TabBarView(
                controller: _tabController,
                children: widget.participations
                    .where((part) =>
                        part.communicationsId != null &&
                        part.communicationsId!.length != 0)
                    .map((part) => ParticipationThreadsWidget(
                        participation: part,
                        small: widget.small,
                        onCommunicationDeleted: widget.onCommunicationDeleted))
                    .toList())),
      ];
    } else {
      return [Container()];
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          child: Column(children: getCommunicationList()));
    });
  }
}
