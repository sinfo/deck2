<template>
  <div class="relative">
    <Label v-if="label" :for="inputId" class="text-sm font-medium pb-2">
      {{ label }}
    </Label>

    <div class="relative">
      <!-- Selected item image (when selected) -->
      <div
        v-if="selectedItem"
        class="absolute left-3 top-1/2 transform -translate-y-1/2 z-10"
      >
        <Image
          :alt="selectedItem.name"
          :src="getItemImage(selectedItem)"
          class="w-6 h-6 rounded object-cover border"
        />
      </div>

      <!-- Clear button (when selected) -->
      <button
        v-if="selectedItem"
        class="absolute right-3 top-1/2 transform -translate-y-1/2 z-10 text-muted-foreground hover:text-foreground"
        type="button"
        @click="clearSelection"
      >
        ×
      </button>

      <!-- Keyboard shortcut badge (when empty and not focused) -->
      <div
        v-if="!selectedItem"
        class="absolute right-3 top-1/2 transform -translate-y-1/2 z-10 pointer-events-none hidden sm:block"
      >
        <Badge class="text-xs flex items-center gap-1" variant="secondary">
          <span class="font-mono">{{ isMac ? "⌘" : "Ctrl" }}</span>
          <span class="font-mono">+ K</span>
        </Badge>
      </div>

      <Input
        :id="inputId"
        ref="inputRef"
        v-model="searchTerm"
        :autofocus="props.autofocus"
        :class="['w-full', selectedItem ? 'pl-12 pr-8' : '']"
        :disabled="disabled"
        :placeholder="placeholder || 'Search companies or speakers...'"
        @blur="hideSuggestions"
        @focus="handleFocus"
        @input="handleInput"
        @keydown="handleKeydown"
      />

      <!-- Results dropdown -->
      <div
        v-if="
          forceShowSuggestions ||
          (showSuggestions &&
            (results.length > 0 || isLoading || (searchTerm && showCreate)))
        "
        ref="listRef"
        aria-label="Search results for companies, speakers, and members"
        class="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-md shadow-lg overflow-y-auto overscroll-contain touch-pan-y max-h-[65vh] sm:max-h-[24rem]"
        role="listbox"
        tabindex="-1"
      >
        <!-- Loading state -->
        <div v-if="isLoading" class="p-3 text-center text-gray-500">
          <div
            class="inline-block w-4 h-4 border-2 border-gray-300 border-t-blue-500 rounded-full animate-spin"
          ></div>
          <span class="ml-2">Searching...</span>
        </div>

        <!-- Results -->
        <div v-else>
          <template v-for="group in orderedGroups" :key="group">
            <!-- Companies section -->
            <div v-if="group === 'companies' && filteredCompanies.length > 0">
              <div
                class="px-3 py-2 text-xs font-semibold text-gray-500 bg-gray-50 border-b sticky top-0 z-10"
              >
                Companies
              </div>
              <button
                v-for="company in filteredCompanies"
                :key="`company-${company.id}`"
                type="button"
                :class="[
                  'w-full text-left px-3 py-2 border-b border-gray-100 last:border-b-0 flex items-center gap-3',
                  getItemIndex(company) === highlightedIndex
                    ? 'bg-blue-50 border-blue-200'
                    : 'hover:bg-gray-50',
                ]"
                :data-result-index="getItemIndex(company)"
                role="option"
                :aria-selected="getItemIndex(company) === highlightedIndex"
                @click="selectCompany(company)"
              >
                <Image
                  :alt="company.name"
                  :src="company.imgs?.internal || company.imgs?.public"
                  class="w-8 h-8 rounded object-cover border flex-shrink-0"
                />
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-gray-900 truncate">
                    {{ company.name }}
                  </div>
                  <div
                    v-if="company.description"
                    class="text-sm text-gray-500 truncate"
                  >
                    {{ company.description }}
                  </div>
                </div>
              </button>
            </div>

            <!-- Speakers section -->
            <div
              v-else-if="group === 'speakers' && filteredSpeakers.length > 0"
            >
              <div
                class="px-3 py-2 text-xs font-semibold text-gray-500 bg-gray-50 border-b sticky top-0 z-10"
              >
                Speakers
              </div>
              <button
                v-for="speaker in filteredSpeakers"
                :key="`speaker-${speaker.id}`"
                type="button"
                :class="[
                  'w-full text-left px-3 py-2 border-b border-gray-100 last:border-b-0 flex items-center gap-3',
                  getItemIndex(speaker) === highlightedIndex
                    ? 'bg-blue-50 border-blue-200'
                    : 'hover:bg-gray-50',
                ]"
                :data-result-index="getItemIndex(speaker)"
                role="option"
                :aria-selected="getItemIndex(speaker) === highlightedIndex"
                @click="selectSpeaker(speaker)"
              >
                <Image
                  :alt="speaker.name"
                  :src="speaker.imgs?.internal || speaker.imgs?.speaker"
                  class="w-8 h-8 rounded object-cover border flex-shrink-0"
                />
                <div class="flex-1 min-w-0">
                  <span class="font-medium truncate">{{ speaker.name }}</span>
                  <div
                    class="flex items-center gap-2 text-xs text-muted-foreground"
                  >
                    <span v-if="speaker.title" class="truncate">
                      {{ speaker.title }}
                    </span>
                    <span v-if="speaker.title && speaker.companyName">•</span>
                    <span v-if="speaker.companyName" class="truncate">
                      {{ speaker.companyName }}
                    </span>
                  </div>
                </div>
              </button>
            </div>

            <!-- Members section -->
            <div v-else-if="group === 'members' && filteredMembers.length > 0">
              <div
                class="px-3 py-2 text-xs font-semibold text-gray-500 bg-gray-50 border-b sticky top-0 z-10"
              >
                Members
              </div>
              <button
                v-for="member in filteredMembers"
                :key="`member-${member.id}`"
                type="button"
                :class="[
                  'w-full text-left px-3 py-2 border-b border-gray-100 last:border-b-0 flex items-center gap-3',
                  getItemIndex(member) === highlightedIndex
                    ? 'bg-blue-50 border-blue-200'
                    : 'hover:bg-gray-50',
                ]"
                :data-result-index="getItemIndex(member)"
                role="option"
                :aria-selected="getItemIndex(member) === highlightedIndex"
                @click="selectMember(member)"
              >
                <Image
                  :alt="member.name"
                  :src="member.img"
                  class="w-8 h-8 rounded object-cover border flex-shrink-0"
                />
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-gray-900 truncate">
                    {{ member.name }}
                  </div>
                </div>
              </button>
            </div>
          </template>

          <!-- No results -->
          <div
            v-if="
              !isLoading &&
              filteredCompanies.length === 0 &&
              filteredSpeakers.length === 0 &&
              filteredMembers.length === 0 &&
              searchTerm.trim()
            "
            class="p-3 text-gray-500 text-center"
          >
            No companies, speakers or members found
          </div>

          <!-- Welcome message when no search term -->
          <div
            v-if="
              !isLoading &&
              !searchTerm.trim() &&
              filteredCompanies.length === 0 &&
              filteredSpeakers.length === 0 &&
              filteredMembers.length === 0
            "
            class="p-3 text-gray-500 text-center"
          >
            Start typing to search companies, speakers and members...
          </div>

          <!-- Create options -->
          <div v-if="showCreate && searchTerm.trim()">
            <div class="border-t border-gray-200">
              <button
                class="w-full text-left px-3 py-2 hover:bg-gray-50 text-blue-600 font-medium"
                type="button"
                @click="handleCreateCompany(searchTerm)"
              >
                Create company "{{ searchTerm }}"
              </button>
              <button
                class="w-full text-left px-3 py-2 hover:bg-gray-50 text-blue-600 font-medium border-t border-gray-100"
                type="button"
                @click="handleCreateSpeaker(searchTerm)"
              >
                Create speaker "{{ searchTerm }}"
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Create Company Dialog -->
    <Teleport to="body">
      <AlertDialog v-model:open="isCompanyDialogOpen">
        <AlertDialogContent
          class="max-w-2xl max-h-[90vh] overflow-hidden flex flex-col"
        >
          <AlertDialogHeader class="flex-shrink-0">
            <AlertDialogTitle>Create New Company</AlertDialogTitle>
            <AlertDialogDescription>
              Fill out the information below to create a new company.
            </AlertDialogDescription>
          </AlertDialogHeader>

          <div class="flex-1 overflow-y-auto min-h-0">
            <CreateCompanyForm
              :initial-company-name="createTerm"
              @cancel="handleCompanyCancel"
              @success="handleCompanySuccess"
            />
          </div>
        </AlertDialogContent>
      </AlertDialog>
    </Teleport>

    <!-- Create Speaker Dialog -->
    <Teleport to="body">
      <AlertDialog v-model:open="isSpeakerDialogOpen">
        <AlertDialogContent
          class="max-w-2xl max-h-[90vh] overflow-hidden flex flex-col"
        >
          <AlertDialogHeader class="flex-shrink-0">
            <AlertDialogTitle>Create New Speaker</AlertDialogTitle>
            <AlertDialogDescription>
              Fill out the information below to create a new speaker.
            </AlertDialogDescription>
          </AlertDialogHeader>

          <div class="flex-1 overflow-y-auto min-h-0">
            <CreateSpeakerForm
              :initial-speaker-name="createTerm"
              @cancel="handleSpeakerCancel"
              @success="handleSpeakerSuccess"
            />
          </div>
        </AlertDialogContent>
      </AlertDialog>
    </Teleport>
  </div>
