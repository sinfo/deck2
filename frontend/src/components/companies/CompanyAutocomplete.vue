<template>
  <div class="relative">
    <Label v-if="label" :for="inputId" class="text-sm font-medium pb-2">
      {{ label }}
    </Label>

    <div class="relative">
      <div class="relative">
        <!-- Company image (when selected) -->
        <div
          v-if="selectedCompany"
          class="absolute left-3 top-1/2 transform -translate-y-1/2 z-10"
        >
          <Image
            :src="
              selectedCompany.imgs?.internal || selectedCompany.imgs?.public
            "
            :alt="selectedCompany.name"
            class="w-6 h-6 rounded object-cover border"
          />
        </div>

        <!-- Clear button (when selected) -->
        <button
          v-if="selectedCompany"
          type="button"
          class="absolute right-3 top-1/2 transform -translate-y-1/2 z-10 text-muted-foreground hover:text-foreground"
          @click="clearSelection"
        >
          ×
        </button>

        <Input
          :id="inputId"
          v-model="searchTerm"
          :placeholder="placeholder || 'Search companies...'"
          :class="['w-full', selectedCompany ? 'pl-12 pr-8' : '']"
          :disabled="disabled"
          :autofocus="props.autofocus"
          @input="handleInput"
          @blur="hideSuggestions"
        />
      </div>

      <!-- Company suggestions dropdown -->
      <div
        v-if="
          showSuggestions &&
          (filteredCompanies.length > 0 ||
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
          Searching companies...
        </div>

        <!-- Results -->
        <template v-else>
          <div
            v-for="company in filteredCompanies"
            :key="company.id"
            class="flex items-center gap-3 px-3 py-2 hover:bg-muted cursor-pointer"
            @click="selectCompany(company)"
          >
            <Image
              :src="company.imgs?.internal || company.imgs?.public"
              :alt="company.name"
              class="w-8 h-8 rounded-md object-cover border flex-shrink-0"
            />
            <div class="flex flex-col gap-1 min-w-0 flex-1">
              <span class="font-medium truncate">{{ company.name }}</span>
              <span
                v-if="company.description"
                class="text-xs text-muted-foreground truncate"
              >
                {{ company.description }}
              </span>
            </div>
          </div>
        </template>

        <!-- No results found -->
        <div
          v-if="
            !isLoading && filteredCompanies.length === 0 && searchTerm.trim()
          "
          class="px-4 py-3 text-center text-sm text-muted-foreground flex items-center gap-2 justify-center"
        >
          No company found.
          <Button
            v-if="props.showCreate"
            variant="link"
            size="sm"
            class="p-0 h-auto text-sm"
            @mousedown.prevent="handleCreateCompany"
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
import { getAllCompanies } from "@/api/companies";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import Image from "../Image.vue";
import type { Company } from "@/dto/companies";

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
  selected: [value: Company];
  "update:modelValue": [value: string];
  "create-company": [searchTerm: string];
}>();

const inputId = `company-autocomplete-${Math.random().toString(36).substr(2, 9)}`;
const searchTerm = ref("");
const companies = ref<Company[]>([]);
const showSuggestions = ref(false);
const isLoading = ref(false);
const searchTimeout = ref<number | null>(null);
const selectedCompany = ref<Company | null>(null);

// Watch for external changes to modelValue
watch(
  () => props.modelValue,
  (newValue) => {
    if (newValue !== searchTerm.value) {
      searchTerm.value = newValue || "";
      // Clear selected company if the value doesn't match
      if (selectedCompany.value && newValue !== selectedCompany.value.name) {
        selectedCompany.value = null;
      }
    }
  },
  { immediate: true },
);

// Search functionality
const searchCompanies = async (searchTermValue: string) => {
  if (!searchTermValue.trim()) {
    companies.value = [];
    showSuggestions.value = false;
    return;
  }

  isLoading.value = true;

  try {
    const response = await getAllCompanies({
      event: props.eventId,
      name: searchTermValue,
    });

    const companiesData = response.data || [];

    // Filter companies that match or are similar to the search term
    const filteredCompanies = companiesData.filter((company) =>
      company.name.toLowerCase().includes(searchTermValue.toLowerCase()),
    );

    companies.value = filteredCompanies.slice(0, 10); // Limit to 10 suggestions
    showSuggestions.value = true; // Always show suggestions when searching
  } catch (error) {
    console.error("Error searching companies:", error);
    companies.value = [];
    showSuggestions.value = true; // Show suggestions even on error to allow "Create Company"
  } finally {
    isLoading.value = false;
  }
};

const handleInput = (event: Event) => {
  const target = event.target as HTMLInputElement;
  const value = target.value;

  searchTerm.value = value;
  emit("update:modelValue", value);

  // Clear selected company if user is typing something different
  if (selectedCompany.value && value !== selectedCompany.value.name) {
    selectedCompany.value = null;
  }

  // Clear suggestions immediately if input is empty
  if (!value.trim()) {
    companies.value = [];
    showSuggestions.value = false;
    selectedCompany.value = null;
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
    searchCompanies(value);
  }, 300);
};

const selectCompany = (company: Company) => {
  selectedCompany.value = company;
  searchTerm.value = company.name;
  emit("update:modelValue", company.name);
  emit("selected", company);
  showSuggestions.value = false;
};

const handleCreateCompany = () => {
  emit("create-company", searchTerm.value);
  showSuggestions.value = false;
};

const clearSelection = () => {
  selectedCompany.value = null;
  searchTerm.value = "";
  emit("update:modelValue", "");
  companies.value = [];
  showSuggestions.value = false;
};

// Hide suggestions when clicking outside
const hideSuggestions = () => {
  setTimeout(() => {
    showSuggestions.value = false;
  }, 200);
};

const filteredCompanies = computed(() => {
  return companies.value;
});
</script>
