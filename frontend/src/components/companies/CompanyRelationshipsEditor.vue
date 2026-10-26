<template>
  <div class="space-y-4">
    <div>
      <h3 class="text-sm font-medium">Company Relationships</h3>
      <p class="text-xs text-muted-foreground">
        Acquisitions, mergers and rebrands. Changes are saved immediately and
        also shown on the related company.
      </p>
    </div>

    <!-- Existing relationships -->
    <ul v-if="relationships?.length" class="space-y-2">
      <li
        v-for="rel in relationships"
        :key="`${rel.type}-${rel.company}`"
        class="space-y-1.5 rounded-md border px-2 py-1.5 text-sm"
      >
        <div class="flex items-center gap-2">
          <span class="text-muted-foreground whitespace-nowrap">
            {{ companyRelationshipLabels[rel.type] }}
          </span>
          <Image
            :src="rel.img"
            :alt="`${rel.name} logo`"
            class="h-6 w-6 flex-shrink-0 rounded-full border object-contain bg-white"
          />
          <span class="min-w-0 flex-1 truncate font-medium">
            {{ rel.name }}
          </span>
          <Button
            variant="ghost"
            size="sm"
            class="h-6 w-6 p-0 text-destructive hover:text-destructive"
            :disabled="isRemoving"
            :aria-label="`Remove relationship with ${rel.name}`"
            @click="handleRemove(rel)"
          >
            <XIcon class="h-4 w-4" />
          </Button>
        </div>
        <div class="flex items-center gap-2">
          <label
            :for="`relationship-since-${rel.type}-${rel.company}`"
            class="text-xs text-muted-foreground"
          >
            Since
          </label>
          <Input
            :id="`relationship-since-${rel.type}-${rel.company}`"
            type="date"
            class="h-7 w-auto px-2 text-xs"
            :model-value="toDateInputValue(rel.since)"
            :disabled="isUpdating"
            @change="handleDateChange(rel, $event)"
          />
        </div>
      </li>
    </ul>
    <p v-else class="text-xs text-muted-foreground">No relationships yet.</p>

    <!-- New relationship: created as soon as a company is chosen -->
    <div class="space-y-3 rounded-md border border-dashed p-3">
      <div class="space-y-2">
        <Label for="relationship-type" class="text-sm font-medium">
          This company…
        </Label>
        <NativeSelect
          id="relationship-type"
          v-model="newType"
          class="w-full"
          :disabled="isAdding"
        >
          <option
            v-for="(label, type) in companyRelationshipLabels"
            :key="type"
            :value="type"
          >
            {{ label }}
          </option>
        </NativeSelect>
      </div>

      <div class="relative space-y-2">
        <Label for="relationship-company" class="text-sm font-medium">
          Company
        </Label>
        <Input
          id="relationship-company"
          v-model="search"
          :placeholder="isAdding ? 'Adding…' : 'Search company…'"
          autocomplete="off"
          :disabled="isAdding"
          @focus="isSearchOpen = true"
          @blur="isSearchOpen = false"
        />
        <ul
          v-if="isSearchOpen && search.trim()"
          class="absolute z-50 mt-1 max-h-64 w-full overflow-auto rounded-md border bg-popover p-1 shadow-md"
        >
          <li
            v-for="company in searchResults"
            :key="company.id"
            class="flex cursor-pointer items-center gap-2 rounded-sm px-2 py-1.5 text-sm hover:bg-accent"
            @mousedown.prevent="handleAdd(company)"
          >
            <Image
              :src="company.imgs?.internal || company.imgs?.public"
              :alt="`${company.name} logo`"
              class="h-6 w-6 flex-shrink-0 rounded-full border object-contain bg-white"
            />
            <span class="truncate">{{ company.name }}</span>
          </li>
          <li
            v-if="!searchResults.length"
            class="px-2 py-1.5 text-sm text-muted-foreground"
          >
            No companies found.
          </li>
        </ul>
      </div>
    </div>

    <p v-if="errorMessage" class="text-xs text-destructive">
      {{ errorMessage }}
    </p>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import { useQuery } from "@pinia/colada";
import createFuzzySearch from "@nozbe/microfuzz";
import { XIcon } from "lucide-vue-next";
import { getAllCompanies } from "@/api/companies";
import {
  companyRelationshipLabels,
  type Company,
  type CompanyRelationshipType,
  type RelatedCompany,
} from "@/dto/companies";
import {
  useAddCompanyRelationshipMutation,
  useCompanyRelationshipsQuery,
  useRemoveCompanyRelationshipMutation,
  useUpdateCompanyRelationshipMutation,
} from "@/mutations/companies";
import { fromDateInputValue, toDateInputValue } from "@/lib/utils";
import Button from "../ui/button/Button.vue";
import Input from "../ui/input/Input.vue";
import Label from "../ui/label/Label.vue";
import { NativeSelect } from "../ui/native-select";
import Image from "../Image.vue";

const MAX_SEARCH_RESULTS = 8;

const props = defineProps<{
  companyId: string;
}>();

const { data: relationships } = useCompanyRelationshipsQuery(
  () => props.companyId,
);

// Same query as the global search, so the companies list is shared in cache.
const { data: companiesData } = useQuery({
  key: () => ["companies"],
  query: () => getAllCompanies({}),
});

const otherCompanies = computed(() =>
  (companiesData.value?.data ?? []).filter((c) => c.id !== props.companyId),
);

const fuzzySearch = computed(() =>
  createFuzzySearch(otherCompanies.value, { getText: (c) => [c.name] }),
);

const newType = ref<CompanyRelationshipType>("SUBSIDIARY_OF");
const search = ref("");
const isSearchOpen = ref(false);
const errorMessage = ref("");

const searchResults = computed(() =>
  fuzzySearch
    .value(search.value.trim())
    .slice(0, MAX_SEARCH_RESULTS)
    .map((result) => result.item),
);

const { mutateAsync: addRelationship, isLoading: isAdding } =
  useAddCompanyRelationshipMutation();
const { mutateAsync: removeRelationship, isLoading: isRemoving } =
  useRemoveCompanyRelationshipMutation();
const { mutateAsync: updateRelationship, isLoading: isUpdating } =
  useUpdateCompanyRelationshipMutation();

const toErrorMessage = (error: unknown) => {
  const response = (error as { response?: { status?: number; data?: unknown } })
    .response;
  switch (response?.status) {
    case 409:
      return "This relationship already exists or would create a cycle.";
    case 404:
      return "Company not found.";
    default:
      return typeof response?.data === "string" && response.data
        ? response.data
        : "Something went wrong. Please try again.";
  }
};

const handleAdd = async (company: Company) => {
  errorMessage.value = "";
  search.value = "";
  isSearchOpen.value = false;

  try {
    await addRelationship({
      companyId: props.companyId,
      data: { type: newType.value, company: company.id },
    });
  } catch (error) {
    errorMessage.value = toErrorMessage(error);
  }
};

const handleDateChange = async (rel: RelatedCompany, event: Event) => {
  errorMessage.value = "";
  const value = (event.target as HTMLInputElement).value;

  try {
    await updateRelationship({
      companyId: props.companyId,
      targetId: rel.company,
      type: rel.type,
      data: { since: fromDateInputValue(value) },
    });
  } catch (error) {
    errorMessage.value = toErrorMessage(error);
  }
};

const handleRemove = async (rel: RelatedCompany) => {
  errorMessage.value = "";

  try {
    await removeRelationship({
      companyId: props.companyId,
      targetId: rel.company,
      type: rel.type,
    });
  } catch (error) {
    errorMessage.value = toErrorMessage(error);
  }
};
</script>