</template>

<script lang="ts" setup>
import { ref, computed, watch, nextTick, onBeforeUnmount } from "vue";
import { useQuery } from "@pinia/colada";
import { getAllCompanies } from "@/api/companies";
import { getAllSpeakers } from "@/api/speakers";
import { getAllMembers } from "@/api/members";
import { useEventStore } from "@/stores/event";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import Image from "@/components/Image.vue";
import CreateCompanyForm from "@/components/companies/CreateCompanyForm.vue";
import CreateSpeakerForm from "@/components/speakers/CreateSpeakerForm.vue";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import type { Company } from "@/dto/companies";
import type { Speaker } from "@/dto/speakers";
import type { Member } from "@/dto/members";
import {
  useCompanySpeakerMemberSearch,
  type ResultItem,
} from "@/composables/useCompanySpeakerMemberSearch";

type SelectedItem = Company | Speaker | Member;

interface Props {
  modelValue?: string;
  label?: string;
  placeholder?: string;
  disabled?: boolean;
  eventId?: number;
  showCreate?: boolean;
  autofocus?: boolean;
  forceShowSuggestions?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  showCreate: false,
  autofocus: false,
  modelValue: undefined,
  label: undefined,
  placeholder: undefined,
  eventId: undefined,
});

const emit = defineEmits<{
  companySelected: [value: Company];
  speakerSelected: [value: Speaker];
  memberSelected: [value: Member];
  "update:modelValue": [value: string];
  companySuccess: [companyId: string];
  speakerSuccess: [speakerId: string];
}>();

