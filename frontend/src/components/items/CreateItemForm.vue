<template>
  <div class="w-full max-w-md mx-auto p-4">
    <div class="mb-4">
      <h3 class="text-lg font-medium">
        {{ props.headerTitle || "Create Item" }}
      </h3>
    </div>

    <div class="space-y-4">
      <div>
        <Label class="text-sm font-medium">Name *</Label>
        <Input v-model="form.name" :disabled="isLoading" :autofocus="true" />
        <span v-if="errors.name" class="text-sm text-destructive">{{
          errors.name
        }}</span>
      </div>

      <div>
        <Label class="text-sm font-medium">Type *</Label>
        <div v-if="categories.length">
          <div class="flex gap-2 items-center">
            <Select
              :model-value="selectedCategory"
              :disabled="isLoading"
              @update:model-value="onUpdateSelectedCategory"
            >
              <SelectTrigger class="flex-1 w-full">
                <SelectValue placeholder="-- choose type --" />
              </SelectTrigger>
              <SelectContent>
                <template v-for="c in categories" :key="c">
                  <SelectItem :value="c">{{ c }}</SelectItem>
                </template>
                <SelectItem value="__other__">Other (custom)</SelectItem>
              </SelectContent>
            </Select>
            <Button
              size="sm"
              variant="outline"
              :disabled="isLoading"
              @click.prevent="isCreateCategoryOpen = true"
            >
              New
            </Button>
          </div>
          <div v-if="isCustomType" class="mt-2">
            <Input
              v-model="form.type"
              :disabled="isLoading"
              placeholder="Enter custom type"
            />
            <span v-if="errors.type" class="text-sm text-destructive mt-1">{{
              errors.type
            }}</span>
          </div>
        </div>
        <div v-else>
          <Input v-model="form.type" :disabled="isLoading" />
          <span v-if="errors.type" class="text-sm text-destructive mt-1">{{
            errors.type
          }}</span>
        </div>
      </div>

      <div>
        <Label class="text-sm font-medium">Description *</Label>
        <Textarea v-model="form.description" :disabled="isLoading" rows="3" />
        <span v-if="errors.description" class="text-sm text-destructive mt-1">{{
          errors.description
        }}</span>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div>
          <Label class="text-sm font-medium">Price (cents)</Label>
          <Input
            v-model.number="form.price"
            type="number"
            :disabled="isLoading"
          />
        </div>
        <div>
          <Label class="text-sm font-medium">VAT (%)</Label>
          <Input
            v-model.number="form.vat"
            type="number"
            :disabled="isLoading"
          />
        </div>
      </div>

      <div class="flex justify-end gap-2 pt-2">
        <Button variant="outline" :disabled="isLoading" @click="$emit('cancel')"
          >Cancel</Button
        >
        <Button :disabled="isLoading || !isFormValid" @click="handleCreate">{{
          mode === "edit" ? "Save" : "Create Item"
        }}</Button>
      </div>
    </div>
  </div>

  <!-- Create Category Dialog -->
  <Teleport to="body">
    <AlertDialog v-model:open="isCreateCategoryOpen">
      <AlertDialogContent class="max-w-md">
        <AlertDialogHeader>
          <AlertDialogTitle>Create Category</AlertDialogTitle>
          <AlertDialogDescription>
            Add a new category to be used when creating items.
          </AlertDialogDescription>
        </AlertDialogHeader>

        <div class="flex-1">
          <CreateCategoryForm
            @cancel="handleCategoryCancel"
            @success="handleCategoryCreated"
          />
        </div>
      </AlertDialogContent>
    </AlertDialog>
  </Teleport>
</template>

<script setup lang="ts">
import { reactive, ref, onMounted, watch, computed } from "vue";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select";
import { createItem, getItemCategories, updateItem } from "@/api/items";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogDescription,
} from "@/components/ui/alert-dialog";
import CreateCategoryForm from "./CreateCategoryForm.vue";

const props = defineProps<{
  initialItem?: {
    id?: string;
    name?: string;
    type?: string;
    description?: string;
    price?: number;
    vat?: number;
  } | null;
  // backward compatibility: some callers pass only the name
  initialItemName?: string;
  headerTitle?: string;
  mode?: "create" | "edit";
}>();

const emit = defineEmits<{
  cancel: [];
  success: [itemId: string];
}>();

const isLoading = ref(false);
const errors = reactive<Record<string, string>>({});

const form = reactive({
  name: props.initialItem?.name || props.initialItemName || "",
  type: props.initialItem?.type || "",
  description: props.initialItem?.description || "",
  price: Number(props.initialItem?.price || 0),
  vat: Number(props.initialItem?.vat || 0),
});

const categories = ref<string[]>([]);
const selectedCategory = ref<string>("");
const isCustomType = ref(false);
const isCreateCategoryOpen = ref(false);

