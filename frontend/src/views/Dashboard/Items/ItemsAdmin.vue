<template>
  <div class="p-4">
    <div
      class="flex flex-col md:flex-row md:items-center md:justify-between mb-4"
    >
      <div>
        <h2 class="text-2xl font-semibold">Items administration</h2>
        <p class="text-sm text-muted-foreground">
          Create, edit or remove items and manage categories.
        </p>
      </div>
      <div class="flex items-center gap-2">
        <Button size="sm" variant="outline" @click="openCreate"
          >New Item</Button
        >
      </div>
    </div>

    <div>
      <h3 class="font-medium mb-2">Items</h3>
      <div class="space-y-2">
        <div v-if="isLoading">Loading...</div>
        <div v-else>
          <div v-if="items.length === 0" class="text-sm text-muted-foreground">
            No items found.
          </div>
          <div
            v-for="it in items"
            :key="it.id"
            class="flex items-center justify-between border rounded p-2"
          >
            <div class="min-w-0">
              <div class="font-medium truncate">{{ it.name }}</div>
              <div class="text-xs text-muted-foreground">
                {{ it.type }} • {{ formatPrice(it.price) }}
              </div>
            </div>

            <div class="flex items-center gap-2">
              <!-- Mobile: compact actions (three dots) -->
              <div class="md:hidden">
                <Popover>
                  <PopoverTrigger>
                    <button class="p-1 rounded hover:bg-gray-100">
                      <MoreVertical class="h-5 w-5 text-gray-600" />
                    </button>
                  </PopoverTrigger>
                  <PopoverContent class="w-40">
                    <div class="flex flex-col">
                      <button
                        class="text-left px-2 py-1 hover:bg-gray-50"
                        @click="editItem(it)"
                      >
                        Edit
                      </button>
                      <button
                        class="text-left px-2 py-1 text-destructive hover:bg-gray-50"
                        @click="openRemoveItem(it)"
                      >
                        Delete
                      </button>
                    </div>
                  </PopoverContent>
                </Popover>
              </div>

              <!-- Desktop: inline buttons -->
              <div class="hidden md:flex items-center gap-2">
                <Button size="sm" variant="ghost" @click="editItem(it)"
                  >Edit</Button
                >
                <Button
                  size="sm"
                  variant="destructive"
                  @click="openRemoveItem(it)"
                  >Delete</Button
                >
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Create / Edit Dialog -->
    <Teleport to="body">
      <AlertDialog v-model:open="isDialogOpen">
        <AlertDialogContent class="max-w-2xl">
          <div class="p-4">
            <CreateItemForm
              :initial-item="editItemData"
              :mode="editItemData ? 'edit' : 'create'"
              :header-title="editItemData ? 'Edit Item' : 'Create Item'"
              @cancel="closeDialog"
              @success="handleCreated"
            />
          </div>
        </AlertDialogContent>
      </AlertDialog>
    </Teleport>

    <!-- Delete confirmation dialog -->
    <Teleport to="body">
      <AlertDialog v-model:open="isDeleteDialogOpen">
        <AlertDialogContent class="max-w-md">
          <div class="p-4">
            <ConfirmDelete
              title="Confirm deletion"
              :message="deleteMessage"
              :is-deleting="isDeleting"
              @cancel="closeDeleteDialog"
              @confirm="confirmRemoveItem"
            />
          </div>
        </AlertDialogContent>
      </AlertDialog>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from "vue";
import { getItems, deleteItem, getItemById } from "@/api/items";
import CreateItemForm from "@/components/items/CreateItemForm.vue";
import { Button } from "@/components/ui/button";
import Popover from "@/components/ui/popover/Popover.vue";
import PopoverTrigger from "@/components/ui/popover/PopoverTrigger.vue";
import PopoverContent from "@/components/ui/popover/PopoverContent.vue";
import { MoreVertical } from "lucide-vue-next";
import { AlertDialog, AlertDialogContent } from "@/components/ui/alert-dialog";
import ConfirmDelete from "@/components/ConfirmDelete.vue";

interface ItemRow {
  id: string;
  name: string;
  type: string;
  price: number;
}

interface EditableItem {
  id?: string;
  name?: string;
  type?: string;
  description?: string;
  price?: number;
  vat?: number;
}

const items = ref<ItemRow[]>([]);
const isLoading = ref(false);
const isDialogOpen = ref(false);
const editItemData = ref<EditableItem | null>(null);
const isDeleteDialogOpen = ref(false);
const deleteTarget = ref<{ id: string; name?: string } | null>(null);
const isDeleting = ref(false);

const load = async () => {
  isLoading.value = true;
  try {
    const res = (await getItems()) as Array<import("@/dto/item").Item>;
    // res is Item[]; map to simple shape
    items.value = res.map((r) => ({
      id: r.id || "",
      name: r.name || "",
      type: r.type || "",
      price: Number(r.price || 0),
    }));
  } catch (err) {
    console.error("Failed to load items", err);
  } finally {
    isLoading.value = false;
  }
};

onMounted(load);

const openCreate = () => {
  editItemData.value = null;
  isDialogOpen.value = true;
};

const closeDialog = () => {
  isDialogOpen.value = false;
};

const handleCreated = async () => {
  // refresh list and close dialog
  await load();
  closeDialog();
};

const editItem = async (it: ItemRow) => {
  // fetch full item data (description, vat, etc.) before opening editor
  try {
    const full = await getItemById(it.id);
    // adapt to EditableItem shape but pass full object to form
    editItemData.value = {
      id: full.id || it.id,
      name: full.name || it.name,
      type: full.type || it.type,
      price: Number(full.price || it.price || 0),
      // attach description and vat so CreateItemForm can use them
      description: full.description || "",
      vat: Number(full.vat || 0),
    };
  } catch (err) {
    console.error("Failed to load full item for edit", err);
    // fallback to minimal data
    editItemData.value = {
      id: it.id,
      name: it.name,
      type: it.type,
      price: it.price,
    };
  }
  isDialogOpen.value = true;
};

const openRemoveItem = (it: ItemRow) => {
  deleteTarget.value = { id: it.id, name: it.name };
  isDeleteDialogOpen.value = true;
};

const confirmRemoveItem = async () => {
  if (!deleteTarget.value) return;
  isDeleting.value = true;
  try {
    await deleteItem(deleteTarget.value.id);
    await load();
    isDeleteDialogOpen.value = false;
    deleteTarget.value = null;
  } catch (err) {
    console.error("Failed to delete item", err);
    alert("Failed to delete item");
  } finally {
    isDeleting.value = false;
  }
};

const closeDeleteDialog = () => {
  isDeleteDialogOpen.value = false;
  deleteTarget.value = null;
};

const deleteMessage = computed(() =>
  deleteTarget.value && deleteTarget.value.name
    ? `Delete item "${deleteTarget.value.name}"? This action cannot be undone.`
    : "Delete this item?",
);

const formatPrice = (cents: number) => `${(cents / 100).toFixed(2)}€`;
</script>
