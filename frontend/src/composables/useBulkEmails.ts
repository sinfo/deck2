import { useGmailDrafts, type DraftEmailOptions } from "./useGmailDrafts";
import { useGoogleAuth } from "./useGoogleAuth";
import { useAuthStore } from "@/stores/auth";
import { useEventStore } from "@/stores/event";
import { getCompanyRepresentatives } from "@/api/companies";
import type { CompanyWithParticipation } from "@/dto/companies";
import type {
  Speaker,
  SpeakerWithContactAndParticipation,
} from "@/dto/speakers";
import type { ParticipationStatus } from "@/dto/index";
import {
  EmailTemplateCategory,
  getVariablesFromType,
  loadSignature,
  loadTemplateAndReplace,
  templateCategoryTemplates,
  type CompanyVariablesInput,
  type SpeakerVariablesInput,
  type VariablesInput,
} from "@/lib/templates";
import { ref, computed } from "vue";
import { getSpeakerById } from "@/api/speakers";
import { isEmailValid } from "@/lib/utils";
import { Gender, Language } from "@/dto/contacts";

// Generic types for bulk emails
export type BulkEmailEntity =
  | CompanyWithParticipation
  | SpeakerWithContactAndParticipation;
function isSpeaker(
  entity: BulkEmailEntity,
): entity is SpeakerWithContactAndParticipation {
  return (entity as Speaker).companyName !== undefined;
}

interface EntityInfo {
  id: string;
  name: string;
  email: EmailWithDetails;
  additional: string;
}

export interface BulkEmailResult {
  success: {
    entityInfo: EntityInfo;
  }[];
  failed: number;
  errors: string[];
  failedDetails: EntityInfo[];
}

interface EmailWithDetails {
  address: string | null;
  language: Language | null;
  gender: Gender | null;
}

type ProcessedEmailStatus = "ready" | "incomplete" | "error";
interface ProcessedEmail<T extends BulkEmailEntity> {
  entity: T;
  email: EmailWithDetails | null;
  error: string | null;
  status: ProcessedEmailStatus;
  subject: string | null;
  body: string | null;
}

const processEmail = <T extends BulkEmailEntity>(
  email: EmailWithDetails | null,
  entity: T,
): ProcessedEmail<T> => {
  if (!email) {
    return {
      entity,
      email,
      error: "No contact found",
      status: "error",
      subject: null,
      body: null,
    };
  }

  const status: ProcessedEmailStatus[] = [];
  const errors: string[] = [];

  // Email address
  if (!email?.address) {
    status.push("error");
    errors.push("no address");
  } else if (!isEmailValid(email.address)) {
    status.push("incomplete");
    errors.push(`address invalid (${email.address})`);
  }

  // Language
  if (!email?.language) {
    status.push("error");
    errors.push("no language");
  } else if (!Object.values(Language).includes(email.language)) {
    status.push("incomplete");
    errors.push(`language invalid (${email.language})`);
  }

  if (!email.gender) {
    status.push("incomplete");
    errors.push("no gender");
  } else if (!Object.values(Gender).includes(email.gender)) {
    status.push("error");
    errors.push(`gender invalid (${email.gender})`);
  }

  if (errors.length > 0) {
    const finalStatus = status.some((s) => s === "error")
      ? "error"
      : "incomplete";
    return {
      entity,
      email,
      error: `Errors: ${errors.join(", ")}`,
      status: finalStatus,
      subject: null,
      body: null,
    };
  }

  return {
    entity,
    email,
    error: null,
    status: "ready",
    subject: null,
    body: null,
  };
};

interface BulkEmailProcessResult<T extends BulkEmailEntity> {
  ready: ProcessedEmail<T>[];
  incomplete: ProcessedEmail<T>[];
  errors: ProcessedEmail<T>[];
}

// Email fetcher interface
interface EmailFetcher<T extends BulkEmailEntity> {
  getEmail: (entity: T) => Promise<EmailWithDetails | null>;
  getEntityName: (entity: T) => string;
}

