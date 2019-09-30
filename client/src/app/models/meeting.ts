export class Meeting {
    id: String;
    begin: Date;
    end: Date;
    place: String;
    minute: String;
    participants: MeetingParticipants;
}

export class MeetingParticipants {
    members: String[];
    companyReps: String[];
}
