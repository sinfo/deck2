import 'package:flutter/material.dart';
import 'package:frontend/components/threads/addThreadForm.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/threads/participations/communicationsList.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/routes/company/billing/BillingScreen.dart';
import 'package:frontend/routes/company/CompanyTableNotifier.dart';
import 'package:frontend/routes/company/DetailsScreen.dart';
import 'package:frontend/routes/company/ParticipationList.dart';
import 'package:frontend/routes/company/banner/CompanyBanner.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/companyService.dart';
import 'package:provider/provider.dart';

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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Done.')),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occured.')),
      );
    }
  }

  void _addThreadModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: AddThreadForm(
              company: widget.company,
              onAddCompany: (thread_text, thread_kind) {
                companyChangedCallback(context,
                    fs: _companyService.addThread(
                        id: widget.company.id,
                        kind: thread_kind,
                        text: thread_text));
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
                      Tab(text: 'Billing'),
                      Tab(text: 'Participations'),
                      Tab(text: 'Communications'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(controller: _tabController, children: [
                      DetailsScreen(
                        company: widget.company,
                      ),
                      BillingScreen(
                        participations: widget.company.participations,
                        billingInfo: widget.company.billingInfo,
                        id: widget.company.id,
                        small: small,
                      ),
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
                      CommunicationsList(
                          participations: widget.company.participations != null
                              ? widget.company.participations!.reversed.toList()
                              : [],
                          onCommunicationDeleted: (thread_ID) =>
                              companyChangedCallback(context,
                                  fs: _companyService.deleteThread(
                                      id: widget.company.id,
                                      threadID: thread_ID)),
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
