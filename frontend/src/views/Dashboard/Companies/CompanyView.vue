<template>
  <div v-if="companyWithParticipation" class="flex flex-col lg:flex-row gap-6">
    <!-- Company information section -->
    <div class="space-y-4 w-full lg:w-96 lg:flex-shrink-0">
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

      <!-- Mobile: Accordion for Billing Info and Contacts -->
      <Accordion type="multiple" class="lg:hidden" collapsible>
        <AccordionItem value="billing">
          <AccordionTrigger>Billing Information</AccordionTrigger>
          <AccordionContent>
            <CompanyBillingInfo
              :company="company?.data"
              @updated="handleCompanyUpdated"
            />
          </AccordionContent>
        </AccordionItem>
        <AccordionItem value="contacts">
          <AccordionTrigger>Contacts</AccordionTrigger>
          <AccordionContent>
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
              <div class="text-muted-foreground">
                Loading representatives...
              </div>
            </div>
          </AccordionContent>
        </AccordionItem>
      </Accordion>

      <!-- Desktop: Regular display for Billing Info and Contacts -->
      <div class="hidden lg:block space-y-6">
        <!-- Company Billing Information -->
        <CompanyBillingInfo
          :company="company?.data"
          @updated="handleCompanyUpdated"
        />

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
    </div>

    <!-- Info/Tasks section -->
    <div class="flex-1 min-w-0">
      <Tabs v-model="activeTab" default-value="info" class="w-full">
        <TabsList class="grid w-full grid-cols-2 max-w-md">
          <TabsTrigger value="info"> Info </TabsTrigger>
          <TabsTrigger value="tasks"> Tasks </TabsTrigger>
        </TabsList>

        <TabsContent value="info">
          <Info :company-with-participation="companyWithParticipation" />
        </TabsContent>
        <TabsContent value="tasks">
          <Tasks :company-with-participation="companyWithParticipation" />
        </TabsContent>
      </Tabs>
    </div>
  </div>
</template>

<script setup lang="ts">
import { getCompanyById, getCompanyRepresentatives } from "@/api/companies";
import CompanyCard from "@/components/cards/CompanyCard.vue";
import CompanyBillingInfo from "@/components/companies/CompanyBillingInfo.vue";
import CompanyContacts from "@/components/companies/CompanyContacts.vue";
import DirectEmailDialogTrigger from "@/components/DirectEmailDialogTrigger.vue";
import type { CompanyWithParticipation } from "@/dto/companies";
import { withCurrentParticipation } from "@/lib/utils";
import { useEventStore } from "@/stores/event";

import { useQuery, useQueryCache } from "@pinia/colada";
import { computed, ref } from "vue";
import { useRoute } from "vue-router";
import Info from "./Info/Info.vue";
import TabsList from "@/components/ui/tabs/TabsList.vue";
import TabsTrigger from "@/components/ui/tabs/TabsTrigger.vue";
import TabsContent from "@/components/ui/tabs/TabsContent.vue";
import Tabs from "@/components/ui/tabs/Tabs.vue";
import Tasks from "./Tasks/Tasks.vue";
import Accordion from "@/components/ui/accordion/Accordion.vue";
import AccordionItem from "@/components/ui/accordion/AccordionItem.vue";
import AccordionTrigger from "@/components/ui/accordion/AccordionTrigger.vue";
import AccordionContent from "@/components/ui/accordion/AccordionContent.vue";

const route = useRoute();
const queryCache = useQueryCache();
const activeTab = ref("info");

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
</script>
