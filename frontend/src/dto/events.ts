import type { ObjectID } from ".";

export interface EventPackages {
  template: ObjectID;
  public_name: string;
  available: boolean;
}

export interface Event {
  id: number;
  name: string;
  begin?: string;
  end?: string;
  themes: string[];
  packages: EventPackages[];
  items: ObjectID[];
  meetings: ObjectID[];
  sessions: ObjectID[];
  teams: ObjectID[];
  calendarUrl: string;
}

export interface EventPublic {
  id: number;
  name: string;
  begin?: string;
  end?: string;
  themes: string[];
  calendarUrl: string;
}
