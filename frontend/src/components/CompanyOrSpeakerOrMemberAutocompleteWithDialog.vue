<template>
  <div class="relative">
    <Label v-if="label" :for="inputId" class="text-sm font-medium pb-2">
      {{ label }}
    </Label>

    <div class="relative">
      <div class="relative">
        <!-- Selected item image (when selected) -->
        <div
          v-if="selectedItem"
          class="absolute left-3 top-1/2 transform -translate-y-1/2 z-10"
        >
          <Image
            :src="getItemImage(selectedItem)"
            :alt="selectedItem.name"
            class="w-6 h-6 rounded object-cover border"
          />
        </div>

        <!-- Clear button (when selected) -->
        <button
          v-if="selectedItem"
          type="button"
          class="absolute right-3 top-1/2 transform -translate-y-1/2 z-10 text-muted-foreground hover:text-foreground"
          @click="clearSelection"
        >
          ×
        </button>

        <!-- Keyboard shortcut badge (when empty and not focused) -->
        <div
          class="absolute right-3 top-1/2 transform -translate-y-1/2 z-10 pointer-events-none"
        >
          <Badge variant="secondary" class="text-xs flex items-center gap-1">
            <span class="font-mono">{{ isMac ? "⌘" : "Ctrl" }}</span>
            <span class="font-mono">+ K</span>
          </Badge>
        </div>

        <Input
          :id="inputId"
          ref="inputRef"
          v-model="searchTerm"
          :placeholder="placeholder || 'Search companies or speakers...'"
          :class="['w-full', selectedItem ? 'pl-12 pr-8' : '']"
          :disabled="disabled"
          :autofocus="props.autofocus"
          @input="handleInput"
          @blur="hideSuggestions"
          @focus="handleFocus"
          @keydown="handleKeydown"
        />
      </div>

      <!-- Results dropdown -->
      <div
        v-if="
          forceShowSuggestions ||
          (showSuggestions &&
            (results.length > 0 || isLoading || (searchTerm && showCreate)))
        "
        class="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-md shadow-lg overflow-y-auto"
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
          <!-- Companies section -->
          <div v-if="filteredCompanies.length > 0">
            <div
              class="px-3 py-2 text-xs font-semibold text-gray-500 bg-gray-50 border-b"
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
              @click="selectCompany(company)"
            >
              <Image
                :src="company.imgs?.internal || company.imgs?.public"
                :alt="company.name"
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
          <div v-if="filteredSpeakers.length > 0">
            <div
              class="px-3 py-2 text-xs font-semibold text-gray-500 bg-gray-50 border-b"
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
              @click="selectSpeaker(speaker)"
            >
              <Image
                :src="speaker.imgs?.internal || speaker.imgs?.speaker"
                :alt="speaker.name"
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
          <div v-if="filteredMembers.length > 0">
            <div
              class="px-3 py-2 text-xs font-semibold text-gray-500 bg-gray-50 border-b"
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
              @click="selectMember(member)"
            >
              <Image
                :src="member.img"
                :alt="member.name"
                class="w-8 h-8 rounded object-cover border flex-shrink-0"
              />
              <div class="flex-1 min-w-0">
                <div class="font-medium text-gray-900 truncate">
                  {{ member.name }}
                </div>
              </div>
            </button>
          </div>

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
          <div v-if="showCreate">
            <div class="border-t border-gray-200">
              <button
                type="button"
                class="w-full text-left px-3 py-2 hover:bg-gray-50 text-blue-600 font-medium"
                @click="handleCreateCompany(searchTerm)"
              >
                Create company "{{ searchTerm }}"
              </button>
              <button
                type="button"
                class="w-full text-left px-3 py-2 hover:bg-gray-50 text-blue-600 font-medium border-t border-gray-100"
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

<script setup lang="ts">
import { ref, computed, watch, nextTick } from "vue";
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
const showSuggestions = ref(false);
const selectedItem = ref<SelectedItem | null>(null);
const isCompanyDialogOpen = ref(false);
const isSpeakerDialogOpen = ref(false);
const createTerm = ref("");
const inputRef = ref<HTMLInputElement>();
const highlightedIndex = ref(-1);

// Detect platform for keyboard shortcut
const isMac = computed(() => {
  return (
    typeof navigator !== "undefined" &&
    navigator.platform.toUpperCase().indexOf("MAC") >= 0
  );
});

// Companies query
const { data: companiesData, isLoading: companiesLoading } = useQuery({
  key: () => ["companies"],
  query: () => getAllCompanies({}),
  enabled: () => !!eventStore.selectedEvent?.id,
});

// Speakers query
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

