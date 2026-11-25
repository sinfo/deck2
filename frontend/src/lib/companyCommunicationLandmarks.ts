import type { RelatedCompany } from "@/dto/companies";
import type { Event } from "@/dto/events";
import type { Participation } from "@/dto";

const calendarDate = (date?: string) =>
  date && !date.startsWith("0001-01-01")
    ? Date.parse(date.slice(0, 10))
    : NaN;

export function getEditionRelationshipLandmarks(
  participations: readonly Participation[],
  events: readonly Event[],
  selectedEventId: number | null,
  relationships: readonly RelatedCompany[],
  communications: readonly { posted: string }[],
) {
  if (
    selectedEventId === null ||
    !participations.some(({ event }) => event === selectedEventId)
  ) {
    return [];
  }

  const selectedEvent = events.find(({ id }) => id === selectedEventId);
  const editionEnd = calendarDate(selectedEvent?.end);
  if (!Number.isFinite(editionEnd)) return [];

  // Use the previous edition in which this company actually participated.
  const previousEventId = participations.reduce<number | undefined>(
    (previous, { event }) =>
      event < selectedEventId && (previous === undefined || event > previous)
        ? event
        : previous,
    undefined,
  );
  const previousEvent = events.find(({ id }) => id === previousEventId);
  const previousEnd = calendarDate(previousEvent?.end);
  if (previousEventId !== undefined && !Number.isFinite(previousEnd)) return [];

  // Communications are already sorted from oldest to newest.
  const firstMessage = Date.parse(communications[0]?.posted ?? "");
  const lastMessage = Date.parse(
    communications[communications.length - 1]?.posted ?? "",
  );

  return relationships.filter(
    (relationship): relationship is RelatedCompany & { since: string } => {
      const date = calendarDate(relationship.since);
      if (!Number.isFinite(date) || date > editionEnd) return false;

      // Never show a change before our first contact in the first edition.
      if (previousEventId === undefined) {
        if (!(date >= firstMessage)) return false;
      } else if (date <= previousEnd) {
        return false;
      }

      // No trailing landmarks. With no messages, an inter-edition change
      // can still provide context at the top of the new edition.
      return !communications.length || date <= lastMessage;
    },
  );
}
