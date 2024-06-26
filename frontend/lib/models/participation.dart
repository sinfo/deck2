import 'package:frontend/models/billing.dart';
import 'package:frontend/models/flightInfo.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/models/thread.dart';
import 'package:frontend/services/billingService.dart';
import 'package:frontend/services/flightInfoService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/packageService.dart';
import 'package:frontend/services/threadService.dart';

enum ParticipationStatus {
  SUGGESTED,
  SELECTED,
  ON_HOLD,
  CONTACTED,
  IN_CONVERSATIONS,
  ACCEPTED,
  REJECTED,
  GIVEN_UP,
  ANNOUNCED,
  NO_STATUS
}

class Room {
  final int? cost;
  final String? notes;
  final String? type;

  Room({this.cost, this.notes, this.type});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(cost: json['cost'], notes: json['notes'], type: json['type']);
  }

  Map<String, dynamic> toJson() => {'cost': cost, 'notes': notes, 'type': type};
}

class Participation {
  MemberService _memberService = MemberService();
  ThreadService _threadService = ThreadService();

  final int event;

  final String memberId;
  Member? _member;

  final ParticipationStatus status;

  final List<String>? communicationsId;
  List<Thread>? _communications;

  Future<Member?> get member async {
    if (_member != null) return _member;

    _member = await _memberService.getMember(memberId);
    return _member;
  }

  Future<List<Thread>?> get communications async {
    if (_communications != null && _communications!.length > 0) {
      return _communications;
    } else if (communicationsId == null || communicationsId == []) {
      return [];
    }

    List<Thread> l = [];
    for (String element in communicationsId!) {
      Thread? t = await _threadService.getThread(element);
      if (t != null) {
        l.add(t);
      }
    }

    _communications = l;
    return _communications;
  }

  Participation({
    required this.event,
    required this.memberId,
    required this.communicationsId,
    required this.status,
  });

  static String statusToString(ParticipationStatus s) {
    switch (s) {
      case ParticipationStatus.SUGGESTED:
        return "SUGGESTED";
      case ParticipationStatus.SELECTED:
        return "SELECTED";
      case ParticipationStatus.ON_HOLD:
        return "ON HOLD";
      case ParticipationStatus.CONTACTED:
        return "CONTACTED";
      case ParticipationStatus.IN_CONVERSATIONS:
        return "IN CONVERSATIONS";
      case ParticipationStatus.ACCEPTED:
        return "ACCEPTED";
      case ParticipationStatus.ANNOUNCED:
        return "ANNOUNCED";
      case ParticipationStatus.REJECTED:
        return "REJECTED";
      case ParticipationStatus.GIVEN_UP:
        return "GIVE UP";
      default:
        return "GIVE UP";
    }
  }

  static ParticipationStatus convert(String s) {
    s = s.toUpperCase();

    switch (s) {
      case "SUGGESTED":
        return ParticipationStatus.SUGGESTED;
      case "SELECTED":
        return ParticipationStatus.SELECTED;
      case "ON HOLD":
        return ParticipationStatus.ON_HOLD;
      case "CONTACTED":
        return ParticipationStatus.CONTACTED;
      case "IN_CONVERSATIONS":
        return ParticipationStatus.IN_CONVERSATIONS;
      case "ACCEPTED":
        return ParticipationStatus.ACCEPTED;
      case "ANNOUNCED":
        return ParticipationStatus.ANNOUNCED;
      case "REJECTED":
        return ParticipationStatus.REJECTED;
      case "GIVEN_UP":
        return ParticipationStatus.GIVEN_UP;
      default:
        return ParticipationStatus.GIVEN_UP;
    }
  }

  factory Participation.fromJson(Map<String, dynamic> json) {
    return Participation(
      event: json['event'],
      memberId: json['member'],
      status: Participation.convert(json['status']),
      communicationsId: List.from(json['communications']),
    );
  }
}