// Company email fetcher
const companyEmailFetcher: EmailFetcher<CompanyWithParticipation> = {
  getEmail: async (
    company: CompanyWithParticipation,
  ): Promise<EmailWithDetails | null> => {
    try {
      const response = await getCompanyRepresentatives(company.id);
      const representatives = response.data;

      if (representatives.length === 0) {
        return null;
      }

      const firstRep = representatives[0];
      if (!firstRep.contact?.mails || firstRep.contact.mails.length === 0) {
        return null;
      }

      return {
        address: firstRep.contact.mails[0].mail,
        gender: firstRep.contact.gender || null,
        language: firstRep.contact.language || null,
      };
    } catch (error) {
      throw new Error(
        `Failed to fetch company representatives: ${error instanceof Error ? error.message : "Unknown error"}`,
      );
    }
  },
  getEntityName: (company: CompanyWithParticipation): string => company.name,
};

// Speaker email fetcher
const speakerEmailFetcher: EmailFetcher<SpeakerWithContactAndParticipation> = {
  getEmail: async (
    speaker: SpeakerWithContactAndParticipation,
  ): Promise<EmailWithDetails | null> => {
    try {
      const response = await getSpeakerById(speaker.id);
      const speakerData = response.data;

      if (
        !speakerData.contactObject?.mails ||
        speakerData.contactObject.mails.length === 0
      ) {
        return null;
      }
      return {
        address: speakerData.contactObject.mails[0].mail,
        gender: speakerData.contactObject.gender || null,
        language: speakerData.contactObject.language || null,
      };
    } catch (error) {
      throw new Error(
        `Failed to fetch speaker email: ${error instanceof Error ? error.message : "Unknown error"}`,
      );
    }
  },
  getEntityName: (speaker: SpeakerWithContactAndParticipation): string =>
    speaker.name,
};

