import { toBase64 } from "@/lib/utils";
import { useAuthStore } from "@/stores/auth";
import { ref } from "vue";

export interface DraftEmailOptions {
  to: string[];
  cc?: string[];
  bcc?: string[];
  subject: string;
  body: string;
  entityInfo?: unknown;
}

interface GmailDraftResponse {
  id: string;
  message: {
    id: string;
    threadId: string;
  };
}

function encodeSubject(subject: string) {
  const bytes = new TextEncoder().encode(subject);
  let binary = "";
  bytes.forEach((b) => (binary += String.fromCharCode(b)));
  const base64 = btoa(binary);
  return `=?UTF-8?B?${base64}?=`;
}

export const useGmailDrafts = () => {
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

  const createDraftEmail = async (
    options: DraftEmailOptions,
  ): Promise<GmailDraftResponse | null> => {
    if (!checkAuth()) {
      return null;
    }

    isLoading.value = true;
    error.value = null;
    needsReauth.value = false;

    try {
      // Create the email message in RFC 2822 format
      const emailLines = [
        `To: ${options.to.join(", ")}`,
        ...(options.cc && options.cc.length > 0
          ? [`Cc: ${options.cc.join(", ")}`]
          : []),
        ...(options.bcc && options.bcc.length > 0
          ? [`Bcc: ${options.bcc.join(", ")}`]
          : []),
        `Subject: ${encodeSubject(options.subject)}`,
        "Content-Type: text/html; charset=utf-8",
        "",
        options.body,
      ];

      const emailMessage = emailLines.join("\r\n");

      // Encode the message in base64url format
      const draftData = {
        message: {
          raw: toBase64(emailMessage),
        },
      };

      const response = await fetch(
        "https://gmail.googleapis.com/gmail/v1/users/me/drafts",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${authStore.googleAccessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(draftData),
        },
      );

      if (handleAuthError(response)) {
        return null;
      }

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(
          `Gmail API error: ${errorData.error?.message || response.statusText}`,
        );
      }

      const result: GmailDraftResponse = await response.json();
      return result;
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : "Failed to create draft email";
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  interface CreateBulkDraftEmailsResponse {
    success: {
      entityInfo: unknown;
      response: GmailDraftResponse;
    }[];
    failed: {
      email: DraftEmailOptions;
      error: string;
    }[];
  }

  const createBulkDraftEmails = async (
    emails: DraftEmailOptions[],
    onProgress?: (completed: number, total: number) => void,
  ): Promise<CreateBulkDraftEmailsResponse> => {
    const res: CreateBulkDraftEmailsResponse = {
      success: [],
      failed: [],
    };

    for (let i = 0; i < emails.length; i++) {
      const email = emails[i];
      const result = await createDraftEmail(email);

      if (result) {
        res.success.push({
          entityInfo: email.entityInfo,
          response: result,
        });
      } else {
        res.failed.push({
          email,
          error: error.value || "Unknown error",
        });

        // If re-auth is needed, stop processing and return early
        if (needsReauth.value) {
          break;
        }
      }

      // Call progress callback if provided
      if (onProgress) {
        onProgress(i + 1, emails.length);
      }

      // Add a small delay between requests to avoid rate limiting
      await new Promise((resolve) => setTimeout(resolve, 100));
    }

    return res;
  };

  return {
    isLoading,
    error,
    needsReauth,
    createDraftEmail,
    createBulkDraftEmails,
  };
};
