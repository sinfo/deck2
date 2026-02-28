<template>
  <div class="relative">
    <Label v-if="label" :for="inputId" class="text-sm font-medium pb-2">
      {{ label }}
    </Label>

    <div class="relative">
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
            <template v-for="group in orderedGroups" :key="group">
              <!-- Companies section -->
              <div v-if="group === 'companies' && filteredCompanies.length > 0">
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
              <div
                v-else-if="group === 'speakers' && filteredSpeakers.length > 0"
              >
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
              <div
                v-else-if="group === 'members' && filteredMembers.length > 0"
              >
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
import createFuzzySearch, { type FuzzyResult } from "@nozbe/microfuzz";

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
  if (typeof navigator === "undefined") return false;

  const uaData = navigator.userAgentData;
  if (uaData && typeof uaData.platform === "string") {
    return uaData.platform === "macOS";
  }

  const ua = navigator.userAgent || "";
  return /\bMacintosh\b|\bMac OS X\b/.test(ua);
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

// Members query
const { data: membersData, isLoading: membersLoading } = useQuery({
  key: () => ["members"],
  query: () => getAllMembers({}),
  enabled: () => !!eventStore.selectedEvent?.id,
});

const isLoading = computed(
  () => companiesLoading.value || speakersLoading.value || membersLoading.value,
);

/**
 * NOTE: microfuzz score semantics:
 * - Lower score = better match (exact match is ~0)
 * So we always sort scores ASC, and use Infinity for “no results”.
 */

// ----- Companies fuzzy -----
const companyFuzzy = ref<null | ((q: string) => FuzzyResult<Company>[])>(null);
watch(
  () => companiesData.value?.data,
  (list) => {
    if (!list || !list.length) {
      companyFuzzy.value = null;
    } else {
      companyFuzzy.value = createFuzzySearch(list, {
        getText: (company: Company) => [
          company.name,
          company.description ?? "",
        ],
      });
    }
  },
  { immediate: true },
);

// ----- Speakers fuzzy -----
const speakerFuzzy = ref<null | ((q: string) => FuzzyResult<Speaker>[])>(null);
watch(
  () => speakersData.value?.data,
  (list) => {
    if (!list || !list.length) {
      speakerFuzzy.value = null;
    } else {
      speakerFuzzy.value = createFuzzySearch(list, {
        getText: (speaker: Speaker) => [
          speaker.name,
          speaker.companyName ?? "",
        ],
      });
    }
  },
  { immediate: true },
);

// ----- Members fuzzy (NEW) -----
const memberFuzzy = ref<null | ((q: string) => FuzzyResult<Member>[])>(null);
watch(
  () => membersData.value?.data,
  (list) => {
    if (!list || !list.length) {
      memberFuzzy.value = null;
    } else {
      memberFuzzy.value = createFuzzySearch(list, {
        getText: (member: Member) => [member.name],
      });
    }
  },
  { immediate: true },
);

// Raw fuzzy results (item + score) for current term
const companyResults = computed<FuzzyResult<Company>[]>(() => {
  const term = searchTerm.value.trim();
  const fuzzy = companyFuzzy.value;
  if (!term || !fuzzy) return [];
  return fuzzy(term);
});

const speakerResults = computed<FuzzyResult<Speaker>[]>(() => {
  const term = searchTerm.value.trim();
  const fuzzy = speakerFuzzy.value;
  if (!term || !fuzzy) return [];
  return fuzzy(term);
});

const memberResults = computed<FuzzyResult<Member>[]>(() => {
  const term = searchTerm.value.trim();
  const fuzzy = memberFuzzy.value;
  if (!term || !fuzzy) return [];
  return fuzzy(term);
});

// Visible lists (limit to 5)
const filteredCompanies = computed<Company[]>(() => {
  const list = companiesData.value?.data ?? [];
  const term = searchTerm.value.trim();

  if (!term) return list.slice(0, 5);
  return companyResults.value.map((res) => res.item).slice(0, 5);
});

const filteredSpeakers = computed<Speaker[]>(() => {
  const list = speakersData.value?.data ?? [];
  const term = searchTerm.value.trim();

  if (!term) return list.slice(0, 5);
  return speakerResults.value.map((res) => res.item).slice(0, 5);
});

const filteredMembers = computed<Member[]>(() => {
  const list = membersData.value?.data ?? [];
  const term = searchTerm.value.trim();

  if (!term) return list.slice(0, 5);
  return memberResults.value.map((res) => res.item).slice(0, 5);
});

// Best scores for ordering groups (lower = better, Infinity = “no match”)
const bestCompanyScore = computed(
  () => companyResults.value[0]?.score ?? Infinity,
);
const bestSpeakerScore = computed(
  () => speakerResults.value[0]?.score ?? Infinity,
);
const bestMemberScore = computed(
  () => memberResults.value[0]?.score ?? Infinity,
);

type GroupId = "companies" | "speakers" | "members";

const orderedGroups = computed<GroupId[]>(() => {
  const term = searchTerm.value.trim();
  const baseOrder: GroupId[] = ["companies", "speakers", "members"];

  if (!term) {
    // No search term: keep existing visual order
    return baseOrder;
  }

  const entries: { id: GroupId; score: number }[] = [
    { id: "companies", score: bestCompanyScore.value },
    { id: "speakers", score: bestSpeakerScore.value },
    { id: "members", score: bestMemberScore.value },
  ];

  // Sort by score ASC; tie-breaker = baseOrder stability
  entries.sort((a, b) => {
    if (a.score === b.score) {
      return baseOrder.indexOf(a.id) - baseOrder.indexOf(b.id);
    }
    return a.score - b.score;
  });

  // Only keep groups that have something to show
  return entries
    .filter((entry) => {
      if (entry.id === "companies") return filteredCompanies.value.length > 0;
      if (entry.id === "speakers") return filteredSpeakers.value.length > 0;
      if (entry.id === "members") return filteredMembers.value.length > 0;
      return false;
    })
    .map((entry) => entry.id);
});

const results = computed(() => {
  const out: Array<
    (Company | Speaker | Member) & { type: "company" | "speaker" | "member" }
  > = [];

  for (const group of orderedGroups.value) {
    if (group === "companies") {
      out.push(
        ...filteredCompanies.value.map((company) => ({
          ...company,
          type: "company" as const,
        })),
      );
    } else if (group === "speakers") {
      out.push(
        ...filteredSpeakers.value.map((speaker) => ({
          ...speaker,
          type: "speaker" as const,
        })),
      );
    } else if (group === "members") {
      out.push(
        ...filteredMembers.value.map((member) => ({
          ...member,
          type: "member" as const,
        })),
      );
    }
  }

  return out;
});

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
    const input = event.target as HTMLInputElement;
    if (input) input.blur();
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
  setTimeout(() => {
    showSuggestions.value = false;
    highlightedIndex.value = -1;
  }, 200);
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
      nextTick(() => {
        const input = document.getElementById(
          inputId.value,
        ) as HTMLInputElement;
        if (input) input.focus();
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
