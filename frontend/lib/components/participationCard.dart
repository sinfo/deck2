import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/packageCard.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/routes/items_packages/packages/PackageNotifier.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/packageService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

enum CardType {
  MEMBER,
  SPEAKER,
  COMPANY,
}

class ParticipationCard extends StatefulWidget {
  final Participation participation;
  final bool small;
  final CardType type;
  final void Function()? onDelete;
  final Future<void> Function(Map<String, dynamic>)? onEdit;
  final Future<void> Function(ParticipationStatus)? onChangeParticipationStatus;
  final Future<void> Function(Package)? onChangeCompanyPackage;

  ParticipationCard({
    Key? key,
    required this.participation,
    required this.small,
    required this.type,
    this.onDelete,
    this.onEdit,
    this.onChangeParticipationStatus,
    this.onChangeCompanyPackage,
  }) : super(key: key);

  static Widget addParticipationCard(Function() onAddParticipation) {
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return InkWell(
        onTap: onAddParticipation,
        child: DottedBorder(
          borderType: BorderType.RRect,
          color: Colors.grey,
          strokeCap: StrokeCap.round,
          strokeWidth: 4,
          dashPattern: [10, 8],
          radius: Radius.circular(5),
          child: Container(
            height: 130,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey[100]),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '+ Add Participation',
                  style: small
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  _ParticipationCardState createState() => _ParticipationCardState();
}

class _ParticipationCardState extends State<ParticipationCard> {
  late bool _expanded = false;
  bool _isEditing = false;
  bool _isWaiting = false;
  late TextEditingController _feedbackController;
  late TextEditingController _roomCostController;
  late TextEditingController _roomNotesController;
  late TextEditingController _roomTypeController;
  late TextEditingController _notesController;
  Member? _currentMember;
  late bool _partner;
  late DateTime? _confirmed;
  final MemberService _memberService = MemberService();
  final PackageService _packageService = PackageService();

  @override
  void initState() {
    super.initState();
    switch (widget.type) {
      case CardType.COMPANY:
        _initCompany();
        break;
      case CardType.SPEAKER:
        _initSpeaker();
        break;
      case CardType.MEMBER:
      default:
    }
  }

  List<Widget> _buildFields() {
    switch (widget.type) {
      case CardType.COMPANY:
        return _buildCompanyFields();
      case CardType.SPEAKER:
        return _buildSpeakerFields();
      case CardType.MEMBER:
      default:
        return [];
    }
  }

  void _initSpeaker() {
    _feedbackController = TextEditingController();
    _roomCostController = TextEditingController();
    _roomNotesController = TextEditingController();
    _roomTypeController = TextEditingController();
    _resetSpeakerControllers();
  }

  void _initCompany() {
    _notesController = TextEditingController();
    _resetCompanyControllers();
  }

  void _resetControllers() {
    switch (widget.type) {
      case CardType.COMPANY:
        _resetCompanyControllers();
        break;
      case CardType.SPEAKER:
        _resetSpeakerControllers();
        break;
      case CardType.MEMBER:
      default:
    }
  }

  void _resetSpeakerControllers() {
    SpeakerParticipation p = widget.participation as SpeakerParticipation;

    _feedbackController.text = p.feedback ?? '';
    _roomCostController.text = p.room != null
        ? p.room!.cost == 0
            ? ''
            : p.room!.cost.toString()
        : '';
    _roomNotesController.text = p.room != null ? p.room!.notes ?? '' : '';
    _roomTypeController.text = p.room != null ? p.room!.type ?? '' : '';
  }

  void _resetCompanyControllers() {
    CompanyParticipation p = widget.participation as CompanyParticipation;
    _notesController.text = p.notes ?? '';
    _confirmed = p.confirmed;
    _partner = p.partner ?? false;
  }

  String getDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  List<Future> getPackages(Event event) {
    List<Future> futures = [];
    for (EventPackage evPackage in event.eventPackagesId) {
      futures.add(_packageService.getPackage(evPackage.packageID));
    }
    return futures;
  }

  List<Widget> _buildCompanyFields() {
    CompanyParticipation p = widget.participation as CompanyParticipation;

    return [
      TextField(
        decoration: const InputDecoration(
          labelText: 'Notes',
          disabledBorder: InputBorder.none,
        ),
        enabled: _isEditing,
        controller: _notesController,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        maxLines: 8,
        minLines: 2,
      ),
      SwitchListTile(
        title: Text('Partner'),
        value: _partner,
        onChanged: _isEditing
            ? (bool value) {
                setState(() {
                  _partner = value;
                });
              }
            : null,
      ),
      ListTile(
        title: Text('Confirmed'),
        trailing: _isEditing
            ? ElevatedButton(
                child: Text('Select date'),
                onPressed: () => _selectDate(context),
              )
            : Text(_confirmed != null
                ? getDateTime(_confirmed!)
                : p.confirmed != null
                    ? getDateTime(p.confirmed!)
                    : ''),
      ),
      FutureBuilder(
        future: p.package,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error' + snapshot.error.toString());
          }
          if (snapshot.connectionState == ConnectionState.done) {
            Package? pack = snapshot.data as Package?;

            if (pack == null &&
                (p.status == ParticipationStatus.ACCEPTED ||
                    p.status == ParticipationStatus.ANNOUNCED)) {
              Event latest = Provider.of<EventNotifier>(context).latest;
              PackageNotifier notifier = Provider.of<PackageNotifier>(context);

              return FutureBuilder(
                  future: Future.wait(getPackages(latest)),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error' + snapshot.error.toString());
                    }
                    if (snapshot.connectionState == ConnectionState.done) {
                      List<dynamic> futurePacks =
                          snapshot.data as List<dynamic>;
                      List<Package> packs = [];

                      for (int i = 0; i < futurePacks.length; i++) {
                        Package p = futurePacks[i] as Package;
                        packs.add(p);
                      }

                      notifier.loadPackages(packs);

                      return DropdownButton<Package>(
                        icon: Icon(Icons.arrow_downward),
                        // iconSize: 16,
                        selectedItemBuilder: (BuildContext context) {
                          return notifier
                              .getPackages()
                              .map<Widget>((Package p) {
                            return Container(
                              alignment: Alignment.centerLeft,
                              constraints: const BoxConstraints(minWidth: 70),
                              child: Text(
                                p.name,
                                style: TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList();
                        },
                        underline: Container(height: 2),
                        onChanged: (Package? newPackage) async {
                          widget.onChangeCompanyPackage!(newPackage!);
                          setState(() {
                            pack = newPackage;
                          });
                        },
                        value: pack,
                        hint: Container(
                          alignment: Alignment.centerLeft,
                          constraints: const BoxConstraints(minWidth: 70),
                          child: Text(
                            'Pick a package',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        items: notifier
                            .getPackages()
                            .map<DropdownMenuItem<Package>>((e) =>
                                DropdownMenuItem<Package>(
                                    value: e, child: Text(e.name)))
                            .toList(),
                      );
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  });
            } else if (pack != null) {
              return PackageCard(package: pack);
            } else {
              return Container();
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    ];
  }

  Future<void> _selectDate(BuildContext context) async {
    final datePicker = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );

    final timePicker = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        });

    if (datePicker != null && timePicker != null) {
      setState(() {
        _confirmed = DateTime(datePicker.year, datePicker.month, datePicker.day,
            timePicker.hour, timePicker.minute);
      });
    }
  }

  List<Widget> _buildSpeakerFields() {
    return [
      TextField(
        decoration: const InputDecoration(
          labelText: 'Feedback',
          disabledBorder: InputBorder.none,
        ),
        enabled: _isEditing,
        controller: _feedbackController,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        maxLines: 8,
        minLines: 2,
      ),
      TextField(
        decoration: const InputDecoration(
          labelText: 'Room cost',
          disabledBorder: InputBorder.none,
        ),
        enabled: _isEditing,
        controller: _roomCostController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly
        ],
      ),
      TextField(
        decoration: const InputDecoration(
          labelText: 'Room notes',
          disabledBorder: InputBorder.none,
        ),
        enabled: _isEditing,
        controller: _roomNotesController,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        maxLines: 8,
        minLines: 2,
      ),
      TextField(
        decoration: const InputDecoration(
          labelText: 'Room type',
          disabledBorder: InputBorder.none,
        ),
        enabled: _isEditing,
        controller: _roomTypeController,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
      ),
    ];
  }

  void submitSpeaker(Member m) {
    String? feedback = _feedbackController.text;
    int? cost = int.tryParse(_roomCostController.text) ?? 0;
    String? notes = _roomNotesController.text;
    String? type = _roomTypeController.text;
    Map<String, dynamic> body = {
      "feedback": feedback,
      "room": Room(
        cost: cost,
        notes: notes,
        type: type,
      ),
      "member": _currentMember != null ? _currentMember!.id : m.id,
    };
    widget.onEdit!(body).then((value) {
      setState(() {
        _isEditing = false;
        _isWaiting = false;
      });
    });
    _isWaiting = true;
  }

  void submitCompany(Member m) {
    String? notes = _notesController.text;
    Map<String, dynamic> body = {
      "notes": notes,
      "partner": _partner,
      "confirmed": _confirmed == null ? null : _confirmed!.toUtc(),
      "member": _currentMember != null ? _currentMember!.id : m.id,
    };
    widget.onEdit!(body).then((value) {
      setState(() {
        _isEditing = false;
        _isWaiting = false;
      });
    });
    _isWaiting = true;
  }

  List<ParticipationStatus> getAllStatus() {
    List<ParticipationStatus> allStatus = STATUSSTRING.keys.toList();
    allStatus
        .removeWhere((element) => element == ParticipationStatus.NO_STATUS);
    return allStatus;
  }

  List<Widget> getStatus(bool editable) {
    if (editable) {
      return [
        DecoratedBox(
          decoration: BoxDecoration(
              color: STATUSCOLOR[widget.participation.status],
              borderRadius: BorderRadius.circular(5)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
            child: DropdownButton<ParticipationStatus>(
              icon: Icon(
                Icons.arrow_downward,
                color:
                    widget.participation.status == ParticipationStatus.GIVEN_UP
                        ? Colors.white
                        : Colors.black,
              ),
              // iconSize: 16,
              selectedItemBuilder: (BuildContext context) {
                return getAllStatus().map<Widget>((ParticipationStatus status) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    constraints: const BoxConstraints(minWidth: 70),
                    child: Text(
                      STATUSSTRING[status]!,
                      style: TextStyle(
                        color: widget.participation.status ==
                                ParticipationStatus.GIVEN_UP
                            ? Colors.white
                            : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList();
              },
              underline: Container(
                height: 2,
                color:
                    widget.participation.status == ParticipationStatus.GIVEN_UP
                        ? Colors.white
                        : Colors.black,
              ),
              onChanged: (ParticipationStatus? newStatus) async {
                widget.onChangeParticipationStatus!(newStatus!);
              },
              value: widget.participation.status,
              items: getAllStatus()
                  .map<DropdownMenuItem<ParticipationStatus>>((e) =>
                      DropdownMenuItem<ParticipationStatus>(
                          value: e, child: Text(STATUSSTRING[e]!)))
                  .toList(),
            ),
          ),
        )
      ];
    } else {
      return [
        Container(
          decoration: BoxDecoration(
              color: STATUSCOLOR[widget.participation.status],
              borderRadius: BorderRadius.circular(5)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              STATUSSTRING[widget.participation.status]!,
              style: TextStyle(
                color:
                    widget.participation.status == ParticipationStatus.GIVEN_UP
                        ? Colors.white
                        : Colors.black,
              ),
            ),
          ),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    bool editable = widget.participation.event ==
        Provider.of<EventNotifier>(context).latest.id;
    return FutureBuilder(
      future: widget.participation.member,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Member m = snapshot.data as Member;
          if (_currentMember == null) _currentMember = m;
          return Container(
            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
            padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SINFO ${widget.participation.event}',
                      textAlign: TextAlign.left,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    FutureBuilder(
                        future: Provider.of<AuthService>(context).role,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            Role r = snapshot.data as Role;

                            return Container(
                              child: Row(children: [
                                if (editable) ...[
                                  r == Role.ADMIN && widget.onDelete != null
                                      ? IconButton(
                                          constraints: BoxConstraints(),
                                          hoverColor: Colors.transparent,
                                          splashColor: Colors.transparent,
                                          icon: Icon(Icons.delete),
                                          color:
                                              Color.fromRGBO(211, 211, 211, 1),
                                          iconSize: 22,
                                          onPressed: () {
                                            BlurryDialog d = BlurryDialog(
                                                'Warning',
                                                'Are you sure you want to delete this participation?',
                                                widget.onDelete!);
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return d;
                                              },
                                            );
                                          })
                                      : Container(),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: IconButton(
                                        constraints: BoxConstraints(),
                                        hoverColor: Colors.transparent,
                                        splashColor: Colors.transparent,
                                        icon: !_isEditing
                                            ? Icon(Icons.edit)
                                            : Icon(Icons.cancel),
                                        color: !_isEditing
                                            ? const Color(0xff5c7ff2)
                                            : Colors.red,
                                        iconSize: 22,
                                        onPressed: () {
                                          setState(() {
                                            _isEditing = !_isEditing;
                                            _resetControllers();
                                          });
                                        }),
                                  )
                                ],
                                ...getStatus(editable)
                              ]),
                            );
                          }

                          return Container();
                        })
                  ],
                ),
                Divider(
                  color: Colors.grey[600],
                ),
                AnimatedCrossFade(
                  firstChild: Column(
                    children: [
                      Stack(
                        alignment: AlignmentDirectional.bottomEnd,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: widget.small ? 25 : 35,
                                height: widget.small ? 25 : 35,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Image.network(
                                    _currentMember != null
                                        ? _currentMember!.image!
                                        : m.image!,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return Image.asset(
                                        'assets/noImage.png',
                                        fit: BoxFit.fill,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _currentMember != null
                                      ? _currentMember!.name
                                      : m.name,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            child: Text('See more'),
                            onPressed: () {
                              setState(() {
                                _expanded = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  secondChild: Column(
                    children: [
                      Stack(
                        alignment: AlignmentDirectional.bottomEnd,
                        children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder(
                                    future: _memberService.getMembers(
                                        event:
                                            Provider.of<EventNotifier>(context)
                                                .event
                                                .id),
                                    builder: (context, snapshot) {
                                      List<Member> members = [
                                        _currentMember ?? m
                                      ];
                                      if (snapshot.hasData) {
                                        List<Member> ms =
                                            snapshot.data as List<Member>;
                                        ms.remove(_currentMember);
                                        ms.sort(
                                            (a, b) => a.name.compareTo(b.name));
                                        members.addAll(ms);
                                      }
                                      return Container(
                                        child: DropdownButton<Member>(
                                          underline: Container(
                                            height: 3,
                                          ),
                                          value: _currentMember,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2,
                                          selectedItemBuilder:
                                              (BuildContext context) {
                                            return members.map((e) {
                                              return Align(
                                                alignment: AlignmentDirectional
                                                    .centerStart,
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: widget.small
                                                          ? 25
                                                          : 35,
                                                      height: widget.small
                                                          ? 25
                                                          : 35,
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                        child: Image.network(
                                                          e.image!,
                                                          errorBuilder:
                                                              (BuildContext
                                                                      context,
                                                                  Object
                                                                      exception,
                                                                  StackTrace?
                                                                      stackTrace) {
                                                            return Image.asset(
                                                              'assets/noImage.png',
                                                              fit: BoxFit.fill,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Text(e.name),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList();
                                          },
                                          items: members
                                              .map((e) =>
                                                  DropdownMenuItem<Member>(
                                                    value: e,
                                                    child: Row(
                                                      children: [
                                                        SizedBox(
                                                          width: widget.small
                                                              ? 25
                                                              : 35,
                                                          height: widget.small
                                                              ? 25
                                                              : 35,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                            child:
                                                                Image.network(
                                                              e.image!,
                                                              errorBuilder: (BuildContext
                                                                      context,
                                                                  Object
                                                                      exception,
                                                                  StackTrace?
                                                                      stackTrace) {
                                                                return Image
                                                                    .asset(
                                                                  'assets/noImage.png',
                                                                  fit: BoxFit
                                                                      .fill,
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Text(e.name),
                                                        ),
                                                      ],
                                                    ),
                                                  ))
                                              .toList(),
                                          onChanged: _isEditing
                                              ? (next) {
                                                  setState(() {
                                                    _currentMember = next!;
                                                  });
                                                }
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                  ..._buildFields(),
                                ],
                              ),
                            ] +
                            (_isWaiting
                                ? [
                                    BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 5, sigmaY: 5),
                                      child: CircularProgressIndicator(),
                                    )
                                  ]
                                : []),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_expanded && !_isEditing)
                            TextButton(
                              child: Text('See less'),
                              onPressed: () {
                                setState(() {
                                  _expanded = false;
                                });
                              },
                            ),
                          if (_isEditing)
                            TextButton(
                              child: Text('Submit'),
                              onPressed: () {
                                switch (widget.type) {
                                  case CardType.COMPANY:
                                    return submitCompany(m);
                                  case CardType.SPEAKER:
                                    return submitSpeaker(m);
                                  case CardType.MEMBER:
                                  default:
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                  crossFadeState: !_isEditing && !_expanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: Duration(milliseconds: 250),
                  firstCurve: Curves.easeOut,
                  secondCurve: Curves.easeOut,
                  sizeCurve: Curves.easeOut,
                ),
              ],
            ),
          );
        } else {
          return Shimmer.fromColors(
            baseColor: Colors.grey[400]!,
            highlightColor: Colors.white,
            child: Container(
              margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
              padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(5),
              ),
              height: 135,
            ),
          );
        }
      },
    );
  }
}
