import 'dart:convert';


class Meeting{
    final String id;
    final DateTime begin;
    final DateTime end;
    final String place;
    final String minute;
    final MeetingParticipants participants;
     
    Meeting(
      {this.id, this.begin, this.end, this.place, this.minute, this.participants }); 

    factory Meeting.fromJson(Map<String, dynamic> json) {
        return Meeting(
             id : json['id'],
             begin : DateTime.parse(json['begin']),
             end:  DateTime.parse(json['end']),
             place : json['place'],
             minute:  json['minute'],
             participants: MeetingParticipants.fromJson(json['participants'])
        );
    }

    Map<String, dynamic> toJson() => {
        'id' : id,
        'begin' : begin,
        'end' : end,
        'place' : place,
        'minute' : minute,
        'participants' : participants.toJson()
    };


    @override
    String toString() {
      return json.encode(this.toJson());
    }
}


class MeetingParticipants{

    final List<String> membersIds;
    final List<String> companyRepIds;

    MeetingParticipants(
      {this.membersIds, this.companyRepIds }); 

    factory MeetingParticipants.fromJson(Map<String, dynamic> json) {
        return MeetingParticipants(
            membersIds: json['members'],
            companyRepIds: json['companyReps']
        );
    }

    Map<String, dynamic> toJson() => {
        'members' : membersIds,
        'companyReps' : companyRepIds
    };


    @override
    String toString() {
      return json.encode(this.toJson());
    }

}