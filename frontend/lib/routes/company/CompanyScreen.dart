import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/participationCard.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/routes/company/CompanyTableNotifier.dart';
import 'package:frontend/routes/speaker/speakerNotifier.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/routes/speaker/EditSpeakerForm.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class CompanyScreen extends StatefulWidget {
  Company company;

  CompanyScreen({Key? key, required this.company}) : super(key: key);

  @override
  _CompanyScreenState createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CompanyService _companyService;

  @override
  void initState() {
    super.initState();
    _companyService = CompanyService();
    _tabController = TabController(length: 4, vsync: this);
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

  Future<void> companyChangedCallback(
      BuildContext context, Future<Company?> fs) async {
    Company? s = await fs;
    if (s != null) {
      Provider.of<CompanyTableNotifier>(context, listen: false).edit(s);
      setState(() {
        widget.company = s;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Consumer<SpeakerTableNotifier>(builder: (context, notif, child) {
        return Scaffold(
          body: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                CompanyBanner(
                  company: widget.company,
                  statusChangeCallback: (step, context) {
                    companyChangedCallback(
                      context,
                      _companyService.stepParticipationStatus(
                          id: widget.company.id, step: step),
                    );
                  },
                ),
                TabBar(
                  isScrollable: small,
                  controller: _tabController,
                  labelColor: Colors.indigo,
                  unselectedLabelColor: Colors.indigo[100],
                  tabs: [
                    Tab(text: 'Details'),
                    Tab(text: 'BillingInfo'),
                    Tab(text: 'Participations'),
                    Tab(text: 'Communications'),
                  ],
                ),
                Expanded(
                  child: TabBarView(controller: _tabController, children: [
                    DetailsScreen(
                      company: widget.company,
                    ),
                    Container(
                      child: Center(child: Text('Work in progress :)')),
                    ),
                    ParticipationList(
                      company: widget.company,
                      onParticipationChanged:
                          (Map<String, dynamic> body) async {
                        await companyChangedCallback(
                          context,
                          _companyService.updateParticipation(
                            id: widget.company.id,
                            notes: body['notes'],
                            member: body['member'],
                            partner: body['partner'],
                            confirmed: body['confirmed'],
                          ),
                        );
                      },
                      onParticipationAdded: () => companyChangedCallback(
                          context,
                          _companyService.addParticipation(
                            id: widget.company.id,
                            partner: false,
                          )),
                    ),
                    Container(decoration: BoxDecoration(color: Colors.teal)),
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

class ParticipationList extends StatelessWidget {
  final Company company;
  final Future<void> Function(Map<String, dynamic>) onParticipationChanged;
  final void Function() onParticipationAdded;
  const ParticipationList({
    Key? key,
    required this.company,
    required this.onParticipationChanged,
    required this.onParticipationAdded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool small = constraints.maxWidth < App.SIZE;
        if (company.participations != null) {
          if (company.lastParticipation ==
              Provider.of<EventNotifier>(context).latest.id) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: ListView(
                  children: company.participations!.reversed
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ParticipationCard(
                              participation: e,
                              small: small,
                              type: CardType.COMPANY,
                              onEdit: onParticipationChanged,
                            ),
                          ))
                      .toList(),
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ParticipationCard.addParticipationCard(
                          onParticipationAdded),
                    ),
                    ...company.participations!.reversed
                        .map((e) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ParticipationCard(
                                participation: e,
                                small: small,
                                type: CardType.COMPANY,
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
            );
          }
        } else {
          return Container();
        }
      },
    );
  }
}

class CompanyBanner extends StatelessWidget {
  final Company company;
  final void Function(int, BuildContext) statusChangeCallback;
  const CompanyBanner(
      {Key? key, required this.company, required this.statusChangeCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    int event = Provider.of<EventNotifier>(context).event.id;
    bool isEditable = Provider.of<EventNotifier>(context).isLatest;
    Participation? part = company.participations!
        .firstWhereOrNull((element) => element.event == event);
    ParticipationStatus companyStatus =
        part != null ? part.status : ParticipationStatus.NO_STATUS;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool small = constraints.maxWidth < App.SIZE;
        return Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/banner_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: small ? 4 : 20, vertical: small ? 5 : 25),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(8.0, 8.0, small ? 8 : 20.0, 8.0),
                      child: SizedBox(
                        height: small ? 100 : 150,
                        width: small ? 100 : 150,
                        child: Hero(
                          tag: company.id + event.toString(),
                          child: Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: small ? 2 : 4,
                                  color: STATUSCOLOR[companyStatus]!,
                                )),
                            child: CircleAvatar(
                              foregroundImage: NetworkImage(
                                company.companyImages.internal ??
                                    company.companyImages.public ??
                                    '',
                              ),
                              backgroundImage: AssetImage('assets/noImage.png'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(small ? 8 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.name,
                              style: Theme.of(context).textTheme.headline5,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isEditable)
                              CompanyStatusDropdownButton(
                                companyStatus: companyStatus,
                                statusChangeCallback: statusChangeCallback,
                                companyId: company.id,
                              ),
                            if (!isEditable)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: STATUSCOLOR[companyStatus]),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(STATUSSTRING[companyStatus]!),
                                  ),
                                ),
                              ),
                            //TODO define subscribe behaviour
                            ElevatedButton(
                                onPressed: () => print('zona'),
                                child: Text('+ Subscribe'))
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                mouseCursor: SystemMouseCursors.click,
                onTap: () {}, //TODO: Edit company,
                child: Icon(Icons.edit),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CompanyStatusDropdownButton extends StatelessWidget {
  final void Function(int, BuildContext) statusChangeCallback;
  final ParticipationStatus companyStatus;
  final String companyId;
  final CompanyService _companyService = CompanyService();

  CompanyStatusDropdownButton({
    Key? key,
    required this.statusChangeCallback,
    required this.companyStatus,
    required this.companyId,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _companyService.getNextParticipationSteps(id: companyId),
      builder: (context, snapshot) {
        List<ParticipationStep> steps = [
          ParticipationStep(next: companyStatus, step: 0)
        ];
        if (snapshot.hasData) {
          steps.addAll(snapshot.data as List<ParticipationStep>);
        }
        return Container(
          child: DropdownButton<ParticipationStep>(
            underline: Container(
              height: 3,
              decoration: BoxDecoration(color: STATUSCOLOR[companyStatus]),
            ),
            value: steps[0],
            style: Theme.of(context).textTheme.subtitle2,
            selectedItemBuilder: (BuildContext context) {
              return steps.map((e) {
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(child: Text(STATUSSTRING[e.next]!)),
                );
              }).toList();
            },
            items: steps
                .map((e) => DropdownMenuItem<ParticipationStep>(
                      value: e,
                      child: Text(STATUSSTRING[e.next] ?? ''),
                    ))
                .toList(),
            onChanged: (next) {
              if (next != null && next.step != 0) {
                statusChangeCallback(next.step, context);
              }
            },
          ),
        );
      },
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final Company company;
  const DetailsScreen({Key? key, required this.company}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: EditableCard(
              title: 'Description',
              body: company.description ?? "",
              bodyEditedCallback: (newBio) {
                //speaker.bio = newBio;
                //TODO replace bio with service call to change bio
                print('replaced bio');
                return Future.delayed(Duration.zero);
              },
              isSingleline: false,
              textInputType: TextInputType.multiline,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
            child: EditableCard(
              title: 'Site',
              body: company.site ?? "",
              bodyEditedCallback: (newNotes) {
                //speaker.bio = newBio;
                //TODO replace bio with service call to change bio
                print('replaced notes');
                return Future.delayed(Duration.zero);
              },
              isSingleline: false,
              textInputType: TextInputType.multiline,
            ),
          ),
        ],
      )),
    );
  }
}
