import {
  editionMessagesByThread,
  emailsInHeader,
  entityResult,
  errorMessage,
  failure,
  gmailSearchQuery,
  loadGmailEntities,
  loadGmailSyncWindow,
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
): Promise<EntityLinkResult | null> => {
  const existing = entity.existingThreads;
  const isRecent = options.recentAfterEpoch !== undefined;
  let query: string | undefined;

  try {
    // Normal full sync keeps existing links and only refreshes their messages.
    if (existing.length > 0 && !options.forceReScan && !isRecent) {
      for (let offset = 0; offset < existing.length; offset += 20) {
        const messages = await client.fetchMessages(existing.slice(offset, offset + 20));
        if (!messages.ok) throw new Error(messages.error);
        const inEdition = editionMessagesByThread(messages.value, window);
        const batch = [...inEdition.values()].flat();
        if (batch.length > 0) await entity.syncMessages(batch);
      }
      return entityResult(entity, "ALREADY_LINKED", existing);
    }

    const emails = normalizeEmails(await entity.fetchEmails());
    if (emails.length === 0) {
      return isRecent
        ? null
        : entityResult(entity, existing.length ? "ALREADY_LINKED" : "NOT_FOUND", existing);
    }

    const afterEpoch = Math.max(
      window.afterEpoch,
      options.recentAfterEpoch ?? window.afterEpoch,
    );
    if (afterEpoch >= window.beforeEpoch) return null;

    const allowed = new Set(emails);
    query = gmailSearchQuery(emails, window, afterEpoch);
    const found = new Set(existing);
    const added: string[] = [];
    let synced = false;

    const scanned = await client.scanThreads(query, async (threads) => {
      const ids = threads.map((thread) => thread.id);
      if (ids.length === 0) return success(undefined);

      const response = await client.fetchMessages(ids);
      if (!response.ok) return failure(response.error);

      const byThread = editionMessagesByThread(response.value, {
        ...window,
        afterEpoch,
      });
      const batch = [];

      for (const [id, messages] of byThread) {
        if (
          !messages.some((message) =>
            [...emailsInHeader(message.from), ...emailsInHeader(message.to)]
              .some((email) => allowed.has(email)),
          )
        ) continue;

        batch.push(...messages);
        if (!found.has(id)) {
          found.add(id);
          added.push(id);
        }
      }

      if (batch.length > 0) {
        await entity.syncMessages(batch);
        synced = true;
      }
      return success(undefined);
    });

    if (!scanned.ok) throw new Error(scanned.error);
    if (added.length > 0) await entity.updateThreadIds([...found]);

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
      errorMessage: errorMessage(error),
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
    const result = await syncEntity(entity, client, window.value, options);
    if (result) results.push(result);
    onProgress(entity.name, index + 1, entities.value.length);
  }

  return success(results);
};
