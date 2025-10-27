<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { Menu, X, LogOut, Settings, Trash } from "lucide-vue-next";
import { Bell } from "lucide-vue-next";
import { Button } from "@/components/ui/button";
import type { RouteLocationRaw } from "vue-router";
import { useQuery } from "@pinia/colada";
import { getAllEvents } from "@/api/events";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "./ui/select";
import { useEventStore } from "@/stores/event";
import { useAuthStore } from "@/stores/auth";
import { useRouter } from "vue-router";
import CompanyOrSpeakerAutocompleteWithDialog from "./CompanyOrSpeakerAutocompleteWithDialog.vue";
import type { Company } from "@/dto/companies";
import type { Speaker } from "@/dto/speakers";
import { useMagicKeys } from "@vueuse/core";
import type { EnrichedNotification } from '@/dto/notifications';
import { useNotificationsStore } from "@/stores/notifications";
import {
  Popover, PopoverContent, PopoverTrigger,
} from '@/components/ui/popover'

const isOpen = ref(false);
const authStore = useAuthStore();
const router = useRouter();

const logout = () => {
  authStore.clearToken();
  router.push({ name: "landing" });
};


const notificationsStore = useNotificationsStore();

const navigateNotification = (n: EnrichedNotification) => {
  const actor = n.actor;
  // if actor is a speaker or company, navigate to their page
  if (actor?.type === 'speaker' && actor?.id) {
    router.push({ name: 'speaker', params: { speakerId: actor.id } });
    return;
  }

  if (actor?.type === 'company' && actor?.id) {
    router.push({ name: 'company', params: { companyId: actor.id } });
    return;
  }

};

interface NavigationItem {
  name: string;
  to: RouteLocationRaw;
  icon?: any;
}

const navigation: NavigationItem[] = [
  { name: "Me", to: { name: "dashboard" } },
  { name: "Companies", to: { name: "companies" } },
  { name: "Speakers", to: { name: "speakers" } },
  { name: "Settings", to: { name: "settings" }, icon: Settings },
];

const { data: events, isLoading: eventsLoading } = useQuery({
  key: ["events"],
  query: getAllEvents,
});

const sortedEvents = computed(() =>
  events.value?.data.sort((a, b) => b.begin?.localeCompare(a.begin || "") || 0),
);

const eventStore = useEventStore();

watch(
  () => sortedEvents.value,
  () => {
    if (sortedEvents.value?.length && !eventStore.selectedEvent) {
      eventStore.selectedEvent = sortedEvents.value[0]!;
    }
  },
  { immediate: true },
);

const companySelected = (company: Company) =>
  router.push({ name: "company", params: { companyId: company.id } });

const speakerSelected = (speaker: Speaker) =>
  router.push({ name: "speaker", params: { speakerId: speaker.id } });

const keys = useMagicKeys();
const shortcutMac = keys["meta+k"];
const shortcutLinux = keys["ctrl+k"];
const showSuggestions = ref(false);

watch(shortcutMac, () => {
  if (shortcutMac.value) {
    showSuggestions.value = true;
    // Reset after a short delay to allow the component to react
    setTimeout(() => {
      showSuggestions.value = false;
    }, 100);
  }
});

watch(shortcutLinux, () => {
  if (shortcutLinux.value) {
    showSuggestions.value = true;
    // Reset after a short delay to allow the component to react
    setTimeout(() => {
      showSuggestions.value = false;
    }, 100);
  }
});
</script>

