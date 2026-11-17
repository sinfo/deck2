import type { EntityLinkResult, SyncResult } from "./common";
import type { GmailSyncClient } from "./client";
import { runFullGmailSync } from "./fullSync";

// Incremental sync uses the same assigned-entity, edition-scoped search as a
// full scan. The timestamp only narrows the date range further.
export const runRecentGmailSync = (
  eventId: number,
  lastSyncTime: number,
  client: GmailSyncClient,
): Promise<SyncResult<EntityLinkResult[]>> =>
  runFullGmailSync(
    eventId,
    client,
    () => {},
    Math.max(0, Math.floor(lastSyncTime / 1000) - 180),
  );
