<template>
  <Card class="w-full">
    <CardHeader>
      <div class="flex items-center justify-between">
        <div>
          <CardTitle class="text-lg">Contacts</CardTitle>
          <CardDescription
            >⚠️ The first representative will be contacted when using bulk
            emails</CardDescription
          >
        </div>
        <div class="flex items-center gap-2">
          <Button
            v-if="representatives.length > 1"
            variant="outline"
            size="sm"
            :class="{ 'bg-primary/10 border-primary': isReorderMode }"
            :title="isReorderMode ? 'Exit reorder mode' : 'Reorder contacts'"
            @click="toggleReorderMode"
          >
            <GripVerticalIcon class="w-4 h-4" />
          </Button>
          <Popover v-model:open="isAddFormOpen">
            <PopoverTrigger as-child>
              <Button variant="outline" size="sm"> Add </Button>
            </PopoverTrigger>
            <PopoverContent
              :side="popoverSide"
              :side-offset="8"
              :collision-padding="20"
              :avoid-collisions="true"
              :sticky="'partial'"
              class="w-[420px] max-w-[calc(100vw-40px)] max-h-[85vh] overflow-hidden flex flex-col z-50"
            >
              <div class="p-6 pb-4 border-b flex-shrink-0">
                <h3 class="font-semibold text-lg">Add New Representative</h3>
              </div>
              <div class="flex-1 overflow-y-auto p-6 min-h-0">
                <ContactForm
                  mode="create"
                  :is-loading="isCreating"
                  @submit="handleCreateRepresentative"
                  @cancel="isAddFormOpen = false"
                />
              </div>
            </PopoverContent>
          </Popover>
        </div>
      </div>
    </CardHeader>

    <!-- Overlay backdrop when popover is open -->
    <div
      v-if="isAddFormOpen"
      class="fixed inset-0 bg-black/20 z-40 transition-opacity duration-200"
      @click="closeAllPopovers"
    ></div>

    <CardContent class="space-y-4">
      <!-- Reorder mode notice -->
      <div
        v-if="isReorderMode"
        class="bg-blue-50 border border-blue-200 rounded-lg p-3 text-sm text-blue-700"
      >
        <div class="flex items-center gap-2">
          <GripVerticalIcon class="w-4 h-4" />
          <span
            >Reorder mode active. Drag the cards to rearrange contacts.</span
          >
        </div>
      </div>

      <EmptyStateCard
        v-if="!representatives.length"
        class="text-center text-muted-foreground py-8"
        title="Click here to add representatives"
        @click="isAddFormOpen = true"
      />

      <div v-else class="space-y-3">
        <div
          v-for="(rep, index) in orderedRepresentatives"
          :key="rep.id"
          :ref="(el) => setItemRef(rep.id, el)"
          class="relative"
          :class="{
            'cursor-grab select-none touch-none': isReorderMode,
            'z-10 cursor-grabbing': draggedId === rep.id,
            'transition-transform duration-200 ease-out': draggedId !== rep.id,
          }"
          :style="
            draggedId === rep.id
              ? { transform: `translateY(${dragOffset}px)` }
              : undefined
          "
          @pointerdown="onPointerDown($event, rep.id)"
          @pointermove="onPointerMove"
          @pointerup="onPointerUp"
          @pointercancel="onPointerUp"
        >
          <!-- Drag handle hint, sits in the card list's left gutter -->
          <GripVerticalIcon
            v-if="isReorderMode"
            class="absolute -left-5 top-1/2 -translate-y-1/2 size-4 text-muted-foreground"
          />

          <div class="relative">
            <ContactCard
              :contact="rep.contact"
              :contact-name="rep.name"
              can-edit
              can-delete
              :entity-id="companyId"
              entity-type="company"
              :rep-id="rep.id"
              :is-deleting="isDeleting"
              :is-primary="index === 0"
              :class="{
                'transition-all duration-300': true,
                'ring-2 ring-blue-200': isReorderMode,
                'ring-1 ring-orange-200 shadow-sm':
                  index === 0 && !isReorderMode,
                'shadow-lg': draggedId === rep.id,
              }"
              @updated="handleContactUpdated"
              @delete="() => handleDeleteRepresentative(rep.id)"
            />
          </div>
        </div>
      </div>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { ref, computed, nextTick, onMounted, onUnmounted, watch } from "vue";
