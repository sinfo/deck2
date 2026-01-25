import { useAuthStore } from "@/stores/auth";
import { ref } from "vue";

export interface GmailMessageHeader {
  name: string;
  value: string;
}

export interface GmailMessagePart {
  partId: string;
  mimeType: string;
  filename: string;
  headers: GmailMessageHeader[];
  body: {
    attachmentId?: string;
    size: number;
    data?: string;
  };
  parts?: GmailMessagePart[];
}

export interface GmailMessage {
  id: string;
  threadId: string;
  labelIds: string[];
  snippet: string;
  historyId: string;
  internalDate: string;
  payload: {
    partId: string;
    mimeType: string;
    filename: string;
    headers: GmailMessageHeader[];
    body: {
      size: number;
      data?: string;
    };
    parts?: GmailMessagePart[];
  };
  sizeEstimate: number;
  raw?: string;
}

export interface GmailMessageListItem {
  id: string;
  threadId: string;
}

export interface GmailMessagesListResponse {
  messages: GmailMessageListItem[];
  nextPageToken?: string;
  resultSizeEstimate: number;
}

export interface GetMessagesOptions {
  maxResults?: number;
  pageToken?: string;
  q?: string;
  labelIds?: string[];
  includeSpamTrash?: boolean;
}

export interface GetMessageOptions {
  format?: "minimal" | "full" | "raw" | "metadata";
  metadataHeaders?: string[];
}

export interface GmailThreadListItem {
  id: string;
  snippet: string;
  historyId: string;
}

export interface GmailThreadsListResponse {
  threads: GmailThreadListItem[];
  nextPageToken?: string;
  resultSizeEstimate: number;
}

export interface GmailThread {
  id: string;
  historyId: string;
  messages: GmailMessage[];
}

