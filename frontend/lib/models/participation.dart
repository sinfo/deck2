import 'package:frontend/models/member.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/models/thread.dart';
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
    if (_communications != null && _communications!.length == 0) {
      return _communications;
    }
    if (communicationsId == null) {
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
  final List<String>? flights; //TODO: Lazy load
  final Room? room;

  SpeakerParticipation({
    required int event,
    required String member,
    required List<String> communicationIds,
    required ParticipationStatus status,
    this.feedback,
    this.flights,
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
      flights: List.from(json['flights']),
      member: json['member'],
      status: Participation.convert(json['status']),
      room: Room.fromJson(json['room']),
    );
  }

  Map<String, dynamic> toJson() => {
        'communications': communicationsId,
        'event': event,
        'feedback': feedback,
        'flights': flights,
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

  final String? packageId;
  Package? _package;

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

  Map<String, dynamic> toJson() => {
        'event': event,
        'member': memberId,
        'status': Participation.statusToString(status),
        'communications': communicationsId,
        'package': packageId,
        'confirmed': confirmed != null ? confirmed!.toIso8601String() : '',
        'partner': partner,
        'notes': notes,
      };
}
