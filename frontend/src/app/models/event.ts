export class Event {
    id: Number;
    name: String;
    begin: Date;
    end: Date;
    themes: String[];
    packages: EventPackages[];
    items: String[];
    meetings: String[];
    sessions: String[];
    teams: String[];
}

export class EventPackages {
    template: String;
    public_name: String;
    available: Boolean;
}

export function EventComparator(e1: Event, e2: Event) {
    if (e1.id < e2.id) { return 1; }
    if (e1.id > e2.id) { return -1; }
    return 0;
}
