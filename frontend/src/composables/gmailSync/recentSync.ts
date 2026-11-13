import type { GmailMessageData } from "@/api/companies";
import {
  emailsInHeader,
  entityResult,
  errorMessage,
  failure,
  loadGmailEntities,
  success,
  type EntityLinkResult,
  type GmailEntity,
  type SyncResult,
} from "./common";
import type { GmailSyncClient } from "./client";

interface PendingUpdate {
  entity: GmailEntity;
  messages: GmailMessageData[];
  threadIds: Set<string>;
}

const buildContactMap = async (
  entities: GmailEntity[],
): Promise<SyncResult<Map<string, GmailEntity>>> => {
  try {
    const contacts = await Promise.all(
      entities.map(async (entity) => ({
        entity,
        emails: await entity.fetchEmails(),
      })),
    );

    const byEmail = new Map<string, GmailEntity>();
    // Companies take priority if both types share an email address.
    for (const { entity, emails } of [
      ...contacts.filter(({ entity }) => entity.type === "speaker"),
      ...contacts.filter(({ entity }) => entity.type === "company"),
    ]) {
      for (const email of emails) byEmail.set(email.toLowerCase(), entity);
    }
    return success(byEmail);
  } catch (error) {
    return failure(errorMessage(error));
  }
};

export const runRecentGmailSync = async (
  eventId: number,
  lastSyncTime: number,
  client: GmailSyncClient,
): Promise<SyncResult<EntityLinkResult[]>> => {
  const afterEpoch = Math.max(0, Math.floor(lastSyncTime / 1000) - 180);
  const recentThreads = await client.listThreads(`after:${afterEpoch}`);
  if (!recentThreads.ok) return failure(recentThreads.error);
  if (recentThreads.value.length === 0) return success([]);

  const ids = [...new Set(recentThreads.value.map((thread) => thread.id))];
  const messages = await client.fetchMessages(ids);
  if (!messages.ok) return failure(messages.error);
  if (messages.value.length === 0) return success([]);

  const assigned = await loadGmailEntities(eventId, true);
  if (!assigned.ok) return failure(assigned.error);

  const contactMap = await buildContactMap(assigned.value);
  if (!contactMap.ok) return failure(contactMap.error);

  const byThread = new Map<string, GmailEntity>();
  for (const entity of [
    ...assigned.value.filter((e) => e.type === "speaker"),
    ...assigned.value.filter((e) => e.type === "company"),
  ]) {
    for (const threadId of entity.existingThreads)
      byThread.set(threadId, entity);
  }

  const pending = new Map<string, PendingUpdate>();
  for (const message of messages.value) {
    const addresses = [
      ...emailsInHeader(message.from),
      ...emailsInHeader(message.to),
    ];
    const candidates = addresses
      .map((email) => contactMap.value.get(email))
      .filter((item): item is GmailEntity => item !== undefined);
    const entity =
      byThread.get(message.threadId) ??
      candidates.find((candidate) => candidate.type === "company") ??
      candidates[0];
    if (!entity) continue;

    const key = `${entity.type}:${entity.id}`;
    const entry = pending.get(key) ?? {
      entity,
      messages: [],
      threadIds: new Set<string>(),
    };
    entry.messages.push(message);
    entry.threadIds.add(message.threadId);
    pending.set(key, entry);
  }

  const results: EntityLinkResult[] = [];
  for (const { entity, messages: batch, threadIds } of pending.values()) {
    try {
      const existing = entity.existingThreads;
      const combined = [...new Set([...existing, ...threadIds])];
      if (combined.length > existing.length) {
        await entity.updateThreadIds(combined);
      }
      await entity.syncMessages(batch);
      results.push(
        entityResult(
          entity,
          "SUCCESS",
          combined,
          combined.length - existing.length,
        ),
      );
    } catch (error) {
      return failure(errorMessage(error));
    }
  }

  return success(results);
};
