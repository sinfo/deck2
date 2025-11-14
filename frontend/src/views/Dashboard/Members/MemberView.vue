<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center gap-4">
        <Image
          :src="member?.data?.img"
          alt="Member Avatar"
          class="w-12 h-12 rounded-xl"
        />
        <div v-if="member?.data">
          <h1 class="text-2xl font-bold">{{ member.data.name }}</h1>
          <div class="text-sm text-muted-foreground">
            SINFO ID: {{ member.data.sinfoid || "—" }}
          </div>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div class="mb-6 lg:col-span-3">
        <ContactCard
          v-if="contact?.data"
          :contact="contact.data"
          :contact-name="member?.data?.name"
          :can-edit="false"
        />
        <Skeleton v-else-if="contactLoading" class="h-28" />
      </div>
      <section class="col-span-1 lg:col-span-2">
        <Accordion type="single" collapsible class="mb-3">
          <AccordionItem value="speakers">
            <AccordionTrigger
              class="text-lg font-semibold flex items-center justify-between p-3 border rounded-md hover:bg-slate-50"
            >
              <div class="flex items-center gap-2">
                <span>Speakers</span>
                <span class="text-sm text-muted-foreground"
                  >({{ speakers?.data?.length || 0 }})</span
                >
              </div>
            </AccordionTrigger>
            <br />
            <AccordionContent>
              <div
                v-if="speakersLoading"
                class="grid grid-cols-2 sm:grid-cols-3 gap-3"
              >
                <Skeleton
                  v-for="skeletonIndex in 6"
                  :key="skeletonIndex"
                  class="h-20"
                />
              </div>

              <div
                v-else-if="speakers?.data && speakers.data.length === 0"
                class="text-muted-foreground"
              >
                No speakers found for this member.
              </div>

              <div
                v-else
                class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3"
              >
                <RouterLink
                  v-for="s in speakers?.data || []"
                  :key="s.id"
                  :to="{ name: 'speaker', params: { speakerId: s.id } }"
                  class="block p-2 border rounded-md hover:shadow-sm bg-white"
                >
                  <Image
                    :src="
                      s.imgs?.speaker || s.imgs?.internal || s.imgs?.company
                    "
                    class="w-full h-16 object-contain mb-2"
                  />
                  <div class="text-sm font-medium truncate">{{ s.name }}</div>
                </RouterLink>
              </div>
            </AccordionContent>
          </AccordionItem>
        </Accordion>

        <Accordion type="single" collapsible class="mt-6">
          <AccordionItem value="companies">
            <AccordionTrigger
              class="text-lg font-semibold flex items-center justify-between p-3 border rounded-md hover:bg-slate-50"
            >
              <div class="flex items-center gap-2">
                <span>Companies</span>
                <span class="text-sm text-muted-foreground"
                  >({{ companies?.data?.length || 0 }})</span
                >
              </div>
            </AccordionTrigger>
            <br />
            <AccordionContent>
              <div
                v-if="companiesLoading"
                class="grid grid-cols-2 sm:grid-cols-3 gap-3"
              >
                <Skeleton
                  v-for="skeletonIndex in 6"
                  :key="`c-${skeletonIndex}`"
                  class="h-20"
                />
              </div>

              <div
                v-else-if="companies?.data && companies.data.length === 0"
                class="text-muted-foreground"
              >
                No companies found for this member.
              </div>

              <div
                v-else
                class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3"
              >
                <RouterLink
                  v-for="company in companies?.data || []"
                  :key="company.id"
                  :to="{ name: 'company', params: { companyId: company.id } }"
                  class="block p-2 border rounded-md hover:shadow-sm bg-white"
                >
                  <Image
                    :src="company.imgs?.internal || company.imgs?.public"
                    class="w-full h-16 object-contain mb-2"
                  />
                  <div class="text-sm font-medium truncate">
                    {{ company.name }}
                  </div>
                </RouterLink>
              </div>
            </AccordionContent>
          </AccordionItem>
        </Accordion>
      </section>

      <aside>
        <h2 class="text-xl font-semibold mb-3">Participations & Teams</h2>

        <div v-if="participationsLoading">
          <Skeleton
            v-for="skeletonIndex in 4"
            :key="skeletonIndex"
            class="h-16 mb-2"
          />
        </div>

        <div
          v-else-if="participations?.data && participations.data.length === 0"
          class="text-muted-foreground"
        >
          No participations found.
        </div>

        <div v-else class="space-y-3">
          <div
            v-for="participation in sortedParticipations"
            :key="`${participation.event}-${participation.team}`"
            class="p-3 border rounded"
          >
            <div class="font-medium">
              {{ getEventName(participation.event) }}
            </div>
            <div class="text-sm text-muted-foreground">
              Team: {{ getTeamName(participation.team) }}
            </div>
            <div class="text-sm text-muted-foreground">
              Role: {{ participation.role }}
            </div>
          </div>
        </div>
      </aside>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRoute } from "vue-router";
import { computed } from "vue";
import { useQuery } from "@pinia/colada";
import { getMemberById, getMemberParticipations } from "@/api/members";
import { getAllSpeakers } from "@/api/speakers";
import { getAllCompanies } from "@/api/companies";
import { useEventStore } from "@/stores/event";
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "@/components/ui/accordion";
import Image from "@/components/Image.vue";
import ContactCard from "@/components/ContactCard.vue";
import { instance } from "@/api";
import { Skeleton } from "@/components/ui/skeleton";
import { getAllEvents } from "@/api/events";
import type { Event } from "@/dto/events";

const route = useRoute();
const memberId = String(route.params.memberId || "");

const { data: member } = useQuery({
  key: () => ["member", memberId],
  query: () => getMemberById(memberId),
});

const eventStore = useEventStore();

const speakersFilters = computed(() => ({
  member: memberId,
  event: eventStore.selectedEvent?.id,
}));

const { data: speakers, isLoading: speakersLoading } = useQuery({
  key: () => ["member-speakers", JSON.stringify(speakersFilters.value)],
  query: () => getAllSpeakers(speakersFilters.value),
});

const contactId = computed(
  () => member.value?.data?.contact as string | undefined,
);

const { data: contact, isLoading: contactLoading } = useQuery({
  key: () => ["member-contact", contactId.value || ""],
  enabled: () => !!contactId.value,
  query: () => instance.get(`/contacts/${contactId.value}`),
});

const companiesFilters = computed(() => ({
  member: memberId,
  event: eventStore.selectedEvent?.id,
}));

const { data: companies, isLoading: companiesLoading } = useQuery({
  key: () => ["member-companies", JSON.stringify(companiesFilters.value)],
  query: () => getAllCompanies(companiesFilters.value),
});

// Collapsible implemented with Accordion UI - no local toggles needed

const { data: participations, isLoading: participationsLoading } = useQuery({
  key: () => ["member-participations", memberId],
  query: () => getMemberParticipations(memberId),
});

const { data: eventsData } = useQuery({
  key: () => ["events"],
  query: () => getAllEvents(),
});

const getEventName = (id: number) => {
  if (!eventsData.value?.data) return `Event ${id}`;
  const evt = eventsData.value.data.find((e: Event) => e.id === id);
  return evt?.name || `Event ${id}`;
};

const getTeamName = (team: string) => {
  if (!team) return "";
  return team.split(" (")[0];
};

// Sort participations by event id descending (largest -> smallest)
const sortedParticipations = computed(() => {
  const list = participations.value?.data || [];
  return [...list].sort((a, b) => (b.event || 0) - (a.event || 0));
});
</script>

<style scoped>
.text-muted-foreground {
  color: var(--muted-foreground);
}
</style>