export const useGmailMessages = () => {
  const authStore = useAuthStore();
  const isLoading = ref(false);
  const error = ref<string | null>(null);
  const needsReauth = ref(false);

  /**
   * Check if Google token is valid before making requests
   */
  const checkAuth = (): boolean => {
    if (!authStore.isGoogleAuthenticated) {
      error.value = "Google authentication required";
      needsReauth.value = true;
      return false;
    }
    return true;
  };

  /**
   * Handle API response and check for auth errors
   */
  const handleAuthError = (response: Response): boolean => {
    if (response.status === 401) {
      // Token is invalid or expired
      authStore.clearGoogleToken();
      error.value = "Google session expired. Please re-authenticate.";
      needsReauth.value = true;
      return true;
    }
    return false;
  };

  /**
   * List messages in the user's mailbox
   */
  const listMessages = async (
    options: GetMessagesOptions = {},
  ): Promise<GmailMessagesListResponse | null> => {
    if (!checkAuth()) {
      return null;
    }

    isLoading.value = true;
    error.value = null;
    needsReauth.value = false;

    try {
      const params = new URLSearchParams();

      if (options.maxResults) {
        params.append("maxResults", options.maxResults.toString());
      }
      if (options.pageToken) {
        params.append("pageToken", options.pageToken);
      }
      if (options.q) {
        params.append("q", options.q);
      }
      if (options.labelIds && options.labelIds.length > 0) {
        options.labelIds.forEach((labelId) =>
          params.append("labelIds", labelId),
        );
      }
      if (options.includeSpamTrash !== undefined) {
        params.append("includeSpamTrash", options.includeSpamTrash.toString());
      }

      const queryString = params.toString();
      const url = `https://gmail.googleapis.com/gmail/v1/users/me/messages${queryString ? `?${queryString}` : ""}`;

      const response = await fetch(url, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${authStore.googleAccessToken}`,
        },
      });

      if (handleAuthError(response)) {
        return null;
      }

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(
          `Gmail API error: ${errorData.error?.message || response.statusText}`,
        );
      }

      const result: GmailMessagesListResponse = await response.json();
      return result;
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : "Failed to list messages";
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  /**
   * List threads in the user's mailbox
   */
  const listThreads = async (
    options: GetMessagesOptions = {},
  ): Promise<GmailThreadsListResponse | null> => {
    if (!checkAuth()) {
      return null;
    }

    isLoading.value = true;
    error.value = null;
    needsReauth.value = false;

    try {
      const params = new URLSearchParams();

      if (options.maxResults) {
        params.append("maxResults", options.maxResults.toString());
      }
      if (options.pageToken) {
        params.append("pageToken", options.pageToken);
      }
      if (options.q) {
        params.append("q", options.q);
      }
      if (options.labelIds && options.labelIds.length > 0) {
        options.labelIds.forEach((labelId) =>
          params.append("labelIds", labelId),
        );
      }
      if (options.includeSpamTrash !== undefined) {
        params.append("includeSpamTrash", options.includeSpamTrash.toString());
      }

      const queryString = params.toString();
      const url = `https://gmail.googleapis.com/gmail/v1/users/me/threads${queryString ? `?${queryString}` : ""}`;

      const response = await fetch(url, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${authStore.googleAccessToken}`,
        },
      });

      if (handleAuthError(response)) {
        return null;
      }

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(
          `Gmail API error: ${errorData.error?.message || response.statusText}`,
        );
      }

      const result: GmailThreadsListResponse = await response.json();
      return result;
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : "Failed to list threads";
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  /**
   * Get a thread with all its messages
   */
  const getThread = async (
    threadId: string,
    options: GetMessageOptions = {},
  ): Promise<GmailThread | null> => {
    if (!checkAuth()) {
      return null;
    }

    isLoading.value = true;
    error.value = null;
    needsReauth.value = false;

    try {
      const params = new URLSearchParams();
      if (options.format) {
        params.append("format", options.format);
      }
      if (options.metadataHeaders && options.metadataHeaders.length > 0) {
        options.metadataHeaders.forEach((header) =>
          params.append("metadataHeaders", header),
        );
      }
      const queryString = params.toString();

      const url = `https://gmail.googleapis.com/gmail/v1/users/me/threads/${threadId}${queryString ? `?${queryString}` : ""}`;

      const response = await fetch(url, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${authStore.googleAccessToken}`,
        },
      });

      if (handleAuthError(response)) {
        return null;
      }

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(
          `Gmail API error: ${errorData.error?.message || response.statusText}`,
        );
      }

      const result: GmailThread = await response.json();
      return result;
    } catch (err) {
      error.value = err instanceof Error ? err.message : "Failed to get thread";
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  /**
   * Get multiple threads by their IDs (in parallel)
   */
  const getThreads = async (
    threadIds: string[],
    options: GetMessageOptions = {},
  ): Promise<GmailThread[]> => {
    if (!checkAuth()) {
      return [];
    }

    isLoading.value = true;
    error.value = null;
    needsReauth.value = false;

    try {
      const params = new URLSearchParams();
      if (options.format) {
        params.append("format", options.format);
      }
      if (options.metadataHeaders && options.metadataHeaders.length > 0) {
        options.metadataHeaders.forEach((header) =>
          params.append("metadataHeaders", header),
        );
      }
      const queryString = params.toString();

      // Fetch all threads in parallel
      const promises = threadIds.map(async (threadId) => {
        const url = `https://gmail.googleapis.com/gmail/v1/users/me/threads/${threadId}${queryString ? `?${queryString}` : ""}`;
        const response = await fetch(url, {
          method: "GET",
          headers: {
            Authorization: `Bearer ${authStore.googleAccessToken}`,
          },
        });

        if (response.status === 401) {
          authStore.clearGoogleToken();
          needsReauth.value = true;
          return null;
        }

        if (!response.ok) {
          console.error(`Failed to fetch thread ${threadId}`);
          return null;
        }

        return response.json() as Promise<GmailThread>;
      });

      const results = await Promise.all(promises);

      if (needsReauth.value) {
        error.value = "Google session expired. Please re-authenticate.";
        return [];
      }

      return results.filter((thread): thread is GmailThread => thread !== null);
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : "Failed to get threads";
      return [];
    } finally {
      isLoading.value = false;
    }
  };

  /**
   * Get a specific message by ID
   */
  const getMessage = async (
    messageId: string,
    options: GetMessageOptions = {},
  ): Promise<GmailMessage | null> => {
    if (!checkAuth()) {
      return null;
    }

    isLoading.value = true;
    error.value = null;
    needsReauth.value = false;

    try {
      const params = new URLSearchParams();

      if (options.format) {
        params.append("format", options.format);
      }
      if (options.metadataHeaders && options.metadataHeaders.length > 0) {
        options.metadataHeaders.forEach((header) =>
          params.append("metadataHeaders", header),
        );
      }

      const queryString = params.toString();
      const url = `https://gmail.googleapis.com/gmail/v1/users/me/messages/${messageId}${queryString ? `?${queryString}` : ""}`;

      const response = await fetch(url, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${authStore.googleAccessToken}`,
        },
      });

      if (handleAuthError(response)) {
        return null;
      }

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(
          `Gmail API error: ${errorData.error?.message || response.statusText}`,
        );
      }

      const result: GmailMessage = await response.json();
      return result;
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : "Failed to get message";
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  /**
   * Get multiple messages by their IDs (in parallel for better performance)
   */
  const getMessages = async (
    messageIds: string[],
    options: GetMessageOptions = {},
  ): Promise<GmailMessage[]> => {
    if (!checkAuth()) {
      return [];
    }

    isLoading.value = true;
    error.value = null;
    needsReauth.value = false;

    try {
      const params = new URLSearchParams();
      if (options.format) {
        params.append("format", options.format);
      }
      if (options.metadataHeaders && options.metadataHeaders.length > 0) {
        options.metadataHeaders.forEach((header) =>
          params.append("metadataHeaders", header),
        );
      }
      const queryString = params.toString();

      // Fetch all messages in parallel
      const promises = messageIds.map(async (messageId) => {
        const url = `https://gmail.googleapis.com/gmail/v1/users/me/messages/${messageId}${queryString ? `?${queryString}` : ""}`;
        const response = await fetch(url, {
          method: "GET",
          headers: {
            Authorization: `Bearer ${authStore.googleAccessToken}`,
          },
        });

        if (response.status === 401) {
          // Token is invalid or expired
          authStore.clearGoogleToken();
          needsReauth.value = true;
          return null;
        }

        if (!response.ok) {
          console.error(`Failed to fetch message ${messageId}`);
          return null;
        }

        return response.json() as Promise<GmailMessage>;
      });

      const results = await Promise.all(promises);

      if (needsReauth.value) {
        error.value = "Google session expired. Please re-authenticate.";
        return [];
      }

      return results.filter((msg): msg is GmailMessage => msg !== null);
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : "Failed to get messages";
      return [];
    } finally {
      isLoading.value = false;
    }
  };

  /**
   * Helper function to extract a header value from a message
   */
  const getHeaderValue = (
    message: GmailMessage,
    headerName: string,
  ): string | undefined => {
    return message.payload.headers.find(
      (h) => h.name.toLowerCase() === headerName.toLowerCase(),
    )?.value;
  };

  /**
   * Helper function to decode base64url encoded content
   */
  const decodeBase64Url = (data: string): string => {
    // Replace base64url characters with base64 characters
    const base64 = data.replace(/-/g, "+").replace(/_/g, "/");
    // Decode base64 to binary string
    const binaryString = atob(base64);
    // Convert binary string to UTF-8
    const bytes = Uint8Array.from(binaryString, (char) => char.charCodeAt(0));
    return new TextDecoder("utf-8").decode(bytes);
  };

  /**
   * Helper function to get the message body content
   */
  const getMessageBody = (
    message: GmailMessage,
    preferHtml: boolean = true,
  ): string | null => {
    const findBody = (
      parts: GmailMessagePart[] | undefined,
      mimeType: string,
    ): string | null => {
      if (!parts) return null;

      for (const part of parts) {
        if (part.mimeType === mimeType && part.body.data) {
          return decodeBase64Url(part.body.data);
        }
        if (part.parts) {
          const found = findBody(part.parts, mimeType);
          if (found) return found;
        }
      }
      return null;
    };

    // Check if the message has a simple body
    if (message.payload.body.data) {
      return decodeBase64Url(message.payload.body.data);
    }

    // Search for the preferred content type
    if (preferHtml) {
      const htmlBody = findBody(message.payload.parts, "text/html");
      if (htmlBody) return htmlBody;
    }

    const textBody = findBody(message.payload.parts, "text/plain");
    if (textBody) return textBody;

    if (!preferHtml) {
      const htmlBody = findBody(message.payload.parts, "text/html");
      if (htmlBody) return htmlBody;
    }

    return null;
  };

  /**
   * Get all messages in a Gmail thread by thread ID
   */
  const getMessagesByThreadId = async (
    threadId: string,
    options: GetMessageOptions = {},
  ): Promise<GmailMessage[]> => {
    if (!checkAuth()) {
      return [];
    }

    isLoading.value = true;
    error.value = null;
    needsReauth.value = false;

    try {
      const params = new URLSearchParams();
      if (options.format) {
        params.append("format", options.format);
      }
      const queryString = params.toString();

      // Use the threads.get endpoint to get all messages in a thread
      const url = `https://gmail.googleapis.com/gmail/v1/users/me/threads/${threadId}${queryString ? `?${queryString}` : ""}`;

      const response = await fetch(url, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${authStore.googleAccessToken}`,
        },
      });

      if (handleAuthError(response)) {
        return [];
      }

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(
          `Gmail API error: ${errorData.error?.message || response.statusText}`,
        );
      }

      const result = await response.json();
      return result.messages || [];
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : "Failed to get thread messages";
      return [];
    } finally {
      isLoading.value = false;
    }
  };

  return {
    isLoading,
    error,
    needsReauth,
    listMessages,
    listThreads,
    getMessage,
    getMessages,
    getThread,
    getThreads,
    getMessagesByThreadId,
    getHeaderValue,
    decodeBase64Url,
    getMessageBody,
  };
};
