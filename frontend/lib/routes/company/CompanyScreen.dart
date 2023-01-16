import 'package:flutter/material.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/components/addThreadForm.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/participationCard.dart';
import 'package:frontend/components/threadCard.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/routes/company/CompanyTableNotifier.dart';
import 'package:frontend/routes/company/EditCompanyForm.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/services/companyService.dart';
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

  Future<void> companyChangedCallback(BuildContext context,
      {Future<Company?>? fs, Company? company}) async {
    Company? s;
    if (fs != null) {
      s = await fs;
    } else if (company != null) {
      s = company;
    }
    if (s != null) {
      Provider.of<CompanyTableNotifier>(context, listen: false).edit(s);
      setState(() {
        widget.company = s!;
      });
    }
  }

  void _addThreadModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: AddThreadForm(
              company: widget.company,
              onEditCompany: (context, _company) {
                companyChangedCallback(context, company: _company);
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
      case 1:
        return null;
      case 2:
        {
          if (widget.company.lastParticipation != latestEvent) {
            return FloatingActionButton.extended(
              onPressed: () => companyChangedCallback(context,
                  fs: _companyService.addParticipation(
                      id: widget.company.id, partner: false)),
              label: const Text('Add Participation'),
              icon: const Icon(Icons.add),
            );
          } else {
            return null;
          }
        }
      case 3:
        {
          return FloatingActionButton.extended(
            onPressed: () {
              _addThreadModal(context);
            },
            label: const Text('Add Communication'),
            icon: const Icon(Icons.add),
          );
        }
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Consumer<CompanyTableNotifier>(builder: (context, notif, child) {
        return Scaffold(
            appBar: CustomAppBar(disableEventChange: true),
            body: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  CompanyBanner(
                    company: widget.company,
                    statusChangeCallback: (step, context) {
                      companyChangedCallback(
                        context,
                        fs: _companyService.stepParticipationStatus(
                            id: widget.company.id, step: step),
                      );
                    },
                    onEdit: (context, _comp) {
                      companyChangedCallback(context, company: _comp);
                    },
                  ),
                  TabBar(
                    isScrollable: small,
                    controller: _tabController,
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
                      widget.company.participations!.isEmpty ?
                      Center(child: Text('No participations yet')):
                      ParticipationList(
                        company: widget.company,
                        onParticipationChanged:
                            (Map<String, dynamic> body) async {
                          await companyChangedCallback(
                            context,
                            fs: _companyService.updateParticipation(
                              id: widget.company.id,
                              notes: body['notes'],
                              member: body['member'],
                              partner: body['partner'],
                              confirmed: body['confirmed'],
                            ),
                          );
                        },
                        onParticipationAdded: () =>
                            companyChangedCallback(context,
                                fs: _companyService.addParticipation(
                                  id: widget.company.id,
                                  partner: false,
                                )),
                      ),
                      widget.company.participations!.isEmpty ?
                      Center(child: Text('No communications yet')):
                      CommunicationsList(
                          participations: widget.company.participations ?? [],
                          small: small),
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
  final void Function(BuildContext, Company?) onEdit;

  const CompanyBanner(
      {Key? key,
      required this.company,
      required this.statusChangeCallback,
      required this.onEdit})
      : super(key: key);

  void _editCompanyModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: EditCompanyForm(company: company, onEdit: this.onEdit),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int event = Provider.of<EventNotifier>(context).event.id;
    bool isLatestEvent = Provider.of<EventNotifier>(context).isLatest;
    Participation? part = company.participations!
        .firstWhereOrNull((element) => element.event == event);
    bool hasParticipation = part != null; 
    ParticipationStatus companyStatus =
        part != null ? part.status : ParticipationStatus.NO_STATUS;
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
                              ),
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(300.0),
                              child: Image.network(
                                company.companyImages.internal,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context, Object exception,
                                  StackTrace? stackTrace) {
                                    return Image.asset(
                                      'assets/noImage.png'
                                    );
                                }
                              ),
                            )
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
                            if (isLatestEvent && hasParticipation)
                              CompanyStatusDropdownButton(
                                companyStatus: companyStatus,
                                statusChangeCallback: statusChangeCallback,
                                companyId: company.id,
                              ),
                            if (!isLatestEvent)
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
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _editCompanyModal(context);
              },
            )
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
