<template>
  <form @submit.prevent="submit">
    <div class="grid grid-cols-1 gap-3">
      <div>
        <Label class="text-sm font-medium">Name</Label>
        <Input
          v-model="local.name"
          placeholder="Package name (without event prefix)"
        />
        <p class="text-xs text-muted-foreground mt-1">
          Name will be prefixed with the event name.
        </p>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div>
          <Label class="text-sm font-medium">Price (cents)</Label>
          <Input v-model.number="local.price" type="number" />
        </div>
        <div>
          <Label class="text-sm font-medium">VAT (%)</Label>
          <Input v-model.number="local.vat" type="number" />
        </div>
      </div>

      <div>
        <Label class="text-sm font-medium">Items</Label>
        <div class="space-y-2">
          <div
            v-for="(it, idx) in local.items"
            :key="idx"
            class="flex gap-2 items-center"
          >
            <ItemAutocomplete
              v-model="it.item"
              placeholder="Select item..."
              :show-create="true"
            />
            <Input v-model.number="it.quantity" type="number" class="w-24" />
            <label class="flex items-center gap-2">
              <input v-model="it.public" type="checkbox" />
              <span class="text-sm">Public</span>
            </label>
            <Button variant="ghost" @click.prevent="removeItem(idx)"
              >Remove</Button
            >
          </div>

          <div>
            <Button size="sm" variant="outline" @click.prevent="addItem"
              >Add item</Button
            >
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-2">
        <Button
          variant="outline"
          size="sm"
          type="button"
          @click.prevent="handleCancel"
        >
          Cancel
        </Button>
        <Button size="sm" :disabled="isSaving">{{
          isSaving ? "Saving..." : submitLabel
        }}</Button>
      </div>
    </div>
  </form>
</template>

<script setup lang="ts">
import { reactive, ref } from "vue";
import {
  createPackage,
  updatePackage,
  updatePackageItems,
} from "@/api/packages";
import type { PackageItem } from "@/dto/packages";
import Input from "@/components/ui/input/Input.vue";
import Button from "@/components/ui/button/Button.vue";
import Label from "@/components/ui/label/Label.vue";
import ItemAutocomplete from "@/components/items/ItemAutocompleteWithDialog.vue";
import type { Package } from "@/dto/packages";

interface Props {
  eventName?: string;
  mode?: "create" | "edit";
  initial?: Package | undefined;
}

const props = withDefaults(defineProps<Props>(), {
  mode: "create",
  initial: undefined,
  eventName: "",
});

const emit = defineEmits(["saved", "cancel"] as const);

const local = reactive({
  id: props.initial?.id as string | undefined,
  name: (props.initial?.name as string) || "",
  price: Number(props.initial?.price || 0),
  vat: Number(props.initial?.vat || 0),
  items: (props.initial?.items || []) as PackageItem[],
});

const isSaving = ref(false);

const submitLabel = props.mode === "edit" ? "Update" : "Create";

const ensurePrefixedName = (name: string) => {
  const prefix = props.eventName ? String(props.eventName).trim() : "";
  if (!prefix) return name;
  if (name.startsWith(prefix)) return name;
  return `${prefix} ${name}`.trim();
};

const submit = async () => {
  isSaving.value = true;
  try {
    const finalName = ensurePrefixedName(local.name);
    if (props.mode === "create") {
      const payloadItems = (local.items || [])
        .map((i: PackageItem) => ({
          item: String(i.item || "").trim(),
          quantity: Math.max(0, Number(i.quantity || 0)),
          public: Boolean(i.public),
        }))
        .filter((i) => i.item.length > 0 && i.quantity > 0);

      // Validate item ids are 24-char hex ObjectIDs
      const invalidItems = payloadItems.filter(
        (it) => !/^[a-fA-F0-9]{24}$/.test(it.item),
      );
      if (invalidItems.length > 0) {
        const ids = invalidItems.map((i) => i.item).join(", ");
        window.alert(
          `One or more item IDs are invalid. Item IDs must be MongoDB ObjectIDs (24 hex characters). Invalid: ${ids}`,
        );
        isSaving.value = false;
        return;
      }

      const payload = {
        name: finalName,
        price: Math.round(Number(local.price || 0)),
        vat: Math.round(Number(local.vat || 0)),
        items: payloadItems,
      };

      await createPackage(payload);
    } else {
      if (!local.id) throw new Error("Missing package id");
      await updatePackage(local.id, {
        name: finalName,
        price: Number(local.price || 0),
        vat: Number(local.vat || 0),
      });
      // Update items through dedicated endpoint
      const itemsToUpdate = (local.items || [])
        .map((i: unknown) => {
          const ii = i as Record<string, unknown>;
          return {
            item: String(ii.item || "").trim(),
            quantity: Math.max(0, Number(ii.quantity || 0)),
          };
        })
        .filter((it) => it.item.length > 0 && it.quantity > 0);

      const invalidOnUpdate = itemsToUpdate.filter(
        (it) => !/^[a-fA-F0-9]{24}$/.test(it.item),
      );
      if (invalidOnUpdate.length > 0) {
        const ids = invalidOnUpdate.map((i) => i.item).join(", ");
        window.alert(
          `One or more item IDs are invalid. Item IDs must be 24 hex characters. Invalid: ${ids}`,
        );
        isSaving.value = false;
        return;
      }

      await updatePackageItems(local.id, { items: itemsToUpdate });
    }

    emit("saved");
  } catch (err: unknown) {
    // Better axios error reporting to help debug 400s
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const anyErr = err as any;
    if (anyErr?.response) {
      console.error(
        "API error response:",
        anyErr.response.status,
        anyErr.response.data,
      );
      // show an alert for quick feedback during development
      try {
        window.alert(
          `Failed to save package: ${anyErr.response.status} - ${JSON.stringify(anyErr.response.data)}`,
        );
      } catch {
        // ignore
      }
    } else {
      console.error(err);
    }
  } finally {
    isSaving.value = false;
  }
};

const addItem = () => {
  local.items.push({ item: "", quantity: 1, public: true } as PackageItem);
};

const removeItem = (idx: number) => {
  local.items.splice(idx, 1);
};

const resetForm = () => {
  local.id = props.initial?.id as string | undefined;
  local.name = (props.initial?.name as string) || "";
  local.price = Number(props.initial?.price || 0);
  local.vat = Number(props.initial?.vat || 0);
  // deep copy of items to avoid mutating prop
  local.items = (
    props.initial?.items ? JSON.parse(JSON.stringify(props.initial.items)) : []
  ) as PackageItem[];
};

const handleCancel = () => {
  resetForm();
  emit("cancel");
};
</script>