const eventStore = useEventStore();

const inputId = ref(`company-speaker-autocomplete-${Math.random()}`);
const searchTerm = ref(props.modelValue || "");
const createTerm = ref("");
const showSuggestions = ref(false);
const selectedItem = ref<SelectedItem | null>(null);
const isCompanyDialogOpen = ref(false);
const isSpeakerDialogOpen = ref(false);
const listRef = ref<HTMLElement | null>(null);
const scrollAnimationFrameId = ref<number | null>(null);
const inputRef = ref<HTMLInputElement>();
const highlightedIndex = ref(-1);

// Detect platform for keyboard shortcut display
const isMac = computed(() => {
  if (typeof navigator === "undefined") return false;

  const uaData = navigator.userAgentData;
  if (uaData && typeof uaData.platform === "string") {
    return uaData.platform === "macOS";
  }

  const ua = navigator.userAgent || "";
  return /\bMacintosh\b|\bMac OS X\b/.test(ua);
});

const { data: companiesData, isLoading: companiesLoading } = useQuery({
  key: () => ["companies"],
  query: () => getAllCompanies({}),
  enabled: () => !!eventStore.selectedEvent?.id,
});

const { data: speakersData, isLoading: speakersLoading } = useQuery({
  key: () => ["speakers"],
  query: () => getAllSpeakers({}),
  enabled: () => !!eventStore.selectedEvent?.id,
});

