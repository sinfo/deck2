export class Session {
    id: String;
    begin: Date;
    end: Date;
    title: String;
    description: String;
    kind: String;
    place: String;
    company: String;
    speaker: String;
    videoURL: String;
    tickets: SessionTickets;
}

export class SessionDinamizers {
    name: String;
    position: String;
}

export class SessionTickets {
    begin: Date;
    end: Date;
    max: Number;
}
