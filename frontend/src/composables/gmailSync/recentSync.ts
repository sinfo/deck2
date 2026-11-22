import type { EntityLinkResult, SyncResult } from "./common";
import type { GmailSyncClient } from "./client";
import { runFullGmailSync } from "./fullSync";

export const runRecentGmailSync = (
  eventId: number,
  threadIds: string[],
  client: GmailSyncClient,
): Promise<SyncResult<EntityLinkResult[]>> =>
  runFullGmailSync(eventId, client, () => {}, threadIds);