const { data: membersData, isLoading: membersLoading } = useQuery({
  key: () => ["members"],
  query: () => getAllMembers({}),
  enabled: () => !!eventStore.selectedEvent?.id,
});

const isLoading = computed(
  () => companiesLoading.value || speakersLoading.value || membersLoading.value,
);

const companies = computed(() => companiesData.value?.data ?? []);
const speakers = computed(() => speakersData.value?.data ?? []);
const members = computed(() => membersData.value?.data ?? []);

const {
  filteredCompanies,
  filteredSpeakers,
  filteredMembers,
  orderedGroups,
  results,
  getItemIndex,
} = useCompanySpeakerMemberSearch({
  searchTerm,
  companies,
  speakers,
  members,
  limit: 5,
  memberBias: 0.15,
});

const getItemImage = (item: SelectedItem): string => {
  if ("imgs" in item && item.imgs) {
    if ("public" in item.imgs) {
      // Company: prefer internal, fall back to public
      return item.imgs.internal || item.imgs.public;
    } else {
      // Speaker: prefer internal, fall back to speaker
      return item.imgs.internal || item.imgs.speaker;
    }
  }

  return (item as Member).img ?? "";
};

const handleInput = () => {
  emit("update:modelValue", searchTerm.value);
  showSuggestions.value = true;
  selectedItem.value = null;
  highlightedIndex.value = -1;
};

const handleFocus = () => {
  showSuggestions.value = true;
  highlightedIndex.value = -1;
};

const hideSuggestions = () => {
  // Delay hiding to allow click events to fire first
  setTimeout(() => {
    showSuggestions.value = false;
    highlightedIndex.value = -1;
  }, 200);
};

const clearSelection = () => {
  selectedItem.value = null;
  searchTerm.value = "";
  highlightedIndex.value = -1;
  emit("update:modelValue", "");
  showSuggestions.value = false;
};

const selectCompany = (company: Company) => {
  selectedItem.value = company;
  searchTerm.value = company.name;
  showSuggestions.value = false;
  highlightedIndex.value = -1;
  emit("companySelected", company);
  emit("update:modelValue", company.name);
};

const selectSpeaker = (speaker: Speaker) => {
  selectedItem.value = speaker;
  searchTerm.value = speaker.name;
  showSuggestions.value = false;
  highlightedIndex.value = -1;
  emit("speakerSelected", speaker);
  emit("update:modelValue", speaker.name);
};

const selectMember = (member: Member) => {
  selectedItem.value = member;
  searchTerm.value = member.name;
  showSuggestions.value = false;
  highlightedIndex.value = -1;
  emit("memberSelected", member);
  emit("update:modelValue", member.name);
};