import { useMutation, useQueryCache } from "@pinia/colada";
import type { CompanyRep, CreateCompanyRepData } from "@/dto/companies";
import {
  createCompanyRepresentative,
  deleteCompanyRepresentative,
} from "@/api/companies";
import { useUpdateRepresentativeOrderMutation } from "@/mutations/companies";
import { GripVerticalIcon } from "lucide-vue-next";
import Card from "../ui/card/Card.vue";
import CardContent from "../ui/card/CardContent.vue";
import CardDescription from "../ui/card/CardDescription.vue";
import CardHeader from "../ui/card/CardHeader.vue";
import CardTitle from "../ui/card/CardTitle.vue";
import Button from "../ui/button/Button.vue";
import { Popover, PopoverContent, PopoverTrigger } from "../ui/popover";
import ContactForm from "./ContactForm.vue";
import ContactCard from "../ContactCard.vue";
import EmptyStateCard from "../ui/EmptyStateCard.vue";

const props = defineProps<{
  representatives: CompanyRep[];
  companyId: string;
}>();

const queryCache = useQueryCache();
const isAddFormOpen = ref(false);

// Reorder state
const isReorderMode = ref(false);
const representativeOrder = ref<string[]>([]);

// Initialize order when representatives change
watch(
  () => props.representatives,
  (newReps) => {
    if (newReps) {
      // Add any new representatives to the order
      const existingIds = new Set(representativeOrder.value);
      const newIds = newReps
        .filter((rep) => !existingIds.has(rep.id))
        .map((rep) => rep.id);

      if (newIds.length > 0) {
        representativeOrder.value = [...representativeOrder.value, ...newIds];
      }

      // Remove any representatives that no longer exist
      const currentIds = new Set(newReps.map((rep) => rep.id));
      representativeOrder.value = representativeOrder.value.filter((id) =>
        currentIds.has(id),
      );

      // Initialize order if empty
      if (representativeOrder.value.length === 0) {
        representativeOrder.value = newReps.map((rep) => rep.id);
      }
    }
  },
  { immediate: true },
);

// Computed property for ordered representatives
const orderedRepresentatives = computed(() => {
  if (representativeOrder.value.length === 0) {
    return props.representatives;
  }

  const repMap = new Map(props.representatives.map((rep) => [rep.id, rep]));
  return representativeOrder.value
    .map((id) => repMap.get(id))
    .filter(Boolean) as CompanyRep[];
});

// Responsive positioning
const windowWidth = ref(0);

const updateWindowWidth = () => {
  windowWidth.value = window.innerWidth;
};

onMounted(() => {
  updateWindowWidth();
  window.addEventListener("resize", updateWindowWidth);
});

onUnmounted(() => {
  window.removeEventListener("resize", updateWindowWidth);
});

// Use bottom positioning on mobile, right on desktop
const popoverSide = computed(() => {
  return windowWidth.value < 768 ? "bottom" : "right";
});

// Mutation for creating a representative
const { mutateAsync: createRep, isLoading: isCreating } = useMutation({
  mutation: (data: CreateCompanyRepData) =>
    createCompanyRepresentative(props.companyId, data),
  onSuccess: () => {
    // Invalidate the representatives query to refresh the data
    queryCache.invalidateQueries({
      key: ["company-representatives", props.companyId],
    });
    isAddFormOpen.value = false;
  },
});

// Mutation for deleting a representative
const { mutateAsync: deleteRep, isLoading: isDeleting } = useMutation({
  mutation: (repId: string) =>
    deleteCompanyRepresentative(props.companyId, repId),
  onSuccess: () => {
    // Invalidate the representatives query to refresh the data
    queryCache.invalidateQueries({
      key: ["company-representatives", props.companyId],
    });
  },
});

// Mutation for updating representative order
const updateOrderMutation = useUpdateRepresentativeOrderMutation();

const handleCreateRepresentative = async (data: CreateCompanyRepData) => {
  try {
    // If we're in reorder mode, save the current order before exiting
    if (isReorderMode.value) {
      await updateRepresentativeOrder(representativeOrder.value);
    }

    await createRep(data);
    // Exit reorder mode when adding new representative
    isReorderMode.value = false;
  } catch (error) {
    console.error("Failed to create representative:", error);
  }
};

const handleContactUpdated = () => {
  // Invalidate the representatives query to refresh the data
  queryCache.invalidateQueries({
    key: ["company-representatives", props.companyId],
  });
};

const handleDeleteRepresentative = async (repId: string) => {
  try {
    await deleteRep(repId);

    // If we're in reorder mode, update the order after deletion
    if (isReorderMode.value) {
      // Remove the deleted representative from the order
      representativeOrder.value = representativeOrder.value.filter(
        (id) => id !== repId,
      );
      await updateRepresentativeOrder(representativeOrder.value);
    }
  } catch (error) {
    console.error("Failed to delete representative:", error);
  }
};

