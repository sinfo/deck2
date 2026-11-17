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
import type {
  EntityLinkResult,
  GmailEntity,
  GmailSyncWindow,
  SyncResult,
} from "./common";
import type { GmailSyncClient } from "./client";
import type { GmailMessageData } from "@/api/companies";

export interface FullSyncOptions {
  forceReScan?: boolean;
  // Used by incremental sync to search only new correspondence.
  recentAfterEpoch?: number;
}

const syncEntity = async (
  entity: GmailEntity,
  client: GmailSyncClient,
  window: GmailSyncWindow,
  options: FullSyncOptions,
  assignedEntities: GmailEntity[],
): Promise<EntityLinkResult | null> => {
  const existing = entity.existingThreads;
  const isRecent = options.recentAfterEpoch !== undefined;
  let query: string | undefined;
  let stage = "loading contact addresses";

  try {
    // Normal full sync keeps existing links and only refreshes their messages.
    if (existing.length > 0 && !options.forceReScan && !isRecent) {
      for (let offset = 0; offset < existing.length; offset += 20) {
        stage = "fetching previously linked Gmail messages";
        const messages = await client.fetchMessages(
          existing.slice(offset, offset + 20),
        );
        if (!messages.ok) throw new Error(messages.error);
        const inEdition = editionMessagesByThread(messages.value, window);
        const batch = [...inEdition.values()].flat();
        if (batch.length > 0) {
          stage = "saving Gmail messages in Deck";
          await entity.syncMessages(batch);
        }
      }
      return entityResult(entity, "ALREADY_LINKED", existing);
    }

    // Contact information is optional, including when its lookup fails.
    let emails: string[] = [];
    try {
      emails = normalizeEmails(await entity.fetchEmails());
    } catch (error) {
      console.warn(
        `[Gmail sync] Contact lookup unavailable for ${entity.type} ${entity.name}; searching by name: ${errorMessage(error)}`,
      );
    }

    const afterEpoch = Math.max(
      window.afterEpoch,
      options.recentAfterEpoch ?? window.afterEpoch,
    );
    if (afterEpoch >= window.beforeEpoch) return null;

    const allowed = new Set(emails);
    // Gmail matches query terms within messages, not across entire threads.
    // Search by name/email, then verify the SINFO edition within the thread.
    query = gmailSearchQuery(entity.name, emails, window, afterEpoch);
    if (!query) {
      return isRecent
        ? null
        : entityResult(
            entity,
            existing.length ? "ALREADY_LINKED" : "NOT_FOUND",
            existing,
          );
    }
    const editionMention = new RegExp(`\\bSINFO\\s+${window.edition}\\b`, "i");
    const found = new Set(existing);
    const added: string[] = [];
    let synced = false;

    stage = "searching Gmail threads";
    const scanned = await client.scanThreads(query, async (threads) => {
      const ids = threads.map((thread) => thread.id);
      if (ids.length === 0) return success(undefined);

      const response = await client.fetchMessages(ids);
      if (!response.ok) {
        return failure(`fetching Gmail thread messages: ${response.error}`);
      }

      const byThread = editionMessagesByThread(response.value, {
        ...window,
        afterEpoch,
      });
      // Inspect each candidate thread once, including its older messages.
      const editionThreads = new Set<string>();
      const emailThreads = new Set<string>();
      const namedThreads = new Map<string, Set<string>>();
      for (const message of response.value) {
        const text = [
          message.subject,
          message.from,
          message.to,
          message.body,
        ].join("\n");
        if (editionMention.test(text)) editionThreads.add(message.threadId);

        if (
          [...emailsInHeader(message.from), ...emailsInHeader(message.to)].some(
            (email) => allowed.has(email),
          )
        ) {
          emailThreads.add(message.threadId);
        }

        for (const assigned of assignedEntities) {
          if (!mentionsGmailEntity(text, assigned.name)) continue;
          const matched = namedThreads.get(message.threadId) ?? new Set<string>();
          matched.add(`${assigned.type}:${assigned.id}`);
          namedThreads.set(message.threadId, matched);
        }
      }
      const batch: GmailMessageData[] = [];

      for (const [id, messages] of byThread) {
        // An edition mention anywhere in the thread is mandatory. A name-only
        // match must also be unique among the member's assigned entities.
        if (!editionThreads.has(id)) continue;
        const names = namedThreads.get(id);
        const uniqueNameMatch =
          names?.size === 1 && names.has(`${entity.type}:${entity.id}`);
        if (!emailThreads.has(id) && !uniqueNameMatch) continue;

        batch.push(...messages);
        if (!found.has(id)) {
          found.add(id);
          added.push(id);
        }
      }

      if (batch.length > 0) {
        try {
          await entity.syncMessages(batch);
        } catch (error) {
          return failure(
            `saving Gmail messages in Deck: ${errorMessage(error)}`,
          );
        }
        synced = true;
      }
      return success(undefined);
    });

    if (!scanned.ok) throw new Error(scanned.error);
    if (added.length > 0) {
      stage = "linking Gmail threads to the participation";
      await entity.updateThreadIds([...found]);
    }

    if (isRecent && !synced) return null;
    if (!synced) {
      return entityResult(
        entity,
        existing.length ? "ALREADY_LINKED" : "NOT_FOUND",
        existing,
        0,
        { searchQueryUsed: query },
      );
    }
    return entityResult(entity, "SUCCESS", [...found], added.length, {
      searchQueryUsed: query,
    });
  } catch (error) {
    return entityResult(entity, "ERROR", existing, 0, {
      errorMessage: `${stage}: ${errorMessage(error)}`,
      searchQueryUsed: query,
    });
  }
};

export const runFullGmailSync = async (
  eventId: number,
  options: FullSyncOptions,
  client: GmailSyncClient,
  onProgress: (name: string, completed: number, total: number) => void,
): Promise<SyncResult<EntityLinkResult[]>> => {
  const window = await loadGmailSyncWindow(eventId);
  if (!window.ok) return failure(window.error);

  // Never scan unassigned entities, even during a forced rescan.
  const entities = await loadGmailEntities(eventId, true);
  if (!entities.ok) return failure(entities.error);

  const results: EntityLinkResult[] = [];
  for (const [index, entity] of entities.value.entries()) {
    onProgress(entity.name, index, entities.value.length);
    const result = await syncEntity(
      entity,
      client,
      window.value,
      options,
      entities.value,
    );
    if (result) results.push(result);
    onProgress(entity.name, index + 1, entities.value.length);
  }

  return success(results);
};
