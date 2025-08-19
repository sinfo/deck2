import type { Event } from "@/dto/events";
import { defineStore } from "pinia";
import { ref } from "vue";

export const useEventStore = defineStore("event", () => {
  const selectedEvent = ref<Event | null>(null);

  return { selectedEvent };
});
