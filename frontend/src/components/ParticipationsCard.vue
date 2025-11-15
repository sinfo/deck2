<template>
  <Card class="w-full py-0">
    <CardHeader class="w-full">
      <Accordion type="single" collapsible class="w-full">
        <AccordionItem value="participations">
          <AccordionTrigger class="text-lg font-semibold px-0 cursor-pointer">
            Participations
          </AccordionTrigger>
          <AccordionContent class="px-0">
            <div
              v-if="sortedParticipations.length === 0"
              class="text-muted-foreground p-4"
            >
              No participations found.
            </div>
            <div v-else class="space-y-4">
              <!-- Current participation - Editable or Create -->
              <div v-if="currentParticipation">
                <div class="flex items-center gap-2 mb-3">
                  <h4 class="text-sm font-medium text-muted-foreground">
                    Current
                  </h4>
                </div>
                <EditableCompanyParticipation
                  v-if="isCompanyParticipation(currentParticipation)"
                  :participation="currentParticipation"
                  :company-id="entityId"
                />
                <EditableSpeakerParticipation
                  v-else-if="isSpeakerParticipation(currentParticipation)"
                  :participation="currentParticipation"
                  :speaker-id="entityId"
                />
              </div>

              <!-- Create participation if no current participation exists -->
              <div v-else-if="getCurrentEvent()">
                <div class="flex items-center gap-2 mb-3">
                  <h4 class="text-sm font-medium text-muted-foreground">
                    Current
                  </h4>
                </div>

                <EmptyStateCard
                  title="Create Participation"
                  :description="`Click to participate in ${getEventName(getCurrentEvent()?.id || 0)}`"
                  :loading="isCreatingParticipation"
                  loading-text="Creating..."
                  @click="createParticipation"
                />
              </div>

              <!-- Past participations - Read-only -->
              <div v-if="pastParticipations.length > 0">
                <h4
                  v-if="currentParticipation || getCurrentEvent()"
                  class="text-sm font-medium text-muted-foreground mb-3 mt-6"
                >
                  Past Participations
                </h4>
                <div class="space-y-4">
                  <Card
                    v-for="participation in pastParticipations"
                    :key="participation.event"
                    class="p-4"
                  >
                    <div class="space-y-3">
                      <div class="flex items-center justify-between">
                        <h4 class="font-medium">
                          {{ getEventName(participation.event) }}
                        </h4>
                        <Badge
                          :class="
                            participationStatusColor[participation.status]
                              ?.background
                          "
                          class="text-xs"
                        >
                          {{
                            humanReadableParticipationStatus[
                              participation.status
                            ]
                          }}
                        </Badge>
                      </div>

                      <div
                        class="grid grid-cols-1 lg:grid-cols-3 gap-4 items-start"
                      >
                        <div class="flex items-center gap-2">
                          <Image
                            :src="getMember(participation.member)?.img"
                            :alt="getMember(participation.member)?.name"
                            class="w-8 h-8 rounded-full object-cover border"
                          />
                          <div>
                            <div class="text-sm font-medium">
                              {{ getMember(participation.member)?.name }}
                            </div>
                            <div class="text-xs text-muted-foreground">
                              Responsible
                            </div>
                          </div>
                        </div>

                        <template v-if="isCompanyParticipation(participation)">
                          <div
                            v-if="hasDate(participation.confirmed)"
                            class="text-sm"
                          >
                            <span class="font-medium">Confirmed:</span>
                            <div class="mt-1 text-muted-foreground">
                              {{ formatDate(participation.confirmed) }}
                            </div>
                          </div>

                          <div v-if="participation.notes" class="text-sm">
                            <span class="font-medium">Notes:</span>
                            <div class="mt-1 text-muted-foreground">
                              {{ participation.notes }}
                            </div>
                          </div>

                          <div
                            v-if="participation.partner"
                            class="flex items-center gap-1"
                          >
                            <Badge variant="secondary" class="text-xs"
                              >Partner</Badge
                            >
                          </div>
                        </template>
                        <template
                          v-else-if="isSpeakerParticipation(participation)"
                        >
                        </template>
                      </div>
                    </div>
                  </Card>
                </div>
              </div>
            </div>
          </AccordionContent>
        </AccordionItem>
      </Accordion>
    </CardHeader>
  </Card>
