<template>
  <div class="flex items-start gap-3">
    <div class="flex-1 min-w-0">
      <div class="flex items-center gap-2">
        <img
          v-if="item?.img"
          :src="item.img"
          alt=""
          class="w-8 h-8 rounded object-cover border"
        />
        <span class="font-medium truncate">{{ item?.name ?? shortId }}</span>
      </div>
      <div class="text-xs text-muted-foreground">{{ item?.type }}</div>
    </div>

    <div class="flex items-center gap-2">
      <Popover v-model:open="isOpen">
        <PopoverTrigger as-child>
          <Button size="sm" variant="outline">More</Button>
        </PopoverTrigger>
        <PopoverContent class="max-w-sm">
          <div class="space-y-2">
            <div class="font-semibold">{{ item?.name ?? shortId }}</div>
            <div v-if="item?.description" class="text-sm text-muted-foreground">
              {{ item.description }}
            </div>
            <div v-else class="text-sm text-muted-foreground">
              No description
            </div>
            <div class="text-xs text-muted-foreground">
              Price: {{ item?.price ?? "-" }} — VAT: {{ item?.vat ?? "-" }}%
            </div>
          </div>
        </PopoverContent>
      </Popover>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue";
import { getItemById } from "@/api/items";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import Button from "@/components/ui/button/Button.vue";
import type { Item } from "@/dto/item";

const props = defineProps<{
  itemId: string;
}>();

const item = ref<Item | null>(null);
const isOpen = ref(false);

const shortId = props.itemId ? props.itemId.slice(0, 8) : "";

onMounted(async () => {
  if (!props.itemId) return;
  try {
    const res = await getItemById(props.itemId);
    item.value = res;
  } catch (err) {
    console.error("Failed to load item", props.itemId, err);
    item.value = null;
  }
});
</script>
