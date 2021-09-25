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

  Map<String, dynamic> toJson() =>
      {'cost': notes, 'notes': notes, 'type': type};
}

class Participation {
  final List<String>? communications; //TODO: lazy load
  final int event;
  final String? feedback;
  final List<String>? flights; //TODO: Lazy load
  final String? member; //TODO: Lazy load
  final ParticipationStatus? status;
  final Room? room;

  Participation(
      {this.communications,
      required this.event,
      this.feedback,
      this.flights,
      this.member,
      this.status,
      this.room});

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
      case "IN CONVERSATIONS":
        return ParticipationStatus.IN_CONVERSATIONS;
      case "ACCEPTED":
        return ParticipationStatus.ACCEPTED;
      case "ANNOUNCED":
        return ParticipationStatus.ANNOUNCED;
      case "REJECTED":
        return ParticipationStatus.REJECTED;
      case "GIVE UP":
        return ParticipationStatus.GIVEN_UP;
      default:
        return ParticipationStatus.GIVEN_UP;
    }
  }

  factory Participation.fromJson(Map<String, dynamic> json) {
    return Participation(
        communications: List.from(json['communications']),
        event: json['event'],
        feedback: json['feedback'],
        flights: List.from(json['flights']),
        member: json['member'],
        status: convert(json['status']),
        room: Room.fromJson(json['room']));
  }

  Map<String, dynamic> toJson() => {
        'communications': communications,
        'event': event,
        'feedback': feedback,
        'flights': flights,
        'member': member,
        'status': status,
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
