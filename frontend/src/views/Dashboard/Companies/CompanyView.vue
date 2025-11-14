<template>
  <div v-if="companyWithParticipation" class="flex flex-col lg:flex-row gap-6">
    <!-- Company information section -->
    <div class="space-y-6 w-full lg:w-96 lg:flex-shrink-0">
      <!-- Company Card -->
      <CompanyCard
        :company="companyWithParticipation"
        @updated="handleCompanyUpdated"
      />

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

      <!-- Audit logs (admin/coordinator) -->
      <div v-if="canViewLogs" class="mt-6 bg-card p-4 rounded-md">
        <h3 class="text-lg font-medium mb-2">Logs</h3>

        <div v-if="companyLogsLoading" class="text-muted-foreground">
          Loading logs...
        </div>

        <div v-else>
          <div
            v-if="companyLogs && companyLogs.length === 0"
            class="text-muted-foreground"
          >
            No logs for this company.
          </div>

          <div v-else>
            <div v-for="log in companyLogs" :key="log.id" class="log-entry">
              <div class="text-sm text-muted-foreground">
                {{ new Date(log.date).toLocaleString() }}
              </div>
              <div class="font-medium">
                {{ formatLogMessage(log) }}
              </div>
              <div class="text-sm text-muted-foreground">
                Actor: {{ getActorName(log.actor) }}
              </div>
              <div
                v-if="log.data && Object.keys(log.data).length"
                class="text-xs mt-1"
              >
                <pre class="whitespace-pre-wrap">{{
                  formatLogDetails(log)
                }}</pre>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { getCompanyById, getCompanyRepresentatives } from "@/api/companies";
import CompanyCard from "@/components/cards/CompanyCard.vue";
import CompanyBillingInfo from "@/components/companies/CompanyBillingInfo.vue";
import CompanyContacts from "@/components/companies/CompanyContacts.vue";
import CompanyCommunications from "@/components/companies/CompanyCommunications.vue";
import ParticipationsCard from "@/components/ParticipationsCard.vue";
import type { CompanyWithParticipation } from "@/dto/companies";
import { withCurrentParticipation } from "@/lib/utils";
import { useEventStore } from "@/stores/event";
import { useAuthStore } from "@/stores/auth";
import { getLogsByCompany } from "@/api/logs";
import { getAllMembers } from "@/api/members";
import type { Log } from "@/dto/logs";
import type { Member } from "@/dto/members";

import { useQuery, useQueryCache } from "@pinia/colada";
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

// logs (admin/coordinator)
const authStore = useAuthStore();
const canViewLogs = computed(() => {
  const role = authStore.decoded?.role as string | undefined;
  console.log("User role:", role);
  return role === "ADMIN" || role === "COORDINATOR";
});

// fetch members so we can resolve actor ids to names
const { data: membersData } = useQuery({
  key: () => ["members"],
  query: () => getAllMembers(),
});

const membersById = computed(() => {
  const map = new Map<string, Member>();
  if (!membersData.value?.data) return map;
  for (const m of membersData.value.data) {
    map.set(m.id, m as Member);
  }
  return map;
});

const getActorName = (actorId?: string | null) => {
  if (!actorId) return "system";
  const m = membersById.value.get(actorId);
  return m?.name || actorId;
};

const formatLogMessage = (log: Log) => {
  const action: string = log.action || "";
  const data = log.data ?? {};

  switch (action) {
    case "UPDATED_PARTICIPATION_STATUS":
      if ("from" in data || "to" in data) {
        const from = String((data as Record<string, unknown>)["from"] ?? "—");
        const to = String((data as Record<string, unknown>)["to"] ?? "—");
        return `Participation status changed from ${from} to ${to}`;
      }
      return "Participation status changed";
    case "CREATE_COMPANY":
      return `Company created${"name" in data ? `: ${String((data as Record<string, unknown>)["name"])}` : ""}`;
    case "UPDATE_COMPANY":
      return `Company updated${"name" in data ? `: ${String((data as Record<string, unknown>)["name"])}` : ""}`;
    case "ADD_PARTICIPATION":
      return "event" in data
        ? `Participation added for event ${String((data as Record<string, unknown>)["event"])}`
        : "Participation added";
    case "ADD_COMMUNICATION":
      return `Communication added${"company" in data ? ` (company ${String((data as Record<string, unknown>)["company"])})` : ""}`;
    case "ADD_PACKAGE":
      return `Package added${"packageId" in data ? `: ${String((data as Record<string, unknown>)["packageId"])}` : ""}`;
    case "ADD_PARTICIPATION_BILLING":
      return `Billing added${"billingId" in data ? `: ${String((data as Record<string, unknown>)["billingId"])}` : ""}`;
    case "DELETE_PARTICIPATION_BILLING":
      return `Billing removed${"billingId" in data ? `: ${String((data as Record<string, unknown>)["billingId"])}` : ""}`;
    case "DELETE_COMPANY":
      return `Company deleted${"name" in data ? `: ${String((data as Record<string, unknown>)["name"])}` : ""}`;
    case "ADD_EMPLOYER":
      return `Employer added${"repName" in data ? `: ${String((data as Record<string, unknown>)["repName"])}` : ""}`;
    case "REMOVE_EMPLOYER":
      return `Employer removed${"repId" in data ? `: ${String((data as Record<string, unknown>)["repId"])}` : ""}`;
    default:
      return `${log.action} — ${log.resource}`;
  }
};

const formatLogDetails = (log: Log) => {
  try {
    return JSON.stringify(log.data ?? {}, null, 2);
  } catch {
    return String(log.data ?? "");
  }
};

const { data: companyLogs, isLoading: companyLogsLoading } = useQuery({
  key: () => [
    "company-logs",
    companyId,
    eventStore.selectedEvent?.id ?? "no-event",
  ],
  query: () => {
    const params: Record<string, string | number> = {};
    if (eventStore.selectedEvent) params.event = eventStore.selectedEvent.id;
    return getLogsByCompany(companyId as string, params).then((r) => r.data);
  },
  enabled: () => canViewLogs.value && !!companyId && !!eventStore.selectedEvent,
});
</script>

<style scoped>
.log-entry {
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
  padding: 8px 0;
}
</style>