// if parent passes an initialItem after mount (edit flow), update form values
watch(
  () => props.initialItem,
  (val) => {
    if (!val) return;
    form.name = val.name || form.name;
    form.type = val.type || form.type;
    form.description = val.description || form.description;
    form.price = Number(val.price || form.price || 0);
    form.vat = Number(val.vat || form.vat || 0);

    // update selected category / custom flag based on type
    if (val.type) {
      if (categories.value.includes(val.type)) {
        selectedCategory.value = val.type;
        isCustomType.value = false;
      } else {
        selectedCategory.value = "__other__";
        isCustomType.value = true;
      }
    }
  },
  { immediate: true },
);

watch(selectedCategory, (val) => {
  if (val === "__other__") {
    isCustomType.value = true;
    form.type = "";
  } else {
    isCustomType.value = false;
    form.type = val || "";
  }
});

const validate = () => {
  errors.name = "";
  errors.type = "";
  errors.description = "";
  if (!form.name || !form.name.trim()) {
    errors.name = "Name is required";
    return false;
  }

  // type must be set (either via select or custom input)
  if (!form.type || !String(form.type).trim()) {
    errors.type = "Type is required";
    return false;
  }

  if (!form.description || !String(form.description).trim()) {
    errors.description = "Description is required";
    return false;
  }

  return true;
};

const handleCreate = async () => {
  if (!validate()) return;
  isLoading.value = true;
  try {
    const payload = {
      name: String(form.name).trim(),
      type: String(form.type || "").trim(),
      description: String(form.description || "").trim(),
      price: Number(form.price || 0),
      vat: Number(form.vat || 0),
    };

    let result: unknown;
    if (
      (props.mode || "create") === "edit" &&
      props.initialItem &&
      props.initialItem.id
    ) {
      // update existing item
      result = await updateItem(props.initialItem.id, payload);
    } else {
      // create new
      result = await createItem(payload);
    }

    // try to extract id from result
    let id: string | undefined;
    if (result && typeof result === "object") {
      const r = result as Record<string, unknown>;
      if (typeof r.id === "string") id = r.id;
      else if (
        r.data &&
        typeof (r.data as Record<string, unknown>).id === "string"
      ) {
        id = (r.data as Record<string, unknown>).id as string;
      }
    }

    if (
      !id &&
      (props.mode || "create") === "edit" &&
      props.initialItem &&
      props.initialItem.id
    ) {
      // fallback: editing succeeded but API returned the updated object without id; use original id
      id = props.initialItem.id;
    }

    if (!id) throw new Error("Invalid response from item API");
    emit("success", id);
  } catch (err) {
    console.error("Error saving item:", err);
    errors.name = "Failed to save item";
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  // autofocus handled by input attribute; ensure initial name set
  (async () => {
    try {
      const res = await getItemCategories();
      // res can be array of strings or array of {id,name}
      const names: string[] = [];
      if (Array.isArray(res)) {
        for (const it of res) {
          if (typeof it === "string") names.push(it);
          else if (it && typeof it === "object" && "name" in it)
            names.push((it as { name?: string }).name || "");
        }
      }
      categories.value = names;
      // if initial type provided and exists in list, select it
      if (form.type && categories.value.includes(form.type)) {
        selectedCategory.value = form.type;
      } else if (form.type) {
        // treat as custom
        selectedCategory.value = "__other__";
        isCustomType.value = true;
      }
    } catch (err) {
      // ignore, we'll keep the input as free text
      console.error("Could not load item categories", err);
    }
  })();
});

// handle category create dialog events
const handleCategoryCreated = async (name: string) => {
  try {
    const res = await getItemCategories();
    const names: string[] = [];
    if (Array.isArray(res)) {
      for (const it of res) {
        if (typeof it === "string") names.push(it);
        else if (it && typeof it === "object" && "name" in it)
          names.push((it as { name?: string }).name || "");
      }
    }
    categories.value = names;
    selectedCategory.value = name;
  } catch (err) {
    console.error("Could not refresh categories after creation", err);
  } finally {
    isCreateCategoryOpen.value = false;
  }
};

const handleCategoryCancel = () => {
  isCreateCategoryOpen.value = false;
};

const isFormValid = computed(() => {
  const nameOk = !!form.name && String(form.name).trim().length > 0;
  const typeOk = !!form.type && String(form.type).trim().length > 0;
  const descOk =
    !!form.description && String(form.description).trim().length > 0;
  return nameOk && typeOk && descOk;
});

const onUpdateSelectedCategory = (val: unknown) => {
  // the Select component may emit `string | null` or other acceptable values
  const v = val == null ? "" : String(val);
  selectedCategory.value = v;
};
</script>
