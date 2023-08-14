import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/threads/participations/participationThreadsWidget.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/requirement.dart';
import 'package:frontend/models/template.dart';
import '../../../services/templateService.dart';

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
  TemplateService templateService = new TemplateService();

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
        // ElevatedButton(
        //   child: Text("Create Templates"),
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: Colors.red,
        //     elevation: 0,
        //   ),
        //   onPressed: () async {
        //     FilePickerResult? result = await FilePicker.platform.pickFiles();
        //     if (result != null) {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(content: Text('Creating')),
        //       );

        //       PlatformFile template = result.files.first;

        //       Requirement requirement1 = new Requirement(title: "Insert Company Name", name:"companyName", type: "String");

        //       //Requirement requirement2 = new Requirement(title: "Insert User Name", name:"userName", type:"String");

        //       List<Requirement> requirements = [ 
        //         requirement1,
        //         //requirement2,
        //       ];

        //       // TODO insert form field to select name of template
        //       Template? m = await templateService.createTemplate(
        //         name: "Company Template", requirements: requirements);

        //       if (m != null) {
        //         m = await templateService.uploadTemplateFile(
        //           id: m.id, template: template);
        //         ScaffoldMessenger.of(context).hideCurrentSnackBar();

        //         ScaffoldMessenger.of(context).showSnackBar(
        //           SnackBar(
        //             content: Text('Done'),
        //             duration: Duration(seconds: 2),
        //           ),
        //         );
        //       } else {
        //         ScaffoldMessenger.of(context).hideCurrentSnackBar();

        //         ScaffoldMessenger.of(context).showSnackBar(
        //           const SnackBar(content: Text('An error occured.')),
        //         );
        //       }
        //     }
        //   },
        // ),
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
