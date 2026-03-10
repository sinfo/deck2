<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h2 class="text-2xl font-semibold">Packages for {{ eventName }}</h2>
        <p class="text-sm text-muted-foreground">
          Create, edit or remove packages for this event.
        </p>
      </div>
    </div>

    <div class="mb-4">
      <router-link
        :to="{ name: 'packages-items' }"
        class="inline-flex items-center gap-2 px-3 py-2 rounded bg-primary text-white hover:opacity-90"
      >
        Manage items
      </router-link>
    </div>

    <div v-if="!eventName" class="text-muted-foreground">
      Select an event to manage packages.
    </div>

    <div v-else class="space-y-6">
      <Card>
        <CardContent>
          <h3 class="font-medium mb-3">Create package</h3>
          <PackageForm :event-name="eventName" @saved="onCreated" />
        </CardContent>
      </Card>

      <div>
        <h3 class="font-medium mb-3">Existing packages</h3>
        <div v-if="isLoading" class="text-muted-foreground">Loading...</div>
        <div v-else>
          <div
            v-if="packages.length === 0"
            class="text-sm text-muted-foreground"
          >
            No packages for this event yet.
          </div>
          <div class="grid gap-4">
            <PackageCard
              v-for="pkg in packages"
              :key="pkg.id"
              :pkg="pkg"
              :event-name="eventName"
              @updated="refetchPackages"
              @deleted="refetchPackages"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useEventStore } from "@/stores/event";
import { useEventPackagesQuery } from "@/mutations/packages";
import Card from "@/components/ui/card/Card.vue";
import CardContent from "@/components/ui/card/CardContent.vue";
import PackageForm from "@/components/packages/PackageForm.vue";
import PackageCard from "@/components/packages/PackageCard.vue";

const eventStore = useEventStore();
const eventName = computed(() => eventStore.selectedEvent?.name || "");

const { data: packages, refetch, isLoading } = useEventPackagesQuery();

const refetchPackages = async () => {
  await refetch();
};

const onCreated = () => refetchPackages();
</script>
