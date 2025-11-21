<template>
  <div class="relative">
    <Label v-if="label" :for="inputId" class="text-sm font-medium pb-2">
      {{ label }}
    </Label>

    <div class="relative">
      <div class="relative">
        <button
          v-if="selectedItem"
          type="button"
          class="absolute left-3 top-1/2 transform -translate-y-1/2 z-10"
        >
          <template v-if="selectedItem?.img">
            <Image
              :src="selectedItem.img"
              :alt="selectedItem.name"
              class="w-6 h-6 rounded object-cover border"
            />
          </template>
          <template v-else>
            <div
              class="w-6 h-6 flex items-center justify-center rounded bg-muted-foreground text-xs text-white border"
            >
              {{ selectedItem.name ? selectedItem.name.charAt(0) : "" }}
            </div>
          </template>
        </button>

        <button
          v-if="selectedItem"
          type="button"
          class="absolute right-3 top-1/2 transform -translate-y-1/2 z-10 text-muted-foreground hover:text-foreground"
          @click="clearSelection"
        >
          ×
        </button>

        <Input
          :id="inputId"
          v-model="searchTerm"
          :placeholder="placeholder || 'Search items...'"
          :class="['w-full', selectedItem ? 'pl-12 pr-8' : '']"
          :disabled="disabled"
          @input="handleInput"
          @blur="hideSuggestions"
        />
      </div>

      <div
        v-if="
          showSuggestions &&
          (items.length > 0 || isLoading || (searchTerm.trim() && !isLoading))
        "
        class="absolute z-50 w-full mt-1 bg-background border border-border rounded-md shadow-lg max-h-60 overflow-auto"
        @mousedown.prevent
      >
        <div
          v-if="isLoading"
          class="px-4 py-3 text-center text-sm text-muted-foreground"
        >
          Searching items...
        </div>

        <template v-else>
          <div
            v-for="it in items"
            :key="it.id"
            class="flex items-center gap-3 px-3 py-2 hover:bg-muted cursor-pointer"
            @click="selectItem(it)"
          >
            <Image
              v-if="it?.img"
              :src="it.img"
              :alt="it.name"
              class="w-8 h-8 rounded-md object-cover border flex-shrink-0"
            />
            <div class="flex flex-col gap-1 min-w-0 flex-1">
              <span class="font-medium truncate">{{ it.name }}</span>
              <div
                class="flex items-center gap-2 text-xs text-muted-foreground"
              >
                <span v-if="it.type" class="truncate">{{ it.type }}</span>
                <span v-if="it.price"
                  >• {{ (it.price / 100).toFixed(2) }}€</span
                >
              </div>
            </div>
          </div>
        </template>

        <div
          v-if="!isLoading && items.length === 0 && searchTerm.trim()"
          class="px-4 py-3 text-center text-sm text-muted-foreground flex items-center gap-2 justify-center"
        >
          No item found.
          <Button
            v-if="showCreate"
            variant="link"
            size="sm"
            class="p-0 h-auto text-sm"
            @mousedown.prevent="handleCreate"
            >Create?</Button
          >
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import { getItems, getItemById } from "@/api/items";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import Image from "@/components/Image.vue";
import type { Item } from "@/dto/item";

interface Props {
  modelValue?: string;
  label?: string;
  placeholder?: string;
  disabled?: boolean;
  showCreate?: boolean;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  selected: [item: Item];
  "update:modelValue": [val: string];
  "create-item": [name: string];
}>();

const inputId = `item-autocomplete-${Math.random().toString(36).substring(2, 11)}`;
const searchTerm = ref("");
const items = ref<Item[]>([]);
const isLoading = ref(false);
const showSuggestions = ref(false);
const selectedItem = ref<Item | null>(null);
let searchTimeout: ReturnType<typeof setTimeout> | null = null;

watch(
  () => props.modelValue,
  async (newVal) => {
    if (!newVal) {
      selectedItem.value = null;
      return;
    }
    try {
      const it = await getItemById(newVal);
      selectedItem.value = it;
      searchTerm.value = it.name;
    } catch (err) {
      console.error("Failed to fetch item by id", err);
      selectedItem.value = null;
    }
  },
  { immediate: true },
);

const search = async (q: string) => {
  if (!q.trim()) {
    items.value = [];
    showSuggestions.value = false;
    return;
  }
  isLoading.value = true;
  try {
    const res = await getItems({ name: q });
    items.value = (res || []).slice(0, 20);
    showSuggestions.value = true;
  } catch (err) {
    console.error("Error searching items", err);
    items.value = [];
    showSuggestions.value = true;
  } finally {
    isLoading.value = false;
  }
};

const handleInput = (ev: Event) => {
  const target = ev.target as HTMLInputElement;
  const val = target.value;
  searchTerm.value = val;
  if (selectedItem.value && val !== selectedItem.value.name)
    selectedItem.value = null;
  if (searchTimeout) clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => search(val), 250);
};

const selectItem = (it: Item) => {
  selectedItem.value = it;
  searchTerm.value = it.name;
  emit("update:modelValue", it.id);
  emit("selected", it);
  showSuggestions.value = false;
};

const handleCreate = () => {
  emit("create-item", searchTerm.value);
  showSuggestions.value = false;
};

const clearSelection = () => {
  selectedItem.value = null;
  searchTerm.value = "";
  emit("update:modelValue", "");
  items.value = [];
  showSuggestions.value = false;
};

const hideSuggestions = () => {
  setTimeout(() => (showSuggestions.value = false), 150);
};
</script>
