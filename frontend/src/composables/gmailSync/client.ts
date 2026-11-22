import type { useAuthStore } from "@/stores/auth";
import type { GmailMessageData } from "@/api/companies";
import type { useGoogleAuth } from "../useGoogleAuth";
import {
  fetchGmail,
  gmailResponseError,
  type useGmailMessages,
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

interface GmailHistoryPage {
  historyId: string;
  nextPageToken?: string;
  history?: { messagesAdded?: { message: { threadId: string } }[] }[];
}

type GmailApiResult<T> =
  | { ok: true; value: T }
  | { ok: false; error: string; status?: number };

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

  // Process one Gmail page at a time, keeping only a small batch of thread
  // IDs and messages in memory instead of collecting the whole mailbox.
  const scanThreads = async (
    query: string,
    visitPage: (threadIds: string[]) => Promise<SyncResult<void>>,
  ): Promise<SyncResult<void>> => {
    const token = await ensureToken();
    if (!token.ok) return failure(token.error);

    try {
      let pageToken: string | undefined;
      do {
        let response = await gmail.listThreads({
          q: query,
          maxResults: 20,
          pageToken,
        });

        if (gmail.needsReauth.value) {
          const reauth = await retryAuth();
          if (!reauth.ok) return failure(reauth.error);
          response = await gmail.listThreads({
            q: query,
            maxResults: 20,
            pageToken,
          });
        }

        if (!response) {
          return failure(
            gmail.error.value ?? "Failed to retrieve Gmail threads",
          );
        }

        const processed = await visitPage(
          (response.threads ?? []).map((thread) => thread.id),
        );
        if (!processed.ok) return processed;
        pageToken = response.nextPageToken;
      } while (pageToken);

      return success(undefined);
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

  const gmailGet = async <T>(url: string): Promise<GmailApiResult<T>> => {
    const token = await ensureToken();
    if (!token.ok) return failure(token.error);

    try {
      const request = () =>
        fetchGmail(() =>
          fetch(url, {
            headers: { Authorization: `Bearer ${auth.googleAccessToken}` },
          }),
        );
      let response = await request();
      if (response.status === 401) {
        const reauth = await retryAuth();
        if (!reauth.ok) return failure(reauth.error);
        response = await request();
      }

      if (!response.ok) {
        return {
          ok: false,
          status: response.status,
          error: await gmailResponseError(response),
        };
      }

      return success((await response.json()) as T);
    } catch (error) {
      return failure(errorMessage(error));
    }
  };

  const getHistoryId = async (): Promise<SyncResult<string>> => {
    const response = await gmailGet<{ historyId: string }>(
      "https://gmail.googleapis.com/gmail/v1/users/me/profile",
    );
    if (!response.ok) return failure(response.error);
    return response.value.historyId
      ? success(response.value.historyId)
      : failure("Gmail profile has no history ID");
  };

  // Changes contain message/thread IDs; complete bodies are downloaded only
  // for conversations that have new messages.
  const getChangedThreadIds = async (
    startHistoryId: string,
  ): Promise<SyncResult<{ historyId: string; threadIds: string[] } | null>> => {
    const ids = new Set<string>();
    let pageToken: string | undefined;

    while (true) {
      const params = new URLSearchParams({
        startHistoryId,
        historyTypes: "messageAdded",
        maxResults: "500",
      });
      if (pageToken) params.set("pageToken", pageToken);

      const response = await gmailGet<GmailHistoryPage>(
        `https://gmail.googleapis.com/gmail/v1/users/me/history?${params}`,
      );
      if (!response.ok) {
        if (response.status === 404) return success(null);
        return failure(response.error);
      }

      for (const change of response.value.history ?? []) {
        for (const added of change.messagesAdded ?? []) {
          ids.add(added.message.threadId);
        }
      }

      if (!response.value.nextPageToken) {
        return response.value.historyId
          ? success({
              historyId: response.value.historyId,
              threadIds: [...ids],
            })
          : failure("Gmail history response has no history ID");
      }
      pageToken = response.value.nextPageToken;
    }
  };

  return {
    ensureToken,
    scanThreads,
    fetchMessages,
    getHistoryId,
    getChangedThreadIds,
  };
};

export type GmailSyncClient = ReturnType<typeof createGmailSyncClient>;
