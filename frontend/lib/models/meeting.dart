import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';

class Meeting {
  final String id;
  final DateTime start;
  final DateTime end;
  final String place;
  final String minute; // Ata
  final MeetingParticipants participants;

  Meeting({
    this.id,
    this.start,
    this.end,
    this.place,
    this.minute,
    this.participants,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'],
      start: DateTime(json['begin']),
      end: DateTime(json['end']),
      place: json['place'],
      minute: json['minute'],
      participants: MeetingParticipants.fromJson(json['participants']),
    );
  }
}

class MeetingParticipants {
  final List<Member> members;
  final List<CompanyRep> companyReps;

  MeetingParticipants({
    this.members,
    this.companyReps,
  });

  factory MeetingParticipants.fromJson(Map<String, dynamic> json) {
    var members = json['members'] as List;
    var reps = json['companyReps'] as List;
    return MeetingParticipants(
      members: members.map((e) => Member.fromJson(e)).toList(),
      companyReps: reps.map((e) => CompanyRep.fromJson(e)).toList(),
    );
  }
}