<template>
  <section class="fixed top-0 left-0 right-0 z-50 w-full flex items-center bg-white py-4 border-b border-gray-200">
    <div class="container mx-auto px-4 md:px-6 lg:px-8">
      <nav class="flex items-center justify-between">
        <div class="flex items-center gap-3">
          <RouterLink :to="{ name: 'dashboard' }" class="text-2xl font-bold">Deck</RouterLink>

          <Select v-model="eventStore.selectedEvent">
            <SelectTrigger :loading="eventsLoading">
              <SelectValue placeholder="Edition" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem v-for="event in sortedEvents" :key="event.id" :value="event">
                {{ event.name }}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>

        <CompanyOrSpeakerAutocompleteWithDialog :autofocus="showSuggestions" :force-show-suggestions="showSuggestions"
          class="hidden md:inline w-full px-3" placeholder="Search" @company-selected="companySelected"
          @speaker-selected="speakerSelected" show-create />

        <!-- Desktop Navigation -->
        <div class="hidden md:flex items-center space-x-4">
            <!-- Notifications -->
            <Popover>
            <PopoverTrigger>
              <button class="p-2 rounded hover:bg-gray-100" :title="'Notifications'">
              <Bell class="h-5 w-5 text-gray-600" />
              <span v-if="notificationsStore.items.length"
                class="absolute -top-1 -right-1 inline-flex items-center justify-center px-1.5 py-0.5 text-xs font-bold leading-none text-white bg-red-600 rounded-full">
                {{ notificationsStore.items.length }}
              </span>
              </button>
            </PopoverTrigger>

            <PopoverContent class="w-80 p-0">
              <div class="p-2 flex items-center justify-between border-b">
              <h4 class="font-semibold">Notifications</h4>
              <button v-if="notificationsStore.items.length" class="text-sm text-blue-600"
                @click="notificationsStore.removeAll()">
                Read all
              </button>
              </div>

              <div class="max-h-60 overflow-auto">
              <div v-if="notificationsStore.loading" class="p-4">Loading...</div>
              <div v-else-if="!notificationsStore.items.length" class="p-4 text-sm text-gray-500">
                No notifications
              </div>

              <ul>
                <li v-for="n in notificationsStore.items" :key="n.id"
                class="flex items-center justify-between px-3 py-2 hover:bg-gray-50 cursor-pointer"
                @click="navigateNotification(n)">
                <div class="flex items-center gap-3">
                  <img v-if="n.actor && n.actor.avatar" :src="n.actor.avatar" alt="actor"
                  class="h-8 w-8 rounded-full object-cover" />
                  <div class="text-sm">
                  <div class="font-medium">{{ n.message || n.kind }}</div>
                  <div class="text-xs text-gray-500">{{ n.actor?.name || n.date }}</div>
                  </div>
                </div>
                <div>
                  <button class="text-red-500 text-sm" @click.stop.prevent="notificationsStore.remove(n.id)">
                  <Trash :size="16" />
                  </button>
                </div>
                </li>
              </ul>
              </div>
            </PopoverContent>
            </Popover>
          <RouterLink v-for="item in navigation" :key="item.name" :to="item.to"
            class="text-gray-600 hover:text-gray-900" :title="item.name">
            <component v-if="item.icon" :is="item.icon" class="h-5 w-5" />
            <span v-else>{{ item.name }}</span>
          </RouterLink>

          <Button variant="ghost" size="sm" @click="logout" class="text-gray-600 hover:text-gray-900">
            <LogOut class="h-4 w-4" />
          </Button>
        </div>

        <!-- Mobile Navigation Button -->
        <div class="md:hidden">
          <Button variant="ghost" @click="isOpen = !isOpen">
            <Menu v-if="!isOpen" class="h-6 w-6" />
            <X v-else class="h-6 w-6" />
          </Button>
        </div>
      </nav>

      <!-- Mobile Navigation Menu -->
      <div v-if="isOpen" class="md:hidden absolute top-full left-0 w-full bg-white border-b border-gray-200 py-4">
        <CompanyOrSpeakerAutocompleteWithDialog class="w-full px-3 pb-3" placeholder="Search"
          @company-selected="companySelected" @speaker-selected="speakerSelected" />

        <div class="container mx-auto px-4">
          <div class="flex flex-col space-y-4">
            <RouterLink v-for="item in navigation" :key="item.name" :to="item.to"
              class="text-gray-600 hover:text-gray-900 flex items-center gap-2">
              <component v-if="item.icon" :is="item.icon" class="h-4 w-4" />
              <span>{{ item.name }}</span>
            </RouterLink>

            <Button variant="ghost" size="sm" @click="logout"
              class="text-gray-600 hover:text-gray-900 justify-start p-0">
              <LogOut class="h-4 w-4 mr-2" />
              Logout
            </Button>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
