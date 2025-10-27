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
            >Reorder mode active. Use the arrow buttons to rearrange
            contacts.</span
          >
        </div>
      </div>

      <EmptyStateCard
        v-if="!representatives.length"
        class="text-center text-muted-foreground py-8"
        title="Click here to add representatives"
        @click="isAddFormOpen = true"
      />

      <div v-else class="space-y-4">
        <div
          v-for="(rep, index) in orderedRepresentatives"
          :key="rep.id"
          class="relative"
        >
          <!-- Reorder buttons -->
          <div
            v-if="isReorderMode"
            class="absolute -left-8 md:-left-16 top-1/2 -translate-y-1/2 flex flex-col gap-1 z-10"
          >
            <Button
              variant="outline"
              size="sm"
              :disabled="index === 0"
              class="h-8 w-8 p-0 shadow-sm"
              title="Move up"
              @click="moveUp(index)"
            >
              <ChevronUpIcon class="w-4 h-4" />
            </Button>
            <Button
              variant="outline"
              size="sm"
              :disabled="index === orderedRepresentatives.length - 1"
              class="h-8 w-8 p-0 shadow-sm"
              title="Move down"
              @click="moveDown(index)"
            >
              <ChevronDownIcon class="w-4 h-4" />
            </Button>
          </div>

          <div class="relative group">
            <!-- Primary contact indicator -->
            <div
              v-if="index === 0"
              class="absolute -top-2 -right-2 z-20 opacity-0 group-hover:opacity-100 transition-opacity duration-200"
            >
              <div
                class="bg-primary text-primary-foreground text-xs px-2 py-1 rounded-full shadow-lg flex items-center gap-1"
              >
                <CrownIcon class="w-3 h-3" />
                Primary Contact
              </div>
            </div>

            <!-- Always visible crown for first contact -->
            <div
              v-if="index === 0"
              class="absolute -top-1 -right-1 z-10 bg-orange-100 text-orange-600 rounded-full p-1 shadow-sm border border-orange-200"
              title="Primary Contact"
            >
              <CrownIcon class="w-3 h-3" />
            </div>

            <ContactCard
              :contact="rep.contact"
              :contact-name="rep.name"
              can-edit
              can-delete
              :entity-id="companyId"
              entity-type="company"
              :is-deleting="isDeleting"
              :class="{
                'ml-2 md:ml-4': isReorderMode,
                'transition-all duration-300': true,
                'ring-2 ring-blue-200': isReorderMode,
                'ring-1 ring-orange-200 shadow-sm':
                  index === 0 && !isReorderMode,
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
import { ref, computed, onMounted, onUnmounted, watch } from "vue";
import { useMutation, useQueryCache } from "@pinia/colada";
import type { CompanyRep, CreateCompanyRepData } from "@/dto/companies";
import {
  createCompanyRepresentative,
  deleteCompanyRepresentative,
} from "@/api/companies";
import { useUpdateRepresentativeOrderMutation } from "@/mutations/companies";
import {
  GripVerticalIcon,
  ChevronUpIcon,
  ChevronDownIcon,
  CrownIcon,
} from "lucide-vue-next";
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

const moveUp = (index: number) => {
  if (index > 0) {
    const newOrder = [...representativeOrder.value];
    [newOrder[index - 1], newOrder[index]] = [
      newOrder[index],
      newOrder[index - 1],
    ];
    representativeOrder.value = newOrder;
  }
};

const moveDown = (index: number) => {
  if (index < representativeOrder.value.length - 1) {
    const newOrder = [...representativeOrder.value];
    [newOrder[index], newOrder[index + 1]] = [
      newOrder[index + 1],
      newOrder[index],
    ];
    representativeOrder.value = newOrder;
  }
};
</script>
