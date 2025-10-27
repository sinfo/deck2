<template>
  <div class="relative">
    <Tabs v-model="activeTab" default-value="companies" class="w-full">
      <div class="relative">
        <!-- Desktop layout: heading on left, tabs centered, button on right -->
        <div class="hidden lg:flex relative items-center justify-center">
          <h1 class="text-2xl font-bold absolute left-0">
            My Responsibilities
          </h1>
          <TabsList class="grid w-full grid-cols-2 max-w-md">
            <TabsTrigger value="companies"> Companies </TabsTrigger>
            <TabsTrigger value="speakers"> Speakers </TabsTrigger>
          </TabsList>

          <!-- Create Company Button and Bulk Email Button - positioned absolutely to not affect tab layout on desktop -->
          <div
            v-if="activeTab === 'companies'"
            class="absolute right-0 top-0 h-full flex items-center gap-2"
          >
            <BulkEmailDialogTrigger
              entity-type="companies"
              :companies="currentCompaniesParticipation || []"
              @success="onBulkCompanyEmailSuccess"
            />
            <CreateCompanyDialogTrigger @success="onCompanyCreated" />
          </div>
          <div
            v-else-if="activeTab === 'speakers'"
            class="absolute right-0 top-0 h-full flex items-center gap-2"
          >
            <BulkEmailDialogTrigger
              entity-type="speakers"
              :speakers="currentSpeakersParticipation || []"
              @success="onBulkSpeakerEmailSuccess"
            />
            <CreateSpeakerDialogTrigger />
          </div>
        </div>

        <!-- Mobile layout: heading and button on same level, tabs below -->
        <div class="lg:hidden">
          <!-- Heading and Create Button on same level -->
          <div class="flex items-center justify-between mb-4">
            <h1 class="text-2xl font-bold">My Responsibilities</h1>
            <div
              v-if="activeTab === 'companies'"
              class="flex flex-col sm:flex-row items-end gap-2"
            >
              <BulkEmailDialogTrigger
                entity-type="companies"
                :companies="currentCompaniesParticipation || []"
                @success="onBulkCompanyEmailSuccess"
              />
              <CreateCompanyDialogTrigger @success="onCompanyCreated" />
            </div>
            <div
              v-else-if="activeTab === 'speakers'"
              class="flex flex-col sm:flex-row items-end gap-2"
            >
              <BulkEmailDialogTrigger
                entity-type="speakers"
                :speakers="currentSpeakersParticipation || []"
                @success="onBulkSpeakerEmailSuccess"
              />
              <CreateSpeakerDialogTrigger />
            </div>
          </div>

          <!-- Tabs centered below -->
          <div class="flex justify-center">
            <TabsList class="grid w-full grid-cols-2 w-4/5 sm:w-3/4">
              <TabsTrigger value="companies"> Companies </TabsTrigger>
              <TabsTrigger value="speakers"> Speakers </TabsTrigger>
            </TabsList>
          </div>
        </div>
      </div>

      <TabsContent value="companies">
        <div
          v-if="!currentCompaniesParticipation?.length && isLoading"
          class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
        >
          <Skeleton
            v-for="i in 21"
            :key="i"
            class="h-[260px] w-full rounded-lg"
          />
        </div>

        <div
          v-else-if="!currentCompaniesParticipation?.length"
          class="text-center text-gray-500"
        >
          No companies assigned to you.
        </div>

        <div
          v-else
          class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
        >
          <CompanyWorkflowCard
            v-for="company in currentCompaniesParticipation || []"
            :key="company.id"
            :company="company"
          />
        </div>
      </TabsContent>

      <TabsContent value="speakers">
        <div
          v-if="!currentSpeakersParticipation?.length && isLoading"
          class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
        >
          <Skeleton
            v-for="i in 21"
            :key="i"
            class="h-[260px] w-full rounded-lg"
          />
        </div>

        <div
          v-else-if="!currentSpeakersParticipation?.length"
          class="text-center text-gray-500"
        >
          No speakers assigned to you.
        </div>

        <div
          class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-4 my-4"
        >
          <SpeakerWorkflowCard
            v-for="speaker in currentSpeakersParticipation || []"
            :key="speaker.id"
            :speaker="speaker"
          />
        </div>
      </TabsContent>
    </Tabs>
  </div>