const closeAllPopovers = () => {
  isAddFormOpen.value = false;
};

// Function to update representative order on the backend
const updateRepresentativeOrder = async (orderIds: string[]) => {
  try {
    updateOrderMutation.companyId.value = props.companyId;
    updateOrderMutation.representativeIds.value = orderIds;
    await updateOrderMutation.mutate();
  } catch (error) {
    console.error("Failed to update representative order:", error);
  }
};

// Reorder functions
const toggleReorderMode = () => {
  if (isReorderMode.value) {
    // If we're exiting, make update order backend call
    updateRepresentativeOrder(representativeOrder.value);
  }

  isReorderMode.value = !isReorderMode.value;
};

// Drag to reorder (reorder mode only), using pointer events so the card
// itself follows the pointer and it also works on touch screens. The list
// reorders live while dragging; the new order is saved when leaving reorder mode.
const draggedId = ref<string | null>(null);
const dragOffset = ref(0);
const itemRefs = new Map<string, HTMLElement>();
let dragStartY = 0;
let dragStartTop = 0;

const setItemRef = (repId: string, el: unknown) => {
  if (el instanceof HTMLElement) itemRefs.set(repId, el);
  else itemRefs.delete(repId);
};

const onPointerDown = (event: PointerEvent, repId: string) => {
  if (!isReorderMode.value || event.button !== 0) return;
  // Keep the card's own buttons and links clickable
  if ((event.target as HTMLElement).closest("a, button")) return;
  const el = itemRefs.get(repId);
  if (!el) return;
  el.setPointerCapture(event.pointerId);
  draggedId.value = repId;
  dragStartY = event.clientY;
  dragStartTop = el.offsetTop;
  dragOffset.value = 0;
};

// Positions the dragged card under the pointer, clamped to the list
const updateDragOffset = (clientY: number) => {
  const el = draggedId.value ? itemRefs.get(draggedId.value) : undefined;
  if (!el) return 0;

  // offsetTop ignores the transform, so this keeps the card under the
  // pointer even after it has moved to a new slot in the list
  const pointerOffset = clientY - dragStartY - (el.offsetTop - dragStartTop);

  // Keep the card inside the list: no higher than the first slot and no
  // lower than the last one
  const items = [...itemRefs.values()];
  const listTop = Math.min(...items.map((item) => item.offsetTop));
  const listBottom = Math.max(
    ...items.map((item) => item.offsetTop + item.offsetHeight),
  );
  dragOffset.value = Math.min(
    Math.max(pointerOffset, listTop - el.offsetTop),
    listBottom - el.offsetHeight - el.offsetTop,
  );
  return pointerOffset;
};

const onPointerMove = async (event: PointerEvent) => {
  if (!draggedId.value) return;
  const el = itemRefs.get(draggedId.value);
  if (!el) return;

  const pointerOffset = updateDragOffset(event.clientY);

  const order = representativeOrder.value;
  const index = order.indexOf(draggedId.value);
  // Use where the pointer is pulling the card, not the clamped position:
  // at the edges the clamped card can never get past its neighbour's middle
  const center = el.offsetTop + pointerOffset + el.offsetHeight / 2;
  const middleOf = (id: string | undefined) => {
    const other = id ? itemRefs.get(id) : undefined;
    return other ? other.offsetTop + other.offsetHeight / 2 : undefined;
  };

  const nextMiddle = middleOf(order[index + 1]);
  const prevMiddle = middleOf(order[index - 1]);
  let target = index;
  if (nextMiddle !== undefined && center > nextMiddle) target = index + 1;
  else if (prevMiddle !== undefined && center < prevMiddle) target = index - 1;
  if (target === index) return;

  // Swap, then animate the card that was pushed aside from its old slot to
  // the new one (FLIP), so it slides instead of jumping
  const neighbour = itemRefs.get(order[target]);
  const neighbourTop = neighbour?.offsetTop ?? 0;

  const newOrder = [...order];
  newOrder.splice(index, 1);
  newOrder.splice(target, 0, draggedId.value);
  representativeOrder.value = newOrder;

  await nextTick();
  // Re-anchor the dragged card right away, before the browser paints
  updateDragOffset(event.clientY);

  if (neighbour) {
    neighbour.style.transition = "none";
    neighbour.style.transform = `translateY(${neighbourTop - neighbour.offsetTop}px)`;
    void neighbour.offsetHeight; // apply the starting position
    neighbour.style.transition = "";
    neighbour.style.transform = "";
  }
};

const onPointerUp = () => {
  draggedId.value = null;
  dragOffset.value = 0;
};
</script>
