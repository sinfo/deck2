<template>
  <Card>
    <CardContent>
      <div class="flex justify-between items-start">
        <div>
          <h4 class="font-semibold">{{ pkg.name }}</h4>
          <div class="text-sm text-muted-foreground">
            Price: {{ pkg.price }} — VAT: {{ pkg.vat }}%
          </div>
        </div>

        <div class="flex items-center gap-2">
          <Popover v-model:open="isEditOpen">
            <PopoverTrigger as-child>
              <Button variant="outline" size="sm">Edit</Button>
            </PopoverTrigger>
            <PopoverContent
              class="w-[520px] max-w-[calc(100vw-40px)] max-h-[85vh] overflow-hidden"
            >
              <div class="p-4 border-b">
                <h3 class="font-semibold">Edit package</h3>
              </div>
              <div class="p-4">
                <PackageForm
                  v-if="isEditOpen"
                  :mode="'edit'"
                  :initial="pkg"
                  :event-name="eventName"
                  @saved="handleUpdated"
                  @cancel="isEditOpen = false"
                />
              </div>
            </PopoverContent>
          </Popover>

          <Popover v-model:open="isDeleteOpen">
            <PopoverTrigger as-child>
              <Button variant="destructive" size="sm">Remove</Button>
            </PopoverTrigger>
            <PopoverContent class="w-80">
              <ConfirmDelete
                title="Confirm deletion"
                message="Are you sure you want to delete this package? This action cannot be undone."
                :is-deleting="isDeleting"
                @cancel="isDeleteOpen = false"
                @confirm="confirmDelete"
              />
            </PopoverContent>
          </Popover>
        </div>
      </div>

      <div class="mt-3">
        <h5 class="font-medium">Items</h5>
        <ul class="list-none ml-0 text-sm space-y-2">
          <li
            v-for="it in pkg.items"
            :key="it.item"
            class="flex items-center justify-between gap-4"
          >
            <div class="flex-1 min-w-0">
              <ItemInline :item-id="it.item" />
            </div>
            <div class="ml-4 text-sm text-muted-foreground">
              qty: {{ it.quantity }}
            </div>
            <div class="ml-4 text-sm text-muted-foreground">
              {{ it.public ? "(public)" : "" }}
            </div>
          </li>
        </ul>
      </div>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { ref } from "vue";
import Card from "@/components/ui/card/Card.vue";
import CardContent from "@/components/ui/card/CardContent.vue";
import Button from "@/components/ui/button/Button.vue";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import PackageForm from "@/components/packages/PackageForm.vue";
import ItemInline from "@/components/items/ItemInline.vue";
import { deletePackage } from "@/api/packages";
import type { Package } from "@/dto/packages";
import ConfirmDelete from "@/components/ConfirmDelete.vue";

interface Props {
  pkg: Package;
  eventName: string;
}

const props = defineProps<Props>();
const emit = defineEmits(["updated", "deleted"] as const);

const isEditOpen = ref(false);
const isDeleteOpen = ref(false);
const isDeleting = ref(false);

const handleUpdated = () => {
  isEditOpen.value = false;
  emit("updated");
};

const confirmDelete = async () => {
  isDeleting.value = true;
  try {
    await deletePackage(String(props.pkg.id));
    isDeleteOpen.value = false;
    emit("deleted");
  } catch (err) {
    console.error(err);
  } finally {
    isDeleting.value = false;
  }
};
</script>