</template>

<script setup lang="ts">
import { getAllEvents } from "@/api/events";
import { getAllMembers } from "@/api/members";
import { useCreateCompanyParticipationMutation } from "@/mutations/companies";
import { useCreateSpeakerParticipationMutation } from "@/mutations/speakers";
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader } from "@/components/ui/card";
import EditableCompanyParticipation from "./companies/EditableCompanyParticipation.vue";
import EditableSpeakerParticipation from "./speakers/EditableSpeakerParticipation.vue";
import type { CompanyParticipation } from "@/dto/companies";
import type { SpeakerParticipation } from "@/dto/speakers";
import {
  humanReadableParticipationStatus,
  participationStatusColor,
} from "@/dto";

import { useQuery } from "@pinia/colada";
import { computed } from "vue";
import Image from "./Image.vue";
import EmptyStateCard from "./ui/EmptyStateCard.vue";

type Participation = CompanyParticipation | SpeakerParticipation;

interface Props {
  participations: Participation[];
  entityId: string;
  entityType: "company" | "speaker";
}

const props = defineProps<Props>();

const { data: eventsData } = useQuery({
  key: () => ["events"],
  query: () => getAllEvents(),
});

const { data: membersData } = useQuery({
  key: () => ["members"],
  query: () => getAllMembers(),
});

const createCompanyParticipationMutation =
  useCreateCompanyParticipationMutation();
const createSpeakerParticipationMutation =
  useCreateSpeakerParticipationMutation();

const isCreatingParticipation = computed(
  () =>
    createCompanyParticipationMutation.isLoading.value ||
    createSpeakerParticipationMutation.isLoading.value,
);

const sortedParticipations = computed(() => {
  if (!props.participations) return [];
  return [...props.participations].sort((a, b) => b.event - a.event); // Most recent first
});

const getCurrentEvent = () => {
  if (!eventsData.value?.data) return null;
  // Find the current event (the one with the highest ID)
  return eventsData.value.data.reduce((latest, event) =>
    event.id > latest.id ? event : latest,
  );
};

const currentParticipation = computed(() => {
  const currentEvent = getCurrentEvent();
  if (!currentEvent) return null;

  return props.participations.find((p) => p.event === currentEvent.id) || null;
});

const pastParticipations = computed(() => {
  const currentEvent = getCurrentEvent();
  if (!currentEvent) return sortedParticipations.value;

  // All participations except the current one
  return sortedParticipations.value.filter((p) => p.event !== currentEvent.id);
});

const getEventName = (eventId: number) => {
  if (!eventsData.value?.data) return `Event ${eventId}`;
  const event = eventsData.value.data.find((e) => e.id === eventId);
  return event?.name || `Event ${eventId}`;
};

const getMember = (memberId: string) => {
  if (!membersData.value?.data) return null;
  return membersData.value.data.find((m) => m.id === memberId) || null;
};

const hasDate = (dateString: string) => {
  return !!dateString && dateString !== "0001-01-01T00:00:00Z";
};

const formatDate = (dateString: string) => {
  if (!hasDate(dateString)) return "";
  try {
    return new Date(dateString).toLocaleString();
  } catch {
    return dateString;
  }
};

const isCompanyParticipation = (
  _participation: Participation,
): _participation is CompanyParticipation => {
  return props.entityType === "company";
};

const isSpeakerParticipation = (
  _participation: Participation,
): _participation is SpeakerParticipation => {
  return props.entityType === "speaker";
};

const createParticipation = async () => {
  if (isCreatingParticipation.value) return;

  const currentEvent = getCurrentEvent();
  if (!currentEvent) return;

  try {
    if (props.entityType === "company") {
      createCompanyParticipationMutation.companyId.value = props.entityId;
      createCompanyParticipationMutation.data.value = {
        partner: false,
      };
      await createCompanyParticipationMutation.mutate();
    } else if (props.entityType === "speaker") {
      createSpeakerParticipationMutation.speakerId.value = props.entityId;
      await createSpeakerParticipationMutation.mutate();
    }
  } catch (error) {
    console.error("Failed to create participation:", error);
  }
};
</script>
