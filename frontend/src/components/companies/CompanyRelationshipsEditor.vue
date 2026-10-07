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
        class="flex items-center gap-2 rounded-md border px-2 py-1.5 text-sm"
      >
        <span class="text-muted-foreground whitespace-nowrap">
          {{ companyRelationshipLabels[rel.type] }}
        </span>
        <Image
          :src="rel.img"
          :alt="`${rel.name} logo`"
          class="h-6 w-6 flex-shrink-0 rounded-full border object-contain bg-white"
        />
        <span class="flex-1 truncate font-medium">{{ rel.name }}</span>
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
      </li>
    </ul>
    <p v-else class="text-xs text-muted-foreground">No relationships yet.</p>

    <!-- New relationship -->
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
        <div
          v-if="selectedCompany"
          class="flex items-center gap-2 rounded-md border px-2 py-1.5 text-sm"
        >
          <Image
            :src="
              selectedCompany.imgs?.internal || selectedCompany.imgs?.public
            "
            :alt="`${selectedCompany.name} logo`"
            class="h-6 w-6 flex-shrink-0 rounded-full border object-contain bg-white"
          />
          <span class="flex-1 truncate font-medium">
            {{ selectedCompany.name }}
          </span>
          <Button
            variant="ghost"
            size="sm"
            class="h-6 w-6 p-0"
            aria-label="Clear selected company"
            :disabled="isAdding"
            @click="selectedCompany = null"
          >
            <XIcon class="h-4 w-4" />
          </Button>
        </div>
        <template v-else>
          <Input
            id="relationship-company"
            v-model="search"
            placeholder="Search company…"
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
              @mousedown.prevent="selectCompany(company)"
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
        </template>
      </div>

      <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <div class="space-y-2">
          <Label for="relationship-since" class="text-sm font-medium">
            Since
          </Label>
          <Input
            id="relationship-since"
            v-model="since"
            type="date"
            :disabled="isAdding"
          />
        </div>
        <div class="space-y-2">
          <Label for="relationship-notes" class="text-sm font-medium">
            Notes
          </Label>
          <Input
            id="relationship-notes"
            v-model="notes"
            placeholder="Optional"
            :disabled="isAdding"
          />
        </div>
      </div>

      <p v-if="errorMessage" class="text-xs text-destructive">
        {{ errorMessage }}
      </p>

      <div class="flex justify-end">
        <Button
          size="sm"
          :disabled="!selectedCompany || isAdding"
          @click="handleAdd"
        >
          Add relationship
        </Button>
      </div>
    </div>
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
} from "@/mutations/companies";
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
const selectedCompany = ref<Company | null>(null);
const since = ref("");
const notes = ref("");
const errorMessage = ref("");

const searchResults = computed(() =>
  fuzzySearch
    .value(search.value.trim())
    .slice(0, MAX_SEARCH_RESULTS)
    .map((result) => result.item),
);

const selectCompany = (company: Company) => {
  selectedCompany.value = company;
  search.value = "";
  isSearchOpen.value = false;
};

const { mutateAsync: addRelationship, isLoading: isAdding } =
  useAddCompanyRelationshipMutation();
const { mutateAsync: removeRelationship, isLoading: isRemoving } =
  useRemoveCompanyRelationshipMutation();

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

const handleAdd = async () => {
  if (!selectedCompany.value) return;
  errorMessage.value = "";

  try {
    await addRelationship({
      companyId: props.companyId,
      data: {
        type: newType.value,
        company: selectedCompany.value.id,
        since: since.value ? new Date(since.value).toISOString() : undefined,
        notes: notes.value.trim() || undefined,
      },
    });

    selectedCompany.value = null;
    since.value = "";
    notes.value = "";
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