const handleKeydown = (event: KeyboardEvent) => {
  const { key } = event;
  const list = results.value;
  const hasResults = list.length > 0;
  const maxIndex = list.length - 1;

  const normalizeIndex = (value: number) =>
    Math.min(Math.max(value, -1), maxIndex);

  const setHighlighted = (nextIndex: number) => {
    highlightedIndex.value = normalizeIndex(nextIndex);
  };

  const closeSuggestions = () => {
    showSuggestions.value = false;
    highlightedIndex.value = -1;
    (event.target as HTMLInputElement).blur();
  };

  const selectResult = (item: ResultItem) => {
    switch (item.type) {
      case "speaker":
        return selectSpeaker(item);
      case "member":
        return selectMember(item);
      case "company":
        return selectCompany(item);
    }
  };

  switch (key) {
    case "Escape": {
      closeSuggestions();
      return;
    }

    case "ArrowDown":
    case "ArrowUp": {
      event.preventDefault();
      if (!hasResults) return;
      const delta = key === "ArrowDown" ? 1 : -1;
      setHighlighted(highlightedIndex.value + delta);
      return;
    }

    case "Enter": {
      event.preventDefault();
      if (!hasResults) return;
      // If nothing is highlighted, select the first item
      const idx = highlightedIndex.value >= 0 ? highlightedIndex.value : 0;
      selectResult(list[idx]);
      highlightedIndex.value = idx;
      return;
    }

    default:
      return;
  }
};

const handleCreateCompany = (term: string) => {
  createTerm.value = term.trim();
  isCompanyDialogOpen.value = true;
  showSuggestions.value = false;
};

const handleCreateSpeaker = (term: string) => {
  createTerm.value = term.trim();
  isSpeakerDialogOpen.value = true;
  showSuggestions.value = false;
};

const handleCompanyCancel = () => {
  isCompanyDialogOpen.value = false;
  createTerm.value = "";
};

const handleCompanySuccess = (companyId: string) => {
  isCompanyDialogOpen.value = false;
  createTerm.value = "";
  emit("companySuccess", companyId);
};

const handleSpeakerCancel = () => {
  isSpeakerDialogOpen.value = false;
  createTerm.value = "";
};

const handleSpeakerSuccess = (speakerId: string) => {
  isSpeakerDialogOpen.value = false;
  createTerm.value = "";
  emit("speakerSuccess", speakerId);
};

// Sync internal searchTerm when modelValue changes externally
watch(
  () => props.modelValue,
  (newValue) => {
    if (newValue !== searchTerm.value) {
      searchTerm.value = newValue || "";
    }
  },
);

// Focus input and show suggestions when forceShowSuggestions is triggered
watch(
  () => props.forceShowSuggestions,
  (newValue) => {
    if (!newValue) return;
    showSuggestions.value = true;
    highlightedIndex.value = -1;
    nextTick(() => {
      const input = document.getElementById(inputId.value) as HTMLInputElement;
      input?.focus();
    });
  },
);

// Reset highlighted index whenever the result list changes size
watch(
  () => results.value.length,
  () => {
    highlightedIndex.value = -1;
  },
);

// Scroll highlighted item into view
watch(
  () => highlightedIndex.value,
  (idx) => {
    const container = listRef.value;
    if (!container || idx < 0) return;

    if (scrollAnimationFrameId.value !== null) {
      cancelAnimationFrame(scrollAnimationFrameId.value);
      scrollAnimationFrameId.value = null;
    }

    scrollAnimationFrameId.value = requestAnimationFrame(() => {
      const el = container.querySelector(
        `[data-result-index="${idx}"]`,
      ) as HTMLElement | null;

      if (!el) return;

      const elTop = el.offsetTop;
      const elBottom = elTop + el.offsetHeight;
      const viewTop = container.scrollTop;
      const viewBottom = viewTop + container.clientHeight;

      if (elTop < viewTop) {
        container.scrollTop = elTop;
      } else if (elBottom > viewBottom) {
        container.scrollTop = elBottom - container.clientHeight;
      }
    });
  },
);

onBeforeUnmount(() => {
  if (scrollAnimationFrameId.value !== null) {
    cancelAnimationFrame(scrollAnimationFrameId.value);
    scrollAnimationFrameId.value = null;
  }
});
</script>
