import {
  errorMessage,
  entityResult,
  failure,
  loadGmailEntities,
  success,
} from "./common";
import type { EntityLinkResult, GmailEntity, SyncResult } from "./common";
import type { GmailSyncClient } from "./client";

export interface FullSyncOptions {
  forceReScan?: boolean;
  onlyMyResponsibilities?: boolean;
}

const syncEntity = async (
  entity: GmailEntity,
  client: GmailSyncClient,
  forceReScan: boolean,
): Promise<EntityLinkResult> => {
  const existing = entity.existingThreads;
  let query: string | undefined;

  try {
    // Already linked: refresh its messages rather than searching the mailbox again.
    if (existing.length > 0 && !forceReScan) {
      const messages = await client.fetchMessages(existing);
      if (!messages.ok) {
        return entityResult(entity, "ERROR", existing, 0, {
          errorMessage: messages.error,
        });
      }
      if (messages.value.length > 0) await entity.syncMessages(messages.value);
      return entityResult(entity, "ALREADY_LINKED", existing);
    }

    const emails = await entity.fetchEmails();
    query = emails.length
      ? emails.map((email) => `from:${email} OR to:${email}`).join(" OR ")
      : `"${entity.name}"`;

    const matches = await client.listThreads(query);
    if (!matches.ok) {
      return entityResult(entity, "ERROR", existing, 0, {
        errorMessage: matches.error,
        searchQueryUsed: query,
      });
    }

    const matchedIds = matches.value.map((thread) => thread.id);
    if (matchedIds.length === 0) {
      return entityResult(entity, "NOT_FOUND", [], 0, {
        searchQueryUsed: query,
      });
    }

    const combined = [...new Set([...existing, ...matchedIds])];
    const added = combined.filter((id) => !existing.includes(id));

    if (added.length > 0) await entity.updateThreadIds(combined);

    const messages = await client.fetchMessages(combined);
    if (!messages.ok) {
      return entityResult(entity, "ERROR", existing, 0, {
        errorMessage: messages.error,
        searchQueryUsed: query,
      });
    }
    if (messages.value.length > 0) await entity.syncMessages(messages.value);

    return entityResult(entity, "SUCCESS", combined, added.length, {
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
  const entities = await loadGmailEntities(
    eventId,
    options.onlyMyResponsibilities !== false,
  );
  if (!entities.ok) return failure(entities.error);

  const results: EntityLinkResult[] = [];
  for (const entity of entities.value) {
    onProgress(entity.name, results.length, entities.value.length);
    results.push(
      await syncEntity(entity, client, options.forceReScan === true),
    );
    onProgress(entity.name, results.length, entities.value.length);
  }

  return success(results);
};
