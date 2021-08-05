enum ParticipationStatus {
  SUGGESTED,
  SELECTED,
  ON_HOLD,
  CONTACTED,
  IN_CONVERSATIONS,
  ACCEPTED,
  REJECTED,
  GIVEN_UP,
  ANNOUNCED
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
  final List<String>? communications;
  final int? event;
  final String? feedback;
  final List<String>? flights;
  final String? member;
  final ParticipationStatus? status;
  final List<String>? subscribers;
  final Room? room;

  Participation(
      {this.communications,
      this.event,
      this.feedback,
      this.flights,
      this.member,
      this.status,
      this.subscribers,
      this.room});

  factory Participation.fromJson(Map<String, dynamic> json) {
    return Participation(
        communications: json['communications'],
        event: json['event'],
        feedback: json['feedback'],
        flights: json['flights'],
        member: json['member'],
        status: json['status'],
        subscribers: json['subscribers'],
        room: Room.fromJson(json['room']));
  }

  Map<String, dynamic> toJson() => {
        'communications': communications,
        'event': event,
        'feedback': feedback,
        'flights': flights,
        'member': member,
        'status': status,
        'subscribers': subscribers,
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
  final String? next;
  final int? step;

  ParticipationStep({this.next, this.step});

  factory ParticipationStep.fromJson(Map<String, dynamic> json) {
    return ParticipationStep(
      next: json['next'],
      step: json['step']
    );
  }
}