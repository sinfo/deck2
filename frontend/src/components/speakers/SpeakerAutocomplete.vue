<template>
  <div class="relative">
    <Label v-if="label" :for="inputId" class="text-sm font-medium pb-2">
      {{ label }}
    </Label>

    <div class="relative">
      <div class="relative">
        <!-- Speaker image (when selected) -->
        <div
          v-if="selectedSpeaker"
          class="absolute left-3 top-1/2 transform -translate-y-1/2 z-10"
        >
          <Image
            :src="
              selectedSpeaker.imgs?.internal || selectedSpeaker.imgs?.speaker
            "
            :alt="selectedSpeaker.name"
            class="w-6 h-6 rounded object-cover border"
          />
        </div>

        <!-- Clear button (when selected) -->
        <button
          v-if="selectedSpeaker"
          type="button"
          class="absolute right-3 top-1/2 transform -translate-y-1/2 z-10 text-muted-foreground hover:text-foreground"
          @click="clearSelection"
        >
          ×
        </button>

        <Input
          :id="inputId"
          v-model="searchTerm"
          :placeholder="placeholder || 'Search speakers...'"
          :class="['w-full', selectedSpeaker ? 'pl-12 pr-8' : '']"
          :disabled="disabled"
          :autofocus="props.autofocus"
          @input="handleInput"
          @blur="hideSuggestions"
        />
      </div>

      <!-- Speaker suggestions dropdown -->
      <div
        v-if="
          showSuggestions &&
          (filteredSpeakers.length > 0 ||
            isLoading ||
            (searchTerm.trim() && !isLoading))
        "
        class="absolute z-50 w-full mt-1 bg-background border border-border rounded-md shadow-lg max-h-60 overflow-auto"
        @mousedown.prevent
      >
        <!-- Loading state -->
        <div
          v-if="isLoading"
          class="px-4 py-3 text-center text-sm text-muted-foreground"
        >
          Searching speakers...
        </div>

        <!-- Results -->
        <template v-else>
          <div
            v-for="speaker in filteredSpeakers"
            :key="speaker.id"
            class="flex items-center gap-3 px-3 py-2 hover:bg-muted cursor-pointer"
            @click="selectSpeaker(speaker)"
          >
            <Image
              :src="speaker.imgs?.internal || speaker.imgs?.speaker"
              :alt="speaker.name"
              class="w-8 h-8 rounded-md object-cover border flex-shrink-0"
            />
            <div class="flex flex-col gap-1 min-w-0 flex-1">
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
          </div>
        </template>

        <!-- No results found -->
        <div
          v-if="
            !isLoading && filteredSpeakers.length === 0 && searchTerm.trim()
          "
          class="px-4 py-3 text-center text-sm text-muted-foreground flex items-center gap-2 justify-center"
        >
          No speaker found.
          <Button
            v-if="props.showCreate"
            variant="link"
            size="sm"
            class="p-0 h-auto text-sm"
            @mousedown.prevent="handleCreateSpeaker"
          >
            Create?
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import { getAllSpeakers } from "@/api/speakers";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import Image from "../Image.vue";
import type { Speaker } from "@/dto/speakers";

interface Props {
  modelValue?: string;
  label?: string;
  placeholder?: string;
  disabled?: boolean;
  eventId?: number;
  showCreate?: boolean;
  autofocus?: boolean;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  selected: [value: Speaker];
  "update:modelValue": [value: string];
  "create-speaker": [searchTerm: string];
}>();

const inputId = `speaker-autocomplete-${Math.random().toString(36).substr(2, 9)}`;
const searchTerm = ref("");
const speakers = ref<Speaker[]>([]);
const showSuggestions = ref(false);
const isLoading = ref(false);
const searchTimeout = ref<number | null>(null);
const selectedSpeaker = ref<Speaker | null>(null);

// Watch for external changes to modelValue
watch(
  () => props.modelValue,
  (newValue) => {
    if (newValue !== searchTerm.value) {
      searchTerm.value = newValue || "";
      // Clear selected speaker if the value doesn't match
      if (selectedSpeaker.value && newValue !== selectedSpeaker.value.name) {
        selectedSpeaker.value = null;
      }
    }
  },
  { immediate: true },
);

// Search functionality
const searchSpeakers = async (searchTermValue: string) => {
  if (!searchTermValue.trim()) {
    speakers.value = [];
    showSuggestions.value = false;
    return;
  }

  isLoading.value = true;

  try {
    const response = await getAllSpeakers({
      event: props.eventId,
      name: searchTermValue,
    });

    const speakersData = response.data || [];

    // Filter speakers that match or are similar to the search term
    const filteredSpeakers = speakersData.filter((speaker) =>
      speaker.name.toLowerCase().includes(searchTermValue.toLowerCase()),
    );

    speakers.value = filteredSpeakers.slice(0, 10); // Limit to 10 suggestions
    showSuggestions.value = true; // Always show suggestions when searching
  } catch (error) {
    console.error("Error searching speakers:", error);
    speakers.value = [];
    showSuggestions.value = true; // Show suggestions even on error to allow "Create Speaker"
  } finally {
    isLoading.value = false;
  }
};

const handleInput = (event: Event) => {
  const target = event.target as HTMLInputElement;
  const value = target.value;

  searchTerm.value = value;
  emit("update:modelValue", value);

  // Clear selected speaker if user is typing something different
  if (selectedSpeaker.value && value !== selectedSpeaker.value.name) {
    selectedSpeaker.value = null;
  }

  // Clear suggestions immediately if input is empty
  if (!value.trim()) {
    speakers.value = [];
    showSuggestions.value = false;
    selectedSpeaker.value = null;
    if (searchTimeout.value) {
      clearTimeout(searchTimeout.value);
    }
    return;
  }

  // Clear existing timeout
  if (searchTimeout.value) {
    clearTimeout(searchTimeout.value);
  }

  // Debounce search to avoid too many API calls
  searchTimeout.value = setTimeout(() => {
    searchSpeakers(value);
  }, 300);
};

const selectSpeaker = (speaker: Speaker) => {
  selectedSpeaker.value = speaker;
  searchTerm.value = speaker.name;
  emit("update:modelValue", speaker.name);
  emit("selected", speaker);
  showSuggestions.value = false;
};

const handleCreateSpeaker = () => {
  emit("create-speaker", searchTerm.value);
  showSuggestions.value = false;
};

const clearSelection = () => {
  selectedSpeaker.value = null;
  searchTerm.value = "";
  emit("update:modelValue", "");
  speakers.value = [];
  showSuggestions.value = false;
};

// Hide suggestions when clicking outside
const hideSuggestions = () => {
  setTimeout(() => {
    showSuggestions.value = false;
  }, 200);
};

const filteredSpeakers = computed(() => {
  return speakers.value;
});
</script>
