import type { Participation } from "@/dto";
import type { RelatedCompany } from "@/dto/companies";
import type { Event } from "@/dto/events";

const dateValue = (date?: string) =>
  date && !date.startsWith("0001-01-01")
    ? Date.parse(date.slice(0, 10))
    : NaN;

// Participations are ordered from the most recent edition to the oldest.
// Each group precedes the older edition of a gap between two participations.
export function groupParticipationLandmarks(
  participations: readonly Participation[],
  events: readonly Event[],
  relationships: readonly RelatedCompany[],
) {
  const groups = new Map<number, RelatedCompany[]>();
  if (participations.length < 2 || !relationships.length) return groups;

  const eventDates = new Map(events.map((event) => [event.id, event.begin]));
  const anchors = participations.map(({ event }) => ({
    event,
    date: dateValue(eventDates.get(event)),
  }));

  const changes = relationships
    .filter((relationship) => relationship.type !== "PARENT_OF")
    .map((relationship) => ({
      relationship,
      date: dateValue(relationship.since),
    }))
    .filter((change) => Number.isFinite(change.date))
    .sort((a, b) => b.date - a.date);

  for (const { relationship, date } of changes) {
    // Both adjacent participations must have known dates.
    const anchor = anchors.find(
      (anchor, index) =>
        index > 0 && date >= anchor.date && date < anchors[index - 1].date,
    );
    if (!anchor) continue;

    const event = anchor.event;
    const group = groups.get(event);
    if (group) {
      group.push(relationship);
    } else {
      groups.set(event, [relationship]);
    }
  }

  return groups;
}