export const useBulkEmails = <T extends BulkEmailEntity>(
  emailFetcher: EmailFetcher<T>,
) => {
  const { createBulkDraftEmails, isLoading, error } = useGmailDrafts();
  const { signInWithGoogle, isSigningIn } = useGoogleAuth();
  const authStore = useAuthStore();
  const eventStore = useEventStore();

  const isProcessing = ref(false);
  const result = ref<BulkEmailResult | null>(null);
  const processResult = ref<BulkEmailProcessResult<T> | null>(null);
  const processedCount = ref(0);
  const totalToProcess = ref(0);
  const isSending = ref(false);
  const sentCount = ref(0);
  const totalToSend = ref(0);

  const isGoogleConnected = computed(() => !!authStore.googleAccessToken);

  // Generic function to process and verify bulk emails before sending
  const processBulkEmails = async (
    templateCategory: EmailTemplateCategory,
    statuses: ParticipationStatus[],
    entities: T[],
  ): Promise<BulkEmailProcessResult<T>> => {
    isProcessing.value = true;
    processedCount.value = 0;

    try {
      // Filter entities by selected statuses
      const filteredEntities = entities.filter(
        (entity) =>
          entity.participation &&
          statuses.includes(entity.participation.status),
      );

      if (filteredEntities.length === 0) {
        throw new Error("No entities match the selected status criteria.");
      }

      totalToProcess.value = filteredEntities.length;

      // Process each entity to get email status
      const processedEmails: ProcessedEmail<T>[] = [];

      for (let i = 0; i < filteredEntities.length; i++) {
        const entity = filteredEntities[i];
        let valid: ProcessedEmail<T> | null = null;
        let email: EmailWithDetails | null = null;

        try {
          email = await emailFetcher.getEmail(entity);
          valid = processEmail(email, entity);
        } catch (error) {
          valid = {
            entity,
            email: null,
            error: error instanceof Error ? error.message : "Unknown error",
            status: "error",
            body: null,
            subject: null,
          };
        }

        if (valid.status === "ready") {
          try {
            const { subject, body } = await loadTemplate(
              templateCategory,
              entity,
              email!,
            );
            valid.subject = subject;
            valid.body = body;
          } catch (error) {
            valid = {
              entity,
              email,
              error: error instanceof Error ? error.message : "Unknown error",
              status: "error",
              body: null,
              subject: null,
            };
          }
        }

        // Update progress
        processedEmails.push(valid);
        processedCount.value = i + 1;

        // Add delay to avoid overwhelming the API
        await new Promise((resolve) => setTimeout(resolve, 100));
      }

      // Separate results by status
      const ready = processedEmails.filter((item) => item.status === "ready");
      const incomplete = processedEmails.filter(
        (item) => item.status === "incomplete",
      );
      const errors = processedEmails.filter((item) => item.status === "error");

      const result: BulkEmailProcessResult<T> = {
        ready,
        incomplete,
        errors,
      };

      processResult.value = result;
      return result;
    } finally {
      isProcessing.value = false;
    }
  };

  // Function to actually send the drafts after verification
  const sendProcessedEmails = async (): Promise<BulkEmailResult> => {
    if (!processResult.value) {
      throw new Error(
        "No processed emails available. Please process emails first.",
      );
    }

    isSending.value = true;
    sentCount.value = 0;

    try {
      const { ready } = processResult.value;

      if (ready.length === 0) {
        throw new Error("No emails are ready to be sent.");
      }

      totalToSend.value = ready.length;

      const signature = await loadSignature(
        authStore.member!,
        authStore.decoded,
      );

      // Create draft emails for ready entities
      const draftEmails = ready.map((item) => {
        return {
          to: [item.email!.address],
          subject: item.subject,
          body: `${item.body}<br/>${signature}`,
          entityInfo: {
            id: item.entity.id,
            name: emailFetcher.getEntityName(item.entity as T),
            email: item.email,
          } as EntityInfo,
        } as DraftEmailOptions;
      });

      if (!isGoogleConnected.value) {
        // Attempt to sign in with Google
        const signInSuccess = await signInWithGoogle();
        if (!signInSuccess) {
          throw new Error(
            "Google authentication is required to send emails. Please try again.",
          );
        }
      }

      // Create bulk draft emails with progress tracking
      const bulkResult = await createBulkDraftEmails(
        draftEmails,
        (completed) => {
          sentCount.value = completed;
        },
      );

      const finalResult: BulkEmailResult = {
        success: bulkResult.success as { entityInfo: EntityInfo }[],
        failed: bulkResult.failed.length,
        errors: bulkResult.failed.map((f) => f.error),
        failedDetails: bulkResult.failed.map((f) => ({
          ...(f.email.entityInfo as EntityInfo),
          additional: f.error,
        })),
      };

      result.value = finalResult;
      return finalResult;
    } finally {
      isSending.value = false;
    }
  };

  const loadTemplate = async (
    templateCategory: EmailTemplateCategory,
    entity: BulkEmailEntity,
    email: EmailWithDetails,
  ): Promise<{ subject: string; body: string }> => {
    const template =
      templateCategoryTemplates[templateCategory][
        email.language || Language.ENGLISH
      ];
    const varsInput: VariablesInput = {
      event: eventStore.selectedEvent!,
      member: authStore.member!,
    };

    const variables = isSpeaker(entity)
      ? getVariablesFromType<SpeakerVariablesInput>({
          ...varsInput,
          speaker: entity,
        })
      : getVariablesFromType<CompanyVariablesInput>({
          ...varsInput,
          company: entity,
        });

    return await loadTemplateAndReplace(template, variables);
  };

  return {
    isProcessing: computed(
      () => isProcessing.value || isLoading.value || isSigningIn.value,
    ),
    isSending: computed(() => isSending.value),
    isGoogleConnected,
    result: computed(() => result.value),
    processResult: computed(() => processResult.value),
    error: computed(() => error.value),
    processedCount: computed(() => processedCount.value),
    totalToProcess: computed(() => totalToProcess.value),
    sentCount: computed(() => sentCount.value),
    totalToSend: computed(() => totalToSend.value),
    processBulkEmails,
    sendProcessedEmails,
  };
};

// Convenience functions for specific entity types
export const useBulkCompanyEmails = () => useBulkEmails(companyEmailFetcher);
export const useBulkSpeakerEmails = () => useBulkEmails(speakerEmailFetcher);
