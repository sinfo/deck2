<template>
  <div class="p-4">
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-lg font-semibold">Item Categories</h3>
      <div class="flex items-center gap-2">
        <Button size="sm" variant="outline" @click="openCreate"
          >New Category</Button
        >
      </div>
    </div>

    <div class="space-y-2">
      <div
        v-for="(c, idx) in categories"
        :key="c.id || idx"
        class="flex items-center justify-between border rounded p-2"
      >
        <div class="flex items-center gap-3 min-w-0">
          <div class="font-medium truncate">{{ c.name }}</div>
        </div>

        <div class="flex items-center gap-2">
          <!-- Mobile: 3-dot menu -->
          <div class="md:hidden">
            <Popover>
              <PopoverTrigger>
                <button class="p-1 rounded hover:bg-gray-100" :disabled="!c.id">
                  <MoreVertical class="h-5 w-5 text-gray-600" />
                </button>
              </PopoverTrigger>
              <PopoverContent class="w-40">
                <div class="flex flex-col">
                  <button
                    class="text-left px-2 py-1 hover:bg-gray-50"
                    :disabled="!c.id"
                    @click="startEdit(idx)"
                  >
                    Edit
                  </button>
                  <button
                    class="text-left px-2 py-1 text-destructive hover:bg-gray-50"
                    :disabled="!c.id"
                    @click="openRemove(idx)"
                  >
                    Delete
                  </button>
                </div>
              </PopoverContent>
            </Popover>
          </div>

          <!-- Desktop: inline buttons -->
          <div class="hidden md:flex items-center gap-2">
            <Button
              size="sm"
              variant="ghost"
              :disabled="!c.id"
              @click="startEdit(idx)"
              >Edit</Button
            >
            <Button
              size="sm"
              variant="destructive"
              :disabled="!c.id"
              @click="openRemove(idx)"
              >Delete</Button
            >
          </div>
        </div>
      </div>
    </div>

    <!-- Create / Edit Dialog -->
    <Teleport to="body">
      <AlertDialog v-model:open="isDialogOpen">
        <AlertDialogContent class="max-w-md">
          <AlertDialogHeader>
            <AlertDialogTitle>{{
              editIndex === -1 ? "Create Category" : "Edit Category"
            }}</AlertDialogTitle>
            <AlertDialogDescription>
              {{
                editIndex === -1
                  ? "Create a new item category"
                  : "Edit category name"
              }}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <div class="p-4">
            <div class="space-y-3">
              <Input v-model="dialogName" />
            </div>
            <div class="flex justify-end gap-2 mt-3">
              <Button variant="outline" @click="closeDialog">Cancel</Button>
              <Button @click="confirmDialog">{{
                editIndex === -1 ? "Create" : "Save"
              }}</Button>
            </div>
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
              @confirm="confirmRemove"
            />
          </div>
        </AlertDialogContent>
      </AlertDialog>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from "vue";
import { getItemCategories, createItemCategory } from "@/api/items";
import {
  updateItemCategory as apiUpdate,
  deleteItemCategory as apiDelete,
} from "@/api/items";
import { Button } from "@/components/ui/button";
import ConfirmDelete from "@/components/ConfirmDelete.vue";
import Popover from "@/components/ui/popover/Popover.vue";
import PopoverTrigger from "@/components/ui/popover/PopoverTrigger.vue";
import PopoverContent from "@/components/ui/popover/PopoverContent.vue";
import { MoreVertical } from "lucide-vue-next";
import { Input } from "@/components/ui/input";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogDescription,
} from "@/components/ui/alert-dialog";

const categories = ref<Array<{ id: string; name: string }>>([]);
const isDialogOpen = ref(false);
const editIndex = ref(-1);
const dialogName = ref("");

const load = async () => {
  try {
    const res = await getItemCategories();
    const out: Array<{ id: string; name: string }> = [];
    if (Array.isArray(res)) {
      for (const it of res) {
        if (typeof it === "string") out.push({ id: "", name: it });
        else {
          const obj = it as unknown as { id?: string; name?: string };
          out.push({ id: obj.id || "", name: obj.name || "" });
        }
      }
    }
    categories.value = out;
  } catch (err) {
    console.error("Could not load categories", err);
  }
};

onMounted(load);

const openCreate = () => {
  editIndex.value = -1;
  dialogName.value = "";
  isDialogOpen.value = true;
};

const startEdit = (idx: number) => {
  editIndex.value = idx;
  dialogName.value = categories.value[idx].name;
  isDialogOpen.value = true;
};

const closeDialog = () => {
  isDialogOpen.value = false;
};

const confirmDialog = async () => {
  const name = dialogName.value.trim();
  if (!name) return;
  try {
    if (editIndex.value === -1) {
      await createItemCategory(name);
    } else {
      const cat = categories.value[editIndex.value];
      if (!cat || !cat.id) throw new Error("Missing category id");
      await apiUpdate(cat.id, { name });
    }
    await load();
    closeDialog();
  } catch (err) {
    console.error("Failed to save category", err);
    // show error (omitted)
  }
};

const isDeleteDialogOpen = ref(false);
const deleteIndex = ref<number | null>(null);
const isDeleting = ref(false);

const openRemove = (idx: number) => {
  deleteIndex.value = idx;
  isDeleteDialogOpen.value = true;
};

const closeDeleteDialog = () => {
  isDeleteDialogOpen.value = false;
  deleteIndex.value = null;
};

const confirmRemove = async () => {
  if (deleteIndex.value === null) return;
  const cat = categories.value[deleteIndex.value];
  if (!cat || !cat.id) return;
  isDeleting.value = true;
  try {
    await apiDelete(cat.id);
    await load();
    closeDeleteDialog();
  } catch (err) {
    console.error("Failed to delete category", err);
    alert("Failed to delete category");
  } finally {
    isDeleting.value = false;
  }
};

const deleteMessage = computed(() =>
  deleteIndex.value !== null && categories.value[deleteIndex.value]
    ? `Delete category "${categories.value[deleteIndex.value].name}"? This cannot be undone.`
    : "Delete this category?",
);

// expose for template
</script>