const filteredCompanies = computed(() => {
  if (!companiesData.value?.data) return [];

  const term = searchTerm.value.toLowerCase();

  if (!term) {
    // Show recent companies when no search term
    return companiesData.value.data.slice(0, 5);
  }

  return companiesData.value.data
    .filter(
      (company: Company) =>
        company.name.toLowerCase().includes(term) ||
        company.description?.toLowerCase().includes(term),
    )
    .slice(0, 5); // Limit to 5 results
});

const filteredSpeakers = computed(() => {
  if (!speakersData.value?.data) return [];

  const term = searchTerm.value.toLowerCase();

  if (!term) {
    // Show recent speakers when no search term
    return speakersData.value.data.slice(0, 5);
  }

  return speakersData.value.data
    .filter(
      (speaker: Speaker) =>
        speaker.name.toLowerCase().includes(term) ||
        speaker.companyName?.toLowerCase().includes(term),
    )
    .slice(0, 5); // Limit to 5 results
});

const filteredMembers = computed(() => {
  if (!membersData.value?.data) return [];

  const term = searchTerm.value.toLowerCase();

  if (!term) {
    // Show recent members when no search term
    return membersData.value.data.slice(0, 5);
  }

  return membersData.value.data
    .filter((member: Member) => member.name.toLowerCase().includes(term))
    .slice(0, 5);
});

const results = computed(() => [
  ...filteredCompanies.value.map((company: Company) => ({
    ...company,
    type: "company",
  })),
  ...filteredSpeakers.value.map((speaker: Speaker) => ({
    ...speaker,
    type: "speaker",
  })),
  ...filteredMembers.value.map((member: Member) => ({
    ...member,
    type: "member",
  })),
]);

const getItemIndex = (item: SelectedItem) => {
  return results.value.findIndex((result) => result.id === item.id);
};

const getItemImage = (item: SelectedItem) => {
  if ("imgs" in item && item.imgs) {
    if ("public" in item.imgs) {
      // Company
      return item.imgs.internal || item.imgs.public;
    } else {
      // Speaker
      return item.imgs.internal || item.imgs.speaker;
    }
  }

  // Member may have an `img` property
  if ((item as Member).img) return (item as Member).img;

  return "";
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

const handleKeydown = (event: KeyboardEvent) => {
  if (event.key === "Escape") {
    showSuggestions.value = false;
    highlightedIndex.value = -1;
    // Also blur the input to remove focus
    const input = event.target as HTMLInputElement;
    if (input) {
      input.blur();
    }
  } else if (event.key === "ArrowDown") {
    event.preventDefault();
    if (results.value.length > 0) {
      highlightedIndex.value = Math.min(
        highlightedIndex.value + 1,
        results.value.length - 1,
      );
    }
  } else if (event.key === "ArrowUp") {
    event.preventDefault();
    if (results.value.length > 0) {
      highlightedIndex.value = Math.max(highlightedIndex.value - 1, -1);
    }
  } else if (event.key === "Enter") {
    event.preventDefault();
    if (
      highlightedIndex.value >= 0 &&
      highlightedIndex.value < results.value.length
    ) {
      const selectedResult = results.value[highlightedIndex.value];
      if (selectedResult.type === "speaker") {
        selectSpeaker(selectedResult as Speaker);
      } else if (selectedResult.type === "member") {
        selectMember(selectedResult as Member);
      } else if (selectedResult.type === "company") {
        selectCompany(selectedResult as Company);
      }
    }
  }
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

const clearSelection = () => {
  selectedItem.value = null;
  searchTerm.value = "";
  highlightedIndex.value = -1;
  emit("update:modelValue", "");
  showSuggestions.value = false;
};

const hideSuggestions = () => {
  // Delay hiding to allow for click events
  setTimeout(() => {
    showSuggestions.value = false;
    highlightedIndex.value = -1;
  }, 200);
};

const handleCreateCompany = (term: string) => {
  createTerm.value = term;
  isCompanyDialogOpen.value = true;
  showSuggestions.value = false;
};

const handleCreateSpeaker = (term: string) => {
  createTerm.value = term;
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

// Watch for external changes to modelValue
watch(
  () => props.modelValue,
  (newValue) => {
    if (newValue !== searchTerm.value) {
      searchTerm.value = newValue || "";
    }
  },
);

// Watch for forceShowSuggestions to focus input and show suggestions
watch(
  () => props.forceShowSuggestions,
  (newValue) => {
    if (newValue) {
      showSuggestions.value = true;
      highlightedIndex.value = -1;
      // Focus the input when force show suggestions is triggered
      nextTick(() => {
        const input = document.getElementById(
          inputId.value,
        ) as HTMLInputElement;
        if (input) {
          input.focus();
        }
      });
    }
  },
);

// Reset highlighted index when results change
watch(
  () => results.value.length,
  () => {
    highlightedIndex.value = -1;
  },
);
</script>
