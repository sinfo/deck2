import { useGmailDrafts, type DraftEmailOptions } from "./useGmailDrafts";
import { useGoogleAuth } from "./useGoogleAuth";
import { useAuthStore } from "@/stores/auth";
import { useEventStore } from "@/stores/event";
import { getCompanyRepresentatives } from "@/api/companies";
import type { CompanyWithParticipation } from "@/dto/companies";
import type { Speaker, SpeakerWithParticipation } from "@/dto/speakers";
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
import { Gender, Language } from "@/dto/contacts";
import type { Contact } from "@/dto/contacts";

export type DirectEmailEntity =
  | CompanyWithParticipation
  | SpeakerWithParticipation;

function isSpeaker(
  entity: DirectEmailEntity,
): entity is SpeakerWithParticipation {
  return (entity as Speaker).companyName !== undefined;
}

export interface EmailWithDetails {
  address: string;
  language: Language;
  gender: Gender;
  name: string;
  contact: Contact;
}

export interface SendEmailResult {
  success: boolean;
  error?: string;
}

export const useDirectEmail = (entity: DirectEmailEntity) => {
  const { createDraftEmail, isLoading } = useGmailDrafts();
  const { signInWithGoogle, isSigningIn } = useGoogleAuth();
  const authStore = useAuthStore();
  const eventStore = useEventStore();

  const isFetchingEmails = ref(false);
  const availableEmails = ref<EmailWithDetails[]>([]);
  const isSending = ref(false);
  const result = ref<SendEmailResult | null>(null);

  const isGoogleConnected = computed(() => !!authStore.googleAccessToken);

  const fetchAvailableEmails = async () => {
    isFetchingEmails.value = true;
    availableEmails.value = [];
    try {
      if (isSpeaker(entity)) {
        const response = await getSpeakerById(entity.id);
        const speakerData = response.data;
        if (speakerData.contactObject?.mails) {
          availableEmails.value = speakerData.contactObject.mails.map(
            (mail) => ({
              address: mail.mail,
              language: speakerData.contactObject.language || Language.ENGLISH,
              gender: speakerData.contactObject.gender || Gender.MALE,
              name: speakerData.name,
              contact: speakerData.contactObject,
            }),
          );
        }
      } else {
        const response = await getCompanyRepresentatives(entity.id);
        const representatives = response.data;
        availableEmails.value = representatives
          .filter((rep) => rep.contact?.mails && rep.contact.mails.length > 0)
          .map((rep) => ({
            address: rep.contact!.mails[0].mail,
            language: rep.contact!.language || Language.ENGLISH,
            gender: rep.contact!.gender || Gender.MALE,
            name: rep.name,
            contact: rep.contact!,
          }));
      }
    } catch (e) {
      console.error("Failed to fetch emails:", e);
    } finally {
      isFetchingEmails.value = false;
    }
  };

  const sendEmail = async (
    templateCategory: EmailTemplateCategory,
    selectedEmails: EmailWithDetails[],
  ): Promise<SendEmailResult> => {
    if (selectedEmails.length === 0) {
      throw new Error("No email selected.");
    }

    isSending.value = true;

    try {
      if (!isGoogleConnected.value) {
        const signInSuccess = await signInWithGoogle();
        if (!signInSuccess) {
          throw new Error("Google authentication is required.");
        }
      }

      const signature = await loadSignature(
        authStore.member!,
        authStore.decoded,
      );

      const { subject, body } = await loadTemplate(
        templateCategory,
        entity,
        selectedEmails[0], // Assuming template variables are based on the first selected contact
      );

      const draftOptions: DraftEmailOptions = {
        to: selectedEmails.map((e) => e.address),
        subject,
        body: `${body}<br/>${signature}`,
      };

      await createDraftEmail(draftOptions);

      const sendResult = { success: true };
      result.value = sendResult;
      return sendResult;
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : "Unknown error";
      result.value = { success: false, error: errorMsg };
      return result.value;
    } finally {
      isSending.value = false;
    }
  };

  const loadTemplate = async (
    templateCategory: EmailTemplateCategory,
    entity: DirectEmailEntity,
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
    isFetchingEmails,
    availableEmails,
    isSending: computed(
      () => isSending.value || isLoading.value || isSigningIn.value,
    ),
    result,
    fetchAvailableEmails,
    sendEmail,
  };
};
