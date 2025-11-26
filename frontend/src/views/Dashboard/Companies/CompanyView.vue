<template>
  <div v-if="companyWithParticipation" class="flex flex-col lg:flex-row gap-6">
    <!-- Company information section -->
    <div class="space-y-6 w-full lg:w-96 lg:flex-shrink-0">
      <!-- Company Card -->
      <CompanyCard
        :company="companyWithParticipation"
        @updated="handleCompanyUpdated"
      />

      <DirectEmailDialogTrigger
        v-if="companyWithParticipation"
        :entity="companyWithParticipation"
        entity-type="company"
        button-class="w-full"
      />

      <!-- Company Billing Information -->
      <CompanyBillingInfo
        :company="company?.data"
        @updated="handleCompanyUpdated"
      />

      <div class="mt-4 flex gap-2">
        <Button :disabled="generating" @click.prevent="generateContract('pt')"
          >Generate Contract (PT)</Button
        >
        <Button :disabled="generating" @click.prevent="generateContract('en')"
          >Generate Contract (EN)</Button
        >
      </div>

      <!-- Company Contacts -->
      <!-- prettier-ignore -->
      <CompanyContacts
        v-if="representatives"
        :representatives="representatives"
        :company-id="(companyId as string)"
      />
      <div
        v-else-if="isRepresentativesLoading"
        class="flex items-center justify-center p-8"
      >
        <div class="text-muted-foreground">Loading representatives...</div>
      </div>
    </div>

    <!-- Communications section -->
    <div class="flex-1 min-w-0">
      <!-- prettier-ignore -->
      <ParticipationsCard
        v-if="companyWithParticipation?.participations"
        :participations="companyWithParticipation.participations"
        :entity-id="(companyId as string)"
        entity-type="company"
        class="mb-5"
      />

      <CompanyCommunications :company="companyWithParticipation" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { getCompanyById, getCompanyRepresentatives } from "@/api/companies";
import CompanyCard from "@/components/cards/CompanyCard.vue";
import CompanyBillingInfo from "@/components/companies/CompanyBillingInfo.vue";
import Button from "@/components/ui/button/Button.vue";
import CompanyContacts from "@/components/companies/CompanyContacts.vue";
import CompanyCommunications from "@/components/companies/CompanyCommunications.vue";
import ParticipationsCard from "@/components/ParticipationsCard.vue";
import DirectEmailDialogTrigger from "@/components/DirectEmailDialogTrigger.vue";
import type { CompanyWithParticipation } from "@/dto/companies";
import { withCurrentParticipation } from "@/lib/utils";
import { useEventStore } from "@/stores/event";

import { useQuery, useQueryCache } from "@pinia/colada";
import { useMutation } from "@pinia/colada";
import { generateCompanyContract } from "@/api/companies";
import type { AxiosResponse } from "axios";
import { computed } from "vue";
import { useRoute } from "vue-router";

const route = useRoute();
const queryCache = useQueryCache();

const companyId = route.params.companyId;
const { data: company } = useQuery({
  key: () => ["company", companyId],
  query: () => getCompanyById(companyId as string),
});

const { data: representativesData, isLoading: isRepresentativesLoading } =
  useQuery({
    key: () => ["company-representatives", companyId],
    query: () => getCompanyRepresentatives(companyId as string),
  });

const representatives = computed(() => representativesData.value?.data);

const handleCompanyUpdated = () => {
  // Invalidate the company query to refresh the data
  queryCache.invalidateQueries({ key: ["company", companyId] });
};

const eventStore = useEventStore();
const companyWithParticipation = computed(() => {
  if (!company.value?.data || !eventStore.selectedEvent) return null;

  return withCurrentParticipation(
    company.value.data,
    eventStore.selectedEvent,
  ) as CompanyWithParticipation;
});

const { mutate: generateMutate, isLoading: generating } = useMutation({
  mutation: (variables: { companyId: string; language: string }) =>
    generateCompanyContract(variables.companyId as string, {
      language: variables.language,
    }),
  onSuccess: (res: AxiosResponse<Blob>) => {
    // res is an axios response with blob data (DOCX)
    try {
      const blob = new Blob([res.data], {
        type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      const name = (
        companyWithParticipation.value?.billingInfo?.name ||
        companyWithParticipation.value?.name ||
        "contract"
      ).replace(/[^a-z0-9_-]/gi, "-");
      link.download = `contract-${name}.docx`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
    } catch (e) {
      console.error("Error downloading generated DOCX", e);
    }
  },
});

const generateContract = (lang: string) => {
  if (!companyWithParticipation.value) return;

  generateMutate({ companyId: companyId as string, language: lang });
};
</script>
