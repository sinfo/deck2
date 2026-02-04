<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="text-3xl font-bold tracking-tight">Multimedia Dashboard</h1>
    </div>

    <!-- Stats Section -->
    <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <Card>
        <CardHeader
          class="flex flex-row items-center justify-between space-y-0 pb-2"
        >
          <CardTitle class="text-sm font-medium">Total Companies</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">{{ tableData.length }}</div>
          <p class="text-xs text-muted-foreground">Accepted / Announced</p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader
          class="flex flex-row items-center justify-between space-y-0 pb-2"
        >
          <CardTitle class="text-sm font-medium">Logos Received</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">{{ stats.logosReceived }}</div>
          <p class="text-xs text-muted-foreground">
            {{ stats.logosReceivedPercent }}%
          </p>
        </CardContent>
      </Card>
    </div>

    <!-- Table Section -->
    <Card>
      <CardHeader>
        <CardTitle>Company Assets</CardTitle>
        <CardDescription
          >Overview of multimedia assets for accepted
          companies.</CardDescription
        >
      </CardHeader>
      <CardContent>
        <div class="rounded-md border overflow-x-auto">
          <table class="w-full caption-bottom text-sm text-left min-w-[800px]">
            <thead class="[&_tr]:border-b">
              <tr
                class="border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted"
              >
                <th
                  class="h-12 px-4 align-middle font-medium text-muted-foreground"
                >
                  Company
                </th>
                <th
                  class="h-12 px-4 align-middle font-medium text-muted-foreground"
                >
                  Responsible
                </th>
                <th
                  class="h-12 px-4 align-middle font-medium text-muted-foreground"
                >
                  Package
                </th>
                <th
                  class="h-12 px-4 align-middle font-medium text-muted-foreground text-center"
                >
                  Logo Received
                </th>
                <th
                  class="h-12 px-4 align-middle font-medium text-muted-foreground text-center"
                >
                  Vector Logo
                </th>
                <th
                  class="h-12 px-4 align-middle font-medium text-muted-foreground text-center"
                >
                  Requested Material Review
                </th>
                <th
                  class="h-12 px-4 align-middle font-medium text-muted-foreground text-center"
                >
                  Guidelines
                </th>
                <th
                  class="h-12 px-4 align-middle font-medium text-muted-foreground"
                >
                  Notes
                </th>
              </tr>
            </thead>
            <tbody class="[&_tr:last-child]:border-0">
              <tr v-if="isLoading" class="border-b">
                <td colspan="8" class="p-4 text-center">Loading...</td>
              </tr>
              <tr v-else-if="tableData.length === 0" class="border-b">
                <td colspan="8" class="p-4 text-center">No companies found</td>
              </tr>
              <tr
                v-for="row in tableData"
                v-else
                :key="row.id"
                class="border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted"
              >
                <td class="p-4 align-middle font-medium">{{ row.name }}</td>
                <td class="p-4 align-middle">{{ row.responsible }}</td>
                <td class="p-4 align-middle">{{ row.package }}</td>
                <td class="p-4 align-middle text-center">
                  <div
                    :class="
                      row.logoReceived
                        ? 'text-green-600 font-bold'
                        : 'text-red-500'
                    "
                  >
                    {{ row.logoReceived ? "Sim" : "Não" }}
                  </div>
                </td>
                <td class="p-4 align-middle text-center text-muted-foreground">
                  -
                </td>
                <td class="p-4 align-middle text-center text-muted-foreground">
                  -
                </td>
                <td class="p-4 align-middle text-center text-muted-foreground">
                  -
                </td>
                <td
                  class="p-4 align-middle max-w-[200px] truncate"
                  :title="row.notes"
                >
                  {{ row.notes }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </CardContent>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useQuery } from "@pinia/colada";
import { useEventStore } from "@/stores/event";
import { getAllCompanies } from "@/api/companies";
import { getAllMembers } from "@/api/members";
import { getPackages } from "@/api/packages";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import type { Company } from "@/dto/companies";
import type { Member } from "@/dto/members";
import type { Package } from "@/dto/packages";
import type { AllCompaniesFilter } from "@/dto/companies";

const eventStore = useEventStore();

// Queries
const companiesFilters = computed<AllCompaniesFilter>(() => ({
  event: eventStore.selectedEvent?.id,
}));

const { data: companiesList, isLoading: isCompaniesLoading } = useQuery({
  key: () => ["companies", JSON.stringify(companiesFilters.value)],
  query: () => getAllCompanies(companiesFilters.value),
  enabled: () => !!eventStore.selectedEvent,
});

const { data: membersList, isLoading: isMembersLoading } = useQuery({
  key: () => ["members", eventStore.selectedEvent?.id || 0],
  query: () => getAllMembers({ event: eventStore.selectedEvent?.id }),
  enabled: () => !!eventStore.selectedEvent,
});

const { data: packagesList, isLoading: isPackagesLoading } = useQuery({
  key: () => ["packages", eventStore.selectedEvent?.id || 0],
  query: () => getPackages(),
  enabled: () => !!eventStore.selectedEvent, // Assuming packages are not strictly event-bound in API but filtered later
});

const isLoading = computed(
  () =>
    isCompaniesLoading.value ||
    isMembersLoading.value ||
    isPackagesLoading.value,
);

// Maps for easier lookup
const membersMap = computed(() => {
  const map = new Map<string, string>();
  if (membersList.value?.data) {
    (membersList.value.data as Member[]).forEach((m) => map.set(m.id, m.name));
  }
  return map;
});

const packagesMap = computed(() => {
  const map = new Map<string, string>();
  if (packagesList.value) {
    (packagesList.value as Package[]).forEach((p) => map.set(p.id, p.name));
  }
  return map;
});

// Processed Data
const tableData = computed(() => {
  if (!companiesList.value?.data || !eventStore.selectedEvent) return [];

  const eventId = eventStore.selectedEvent.id;

  return (companiesList.value.data as Company[])
    .map((company) => {
      const participation = company.participations.find(
        (p) => p.event === eventId,
      );
      return {
        company,
        participation,
      };
    })
    .filter(({ participation }) => {
      // Filter for accepted/announced companies
      return (
        participation &&
        ["ACCEPTED", "ANNOUNCED"].includes(participation.status)
      );
    })
    .map(({ company, participation }) => {
      const memberName = participation?.member
        ? membersMap.value.get(participation.member) || "Unknown"
        : "-";
      const packageName = participation?.package
        ? packagesMap.value.get(participation.package) || "Unknown"
        : "-";

      const logoReceived = !!company.imgs?.public; // Deduce from existing images

      return {
        id: company.id,
        name: company.name,
        responsible: memberName,
        package: packageName,
        logoReceived: logoReceived,
        notes: participation?.notes || "",
      };
    });
});

const stats = computed(() => {
  const total = tableData.value.length;
  if (total === 0) return { logosReceived: 0, logosReceivedPercent: 0 };

  const received = tableData.value.filter((c) => c.logoReceived).length;

  return {
    logosReceived: received,
    logosReceivedPercent: (received / total) * 100,
  };
});
</script>