</template>

<script setup lang="ts">
import { getMyResponsibilities } from "@/api/me";
import CompanyWorkflowCard from "@/components/cards/CompanyWorkflowCard.vue";
import SpeakerWorkflowCard from "@/components/cards/SpeakerWorkflowCard.vue";
import CreateCompanyDialogTrigger from "@/components/companies/CreateCompanyDialogTrigger.vue";
import CreateSpeakerDialogTrigger from "@/components/speakers/CreateSpeakerDialogTrigger.vue";
import BulkEmailDialogTrigger from "@/components/BulkEmailDialogTrigger.vue";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import type { CompanyWithParticipation } from "@/dto/companies";
import type { SpeakerWithParticipation } from "@/dto/speakers";
import { useSortByParticipationStatus } from "@/lib/utils";
import { useAuthStore } from "@/stores/auth";
import { useEventStore } from "@/stores/event";
import { useQuery } from "@pinia/colada";
import { computed, ref } from "vue";
import type { BulkEmailResult } from "@/composables/useBulkEmails";
import { usePostSpeakerThreadMutation } from "@/mutations/speakers";
import { usePostCompanyThreadMutation } from "@/mutations/companies";
import { ThreadKind } from "@/dto/threads";
import {
  templateCategoryHumanReadable,
  type EmailTemplateCategory,
} from "@/lib/templates";

const eventStore = useEventStore();
const authStore = useAuthStore();

// Tab state
const activeTab = ref("companies");

// Event handlers
const onCompanyCreated = () => {
  // The dialog component will handle navigation to the company page
};

const postCompanyThreadMutation = usePostCompanyThreadMutation();
const onBulkCompanyEmailSuccess = (
  template: EmailTemplateCategory,
  result: BulkEmailResult,
) => {
  // For each success, create the template thread
  for (const company of result.success) {
    postCompanyThreadMutation.companyId.value = company.entityInfo.id;
    postCompanyThreadMutation.threadData.value = {
      kind: ThreadKind.ThreadKindTemplate,
      text: `Bulk draft of "${templateCategoryHumanReadable[template]}" template`,
    };
    postCompanyThreadMutation.mutate();
  }
};

const postSpeakerThreadMutation = usePostSpeakerThreadMutation();
const onBulkSpeakerEmailSuccess = (
  template: EmailTemplateCategory,
  result: BulkEmailResult,
) => {
  // For each success, create the template thread
  for (const speaker of result.success) {
    postSpeakerThreadMutation.speakerId.value = speaker.entityInfo.id;
    postSpeakerThreadMutation.threadData.value = {
      kind: ThreadKind.ThreadKindTemplate,
      text: `Bulk draft of "${templateCategoryHumanReadable[template]}" template`,
    };
    postSpeakerThreadMutation.mutate();
  }
};

const { data: responsibilities, isLoading } = useQuery({
  key: ["responsibilities"],
  query: () => getMyResponsibilities({ event: eventStore.selectedEvent?.id }),
});

const currentCompaniesParticipation = computed(() =>
  responsibilities.value?.data.companies
    .map(
      (company) =>
        ({
          ...company,
          participation: company.participations.find(
            (participation) =>
              participation.event === eventStore.selectedEvent?.id,
          ),
        }) as CompanyWithParticipation,
    )
    .filter(
      (company) =>
        company.participation &&
        company.participation.member === authStore.decoded?.id,
    )
    .sort((a, b) =>
      useSortByParticipationStatus(a.participation, b.participation),
    ),
);

const currentSpeakersParticipation = computed(() =>
  responsibilities.value?.data.speakers
    .map(
      (speaker) =>
        ({
          ...speaker,
          participation: speaker.participations.find(
            (participation) =>
              participation.event === eventStore.selectedEvent?.id,
          ),
        }) as SpeakerWithParticipation,
    )
    .filter(
      (speaker) =>
        speaker.participation &&
        speaker.participation.member === authStore.decoded?.id,
    )
    .sort((a, b) =>
      useSortByParticipationStatus(a.participation, b.participation),
    ),
);
</script>
