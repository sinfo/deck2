import {
  editionMessagesByThread,
  emailsInHeader,
  entityResult,
  errorMessage,
  failure,
  gmailSearchQuery,
  loadGmailEntities,
  loadGmailSyncWindow,
  mentionsGmailEntity,
  normalizeEmails,
  success,
} from "./common";
import type { EntityLinkResult, GmailEntity, SyncResult } from "./common";
import type { GmailSyncClient } from "./client";
import type { GmailMessageData } from "@/api/companies";
import type { GmailThreadListItem } from "../useGmailMessages";

interface EntityState {
  entity: GmailEntity;
  emails: Set<string>;
  linked: Set<string>;
  newlyLinked: number;
  synced: boolean;
  error?: string;
}

// Prefer known contacts; without an email match, a name must identify
// exactly one assigned company or speaker.
const matchEntity = (
  messages: GmailMessageData[],
  states: EntityState[],
): EntityState | undefined => {
  const addresses = messages.flatMap((message) => [
    ...emailsInHeader(message.from),
    ...emailsInHeader(message.to),
  ]);
  const byEmail = states.filter((state) =>
    addresses.some((address) => state.emails.has(address)),
  );
  if (byEmail.length > 0) return byEmail.length === 1 ? byEmail[0] : undefined;

  const byName = states.filter((state) =>
    messages.some((message) =>
      mentionsGmailEntity(
        [message.subject, message.from, message.to, message.body].join("\n"),
        state.entity.name,
      ),
    ),
  );
  return byName.length === 1 ? byName[0] : undefined;
};

export const runFullGmailSync = async (
  eventId: number,
  client: GmailSyncClient,
  onProgress: (name: string, completed: number, total: number) => void,
  recentAfterEpoch?: number,
): Promise<SyncResult<EntityLinkResult[]>> => {
  const window = await loadGmailSyncWindow(eventId);
  if (!window.ok) return failure(window.error);

  const entities = await loadGmailEntities(eventId, true);
  if (!entities.ok) return failure(entities.error);
  if (entities.value.length === 0) return success([]);

  const afterEpoch = Math.max(
    window.value.afterEpoch,
    recentAfterEpoch ?? window.value.afterEpoch,
  );
  if (afterEpoch >= window.value.beforeEpoch) return success([]);

  // Load only the signed-in member's assigned entities. Contact email is
  // optional; names remain available when the contact lookup fails.
  const states: EntityState[] = [];
  for (const entity of entities.value) {
    let emails: string[];
    try {
      emails = normalizeEmails(await entity.fetchEmails());
    } catch {
      emails = [];
    }
    states.push({
      entity,
      emails: new Set(emails),
      linked: new Set(entity.existingThreads),
      newlyLinked: 0,
      synced: false,
    });
  }

  // Full discovery uses one edition search. Keep recent searches scoped to
  // assigned entities until we optimize incremental updates separately.
  const isRecent = recentAfterEpoch !== undefined;
  const queries = isRecent
    ? [
        ...new Set(
          states
            .map((state) =>
              gmailSearchQuery(
                state.entity.name,
                [...state.emails],
                window.value,
                afterEpoch,
              ),
            )
            .filter(Boolean),
        ),
      ]
    : [
        `after:${afterEpoch - 1} before:${window.value.beforeEpoch} "SINFO ${window.value.edition}"`,
      ];
  const editionMention = new RegExp(
    `\\bSINFO\\s+${window.value.edition}\\b`,
    "i",
  );
  const seenThreads = new Set<string>();

  onProgress("Searching Gmail", 0, states.length);
  const visitPage = async (threads: GmailThreadListItem[]): Promise<SyncResult<void>> => {
    const ids = threads
      .map((thread) => thread.id)
      .filter((id) => !seenThreads.has(id));
    if (ids.length === 0) return success(undefined);

    const fetched = await client.fetchMessages(ids);
    if (!fetched.ok) {
      return failure(`fetching Gmail thread messages: ${fetched.error}`);
    }
    ids.forEach((id) => seenThreads.add(id));

    // Keep only one page of complete conversations in memory.
    const allMessages = new Map<string, GmailMessageData[]>();
    for (const message of fetched.value) {
      const messages = allMessages.get(message.threadId);
      if (messages) {
        messages.push(message);
      } else {
        allMessages.set(message.threadId, [message]);
      }
    }
    const inEdition = editionMessagesByThread(fetched.value, {
      ...window.value,
      afterEpoch,
    });

    const batches = new Map<
      EntityState,
      { messages: GmailMessageData[]; threadIds: string[] }
    >();
    for (const [threadId, messages] of inEdition) {
      const conversation = allMessages.get(threadId);
      if (
        !conversation ||
        !conversation.some((message) =>
          editionMention.test(`${message.subject}\n${message.body}`),
        )
      ) {
        continue;
      }

      const state = matchEntity(conversation, states);
      if (!state || state.error) continue;

      const batch = batches.get(state);
      if (batch) {
        batch.messages.push(...messages);
        batch.threadIds.push(threadId);
      } else {
        batches.set(state, { messages: [...messages], threadIds: [threadId] });
      }
    }

    for (const [state, batch] of batches) {
      try {
        await state.entity.syncMessages(batch.messages);
        state.synced = true;
        for (const id of batch.threadIds) {
          if (!state.linked.has(id)) {
            state.linked.add(id);
            state.newlyLinked++;
          }
        }
      } catch (error) {
        state.error = `saving Gmail messages in Deck: ${errorMessage(error)}`;
      }
    }
    return success(undefined);
  };

  let scanError: string | undefined;
  for (const query of queries) {
    const scanned = await client.scanThreads(query, visitPage);
    if (!scanned.ok) {
      scanError = scanned.error;
      break;
    }
  }

  const results: EntityLinkResult[] = [];
  for (const [index, state] of states.entries()) {
    onProgress(state.entity.name, index, states.length);
    if (state.newlyLinked > 0) {
      try {
        await state.entity.updateThreadIds([...state.linked]);
      } catch (error) {
        state.error = `linking Gmail threads to the participation: ${errorMessage(error)}`;
      }
    }

    if (!isRecent || state.synced || state.error) {
      results.push(
        entityResult(
          state.entity,
          state.error
            ? "ERROR"
            : state.synced
              ? "SUCCESS"
              : state.linked.size > 0
                ? "ALREADY_LINKED"
                : "NOT_FOUND",
          [...state.linked],
          state.newlyLinked,
          state.error ? { errorMessage: state.error } : {},
        ),
      );
    }
    onProgress(state.entity.name, index + 1, states.length);
  }

  if (scanError !== undefined) return failure(scanError);
  return success(results);
};
