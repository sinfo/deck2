import type { useAuthStore } from "@/stores/auth";
import type { GmailMessageData } from "@/api/companies";
import type { useGoogleAuth } from "../useGoogleAuth";
import type {
  GmailThreadListItem,
  useGmailMessages,
} from "../useGmailMessages";
import {
  errorMessage,
  failure,
  prepareGmailMessage,
  success,
  type SyncResult,
} from "./common";

type AuthStore = ReturnType<typeof useAuthStore>;
type GmailMessages = ReturnType<typeof useGmailMessages>;
type RequestToken = ReturnType<typeof useGoogleAuth>["requestGoogleToken"];

// Converts Gmail's nullable API responses into explicit success/failure values.
export const createGmailSyncClient = (
  auth: AuthStore,
  gmail: GmailMessages,
  requestToken: RequestToken,
) => {
  const ensureToken = async (): Promise<SyncResult<void>> => {
    if (!auth.isGoogleAuthenticated) {
      return failure("Google authentication required");
    }
    if (auth.hasValidGoogleToken) return success(undefined);

    try {
      const authenticated = await requestToken({ silent: true });
      return authenticated
        ? success(undefined)
        : failure("Google authentication failed");
    } catch (error) {
      return failure(errorMessage(error));
    }
  };

  const retryAuth = async (): Promise<SyncResult<void>> => {
    try {
      const authenticated = await requestToken();
      return authenticated
        ? success(undefined)
        : failure("Google authentication failed");
    } catch (error) {
      return failure(errorMessage(error));
    }
  };

  const listThreads = async (
    query: string,
  ): Promise<SyncResult<GmailThreadListItem[]>> => {
    const token = await ensureToken();
    if (!token.ok) return failure(token.error);

    try {
      const threads: GmailThreadListItem[] = [];
      let pageToken: string | undefined;

      do {
        let response = await gmail.listThreads({
          q: query,
          maxResults: 50,
          pageToken,
        });

        if (gmail.needsReauth.value) {
          const reauth = await retryAuth();
          if (!reauth.ok) return failure(reauth.error);
          response = await gmail.listThreads({
            q: query,
            maxResults: 50,
            pageToken,
          });
        }

        if (!response) {
          return failure(
            gmail.error.value ?? "Failed to retrieve Gmail threads",
          );
        }

        threads.push(...(response.threads ?? []));
        pageToken = response.nextPageToken;
      } while (pageToken);

      return success(threads);
    } catch (error) {
      return failure(errorMessage(error));
    }
  };

  const fetchMessages = async (
    threadIds: string[],
  ): Promise<SyncResult<GmailMessageData[]>> => {
    if (threadIds.length === 0) return success([]);
    const token = await ensureToken();
    if (!token.ok) return failure(token.error);

    try {
      const messages: GmailMessageData[] = [];

      for (const threadId of threadIds) {
        let threadMessages = await gmail.getMessagesByThreadId(threadId, {
          format: "full",
        });

        if (gmail.needsReauth.value) {
          const reauth = await retryAuth();
          if (!reauth.ok) return failure(reauth.error);
          threadMessages = await gmail.getMessagesByThreadId(threadId, {
            format: "full",
          });
        }

        if (gmail.error.value) return failure(gmail.error.value);

        for (const message of threadMessages) {
          messages.push(
            prepareGmailMessage(
              message,
              auth.sinfoEmail ?? "",
              gmail.getHeaderValue,
              gmail.getMessageBody,
            ),
          );
        }
      }

      return success(messages);
    } catch (error) {
      return failure(errorMessage(error));
    }
  };

  return { ensureToken, listThreads, fetchMessages };
};

export type GmailSyncClient = ReturnType<typeof createGmailSyncClient>;