class SpeakerParticipation extends Participation {
  final String? feedback;
  final List<String>? flightsId;
  List<FlightInfo>? _flights;
  final Room? room;

  Future<List<FlightInfo>?> get flights async {
    if (_flights != null && _flights!.length == 0) {
      return _flights;
    }
    if (flightsId == null) {
      return [];
    }

    List<FlightInfo> l = [];
    FlightInfoService _flightInfoService = FlightInfoService();
    for (String element in flightsId!) {
      FlightInfo? fi = await _flightInfoService.getFlightInfo(element);
      l.add(fi);
    }

    _flights = l;
    return _flights;
  }

  SpeakerParticipation({
    required int event,
    required String member,
    required List<String> communicationIds,
    required ParticipationStatus status,
    this.feedback,
    this.flightsId,
    this.room,
  }) : super(
          communicationsId: communicationIds,
          event: event,
          memberId: member,
          status: status,
        );

  factory SpeakerParticipation.fromJson(Map<String, dynamic> json) {
    return SpeakerParticipation(
      communicationIds: List.from(json['communications']),
      event: json['event'],
      feedback: json['feedback'],
      flightsId: List.from(json['flights']),
      member: json['member'],
      status: Participation.convert(json['status']),
      room: Room.fromJson(json['room']),
    );
  }

  Map<String, dynamic> toJson() => {
        'communications': communicationsId,
        'event': event,
        'feedback': feedback,
        'flights': flightsId,
        'member': memberId,
        'status': Participation.statusToString(status),
        'room': room?.toJson()
      };
}

class PublicParticipation {
  final int? event;
  final String? feedback;

  PublicParticipation({this.event, this.feedback});

  factory PublicParticipation.fromJson(Map<String, dynamic> json) {
    return PublicParticipation(
        event: json['event'], feedback: json['feedback']);
  }

  Map<String, dynamic> toJson() => {'event': event, 'feedback': feedback};
}

class ParticipationStep {
  final ParticipationStatus next;
  final int step;

  ParticipationStep({required this.next, required this.step});

  factory ParticipationStep.fromJson(Map<String, dynamic> json) {
    return ParticipationStep(
        next: Participation.convert(json['next']), step: json['step']);
  }
}

class CompanyParticipation extends Participation {
  PackageService _packageService = PackageService();
  BillingService _billingService = BillingService();

  final String? packageId;
  Package? _package;
  final String? billingId;
  Billing? _billing;

  final DateTime? confirmed;
  final bool? partner;
  final String? notes;

  CompanyParticipation({
    required int event,
    required String memberId,
    required ParticipationStatus status,
    required List<String> communicationsId,
    this.packageId,
    this.confirmed,
    this.partner,
    this.notes,
    this.billingId,
  }) : super(
          event: event,
          memberId: memberId,
          status: status,
          communicationsId: communicationsId,
        );

  factory CompanyParticipation.fromJson(Map<String, dynamic> json) {
    return CompanyParticipation(
      event: json['event'],
      memberId: json['member'],
      status: Participation.convert(json['status']),
      communicationsId: List.from(json['communications']),
      packageId: json['package'],
      billingId: json['billing'],
      confirmed: DateTime.parse(json['confirmed']),
      partner: json['partner'],
      notes: json['notes'],
    );
  }

  Future<Package?> get package async {
    if (_package != null) return _package;
    if (packageId == null) return null;

    _package = await _packageService.getPackage(packageId!);
    return _package;
  }

  Future<Billing?> get billing async {
    if (_billing != null) return _billing;
    if (billingId == null) return null;

    _billing = await _billingService.getBilling(billingId!);
    return _billing;
  }

  Map<String, dynamic> toJson() => {
        'event': event,
        'member': memberId,
        'status': Participation.statusToString(status),
        'communications': communicationsId,
        'package': packageId,
        'billing': billingId,
        'confirmed': confirmed != null ? confirmed!.toIso8601String() : '',
        'partner': partner,
        'notes': notes,
      };
}
