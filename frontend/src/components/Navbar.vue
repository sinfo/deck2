<script setup lang="ts">
import { computed, ref, watch, type FunctionalComponent } from "vue";
import {
  Menu,
  X,
  LogOut,
  Settings,
  Trophy,
  ChevronDown,
  Mail,
} from "lucide-vue-next";
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
import CompanyOrSpeakerAutocompleteWithDialog from "./CompanyOrSpeakerOrMemberAutocompleteWithDialog.vue";
import { Popover, PopoverTrigger, PopoverContent } from "./ui/popover";
import type { Company } from "@/dto/companies";
import type { Speaker } from "@/dto/speakers";
import type { Member } from "@/dto/members";
import { useMagicKeys } from "@vueuse/core";
import Notification from "./navbar/Notification.vue";

const isOpen = ref(false);
const authStore = useAuthStore();

const showCoordination = computed(() => {
  const role = authStore.decoded?.role as string | undefined;
  return role === "COORDINATOR" || role === "ADMIN";
});
const router = useRouter();

const logout = () => {
  authStore.clearToken();
  router.push({ name: "landing" });
};

interface NavigationItem {
  name: string;
  to: RouteLocationRaw;
  icon?: FunctionalComponent;
}

const navigation: NavigationItem[] = [
  { name: "Me", to: { name: "dashboard" } },
  { name: "Companies", to: { name: "companies" } },
  { name: "Speakers", to: { name: "speakers" } },
  { name: "Gmail", to: { name: "gmail-messages" }, icon: Mail },
  { name: "Leaderboard", to: { name: "leaderboard" }, icon: Trophy },
  { name: "Settings", to: { name: "settings" }, icon: Settings },
];

const coordNavigation: NavigationItem[] = [
  { name: "My Team", to: { name: "my-coordination-team" } },
  { name: "Coordination Teams", to: { name: "coordination-teams" } },
  { name: "Packages", to: { name: "event-packages" } },
  { name: "Templates", to: { name: "contract-templates" } },
];

const { data: events, isLoading: eventsLoading } = useQuery({
  key: ["events"],
  query: getAllEvents,
});

const sortedEvents = computed(() =>
  [...(events.value?.data ?? [])].sort(
    (a, b) => b.begin?.localeCompare(a.begin || "") || 0,
  ),
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

const memberSelected = (member: Member) =>
  router.push({ name: "member", params: { memberId: member.id } });

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
  <section
    class="fixed top-0 left-0 right-0 z-50 w-full flex items-center bg-white py-4 border-b border-gray-200"
  >
    <div class="container mx-auto px-4 md:px-6 lg:px-8">
      <nav class="flex items-center justify-between">
        <div class="flex items-center gap-3">
          <RouterLink :to="{ name: 'dashboard' }" class="text-2xl font-bold"
            >Deck</RouterLink
          >

          <Select v-model="eventStore.selectedEvent">
            <SelectTrigger :loading="eventsLoading">
              <SelectValue placeholder="Edition" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem
                v-for="event in sortedEvents"
                :key="event.id"
                :value="event"
              >
                {{ event.name }}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>

        <CompanyOrSpeakerAutocompleteWithDialog
          :autofocus="showSuggestions"
          :force-show-suggestions="showSuggestions"
          class="hidden md:inline w-full px-3"
          placeholder="Search"
          show-create
          @company-selected="companySelected"
          @speaker-selected="speakerSelected"
          @member-selected="memberSelected"
        />

        <!-- Desktop Navigation -->
        <div class="hidden md:flex items-center space-x-4">
          <Notification />
          <div v-if="showCoordination" class="relative group">
            <Button
              variant="ghost"
              class="text-gray-600 hover:text-gray-900 flex items-center gap-1"
            >
              Coordination
              <ChevronDown class="h-4 w-4" />
            </Button>
            <div
              class="absolute right-0 mt-2 w-44 bg-white border rounded shadow-lg invisible group-hover:visible group-hover:opacity-100 opacity-0 transition-all"
            >
              <RouterLink
                v-for="item in coordNavigation"
                :key="item.name"
                :to="item.to"
                class="block px-4 py-2 text-sm hover:bg-gray-50"
                :title="item.name"
              >
                {{ item.name }}
              </RouterLink>
            </div>
          </div>
          <RouterLink
            v-for="item in navigation"
            :key="item.name"
            :to="item.to"
            class="text-gray-600 hover:text-gray-900"
            :title="item.name"
          >
            <component :is="item.icon" v-if="item.icon" class="h-5 w-5" />
            <span v-else>{{ item.name }}</span>
          </RouterLink>

          <Button
            variant="ghost"
            size="sm"
            class="text-gray-600 hover:text-gray-900"
            @click="logout"
          >
            <LogOut class="h-4 w-4" />
          </Button>
        </div>

        <!-- Mobile Navigation Button -->
        <div class="md:hidden">
          <Notification />
          <Button variant="ghost" @click="isOpen = !isOpen">
            <Menu v-if="!isOpen" class="h-6 w-6" />
            <X v-else class="h-6 w-6" />
          </Button>
        </div>
      </nav>

      <!-- Mobile Navigation Menu -->
      <div
        v-if="isOpen"
        class="md:hidden absolute top-full left-0 w-full bg-white border-b border-gray-200 py-4"
      >
        <CompanyOrSpeakerAutocompleteWithDialog
          class="w-full px-3 pb-3"
          placeholder="Search"
          @company-selected="companySelected"
          @speaker-selected="speakerSelected"
          @member-selected="memberSelected"
        />

        <div class="container mx-auto px-4">
          <div class="flex flex-col space-y-4">
            <RouterLink
              v-for="item in navigation"
              :key="item.name"
              :to="item.to"
              class="text-gray-600 hover:text-gray-900 flex items-center gap-2"
            >
              <component :is="item.icon" v-if="item.icon" class="h-4 w-4" />
              <span>{{ item.name }}</span>
            </RouterLink>

            <div v-if="showCoordination" class="pl-3">
              <Popover>
                <PopoverTrigger as-child>
                  <div
                    class="text-gray-600 hover:text-gray-900 flex items-center gap-2 cursor-pointer"
                  >
                    <span>Coordination</span>
                    <ChevronDown class="h-4 w-4 text-gray-500" />
                  </div>
                </PopoverTrigger>

                <PopoverContent side="bottom" align="start" class="p-0 w-56">
                  <div class="flex flex-col">
                    <RouterLink
                      v-for="item in coordNavigation"
                      :key="item.name"
                      :to="item.to"
                      class="text-gray-600 hover:text-gray-900 flex items-center gap-2"
                    >
                      <component
                        :is="item.icon"
                        v-if="item.icon"
                        class="h-4 w-4"
                      />
                      <span>{{ item.name }}</span>
                    </RouterLink>
                  </div>
                </PopoverContent>
              </Popover>
            </div>

            <Button
              variant="ghost"
              size="sm"
              class="text-gray-600 hover:text-gray-900 justify-start p-0"
              @click="logout"
            >
              <LogOut class="h-4 w-4 mr-2" />
              Logout
            </Button>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>
