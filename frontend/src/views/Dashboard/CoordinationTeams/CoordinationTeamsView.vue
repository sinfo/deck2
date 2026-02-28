<template>
  <div class="max-w-7xl mx-auto p-6">
    <div class="mb-8">
      <h1 class="text-3xl font-bold mb-2">Coordination Teams</h1>
      <p class="text-muted-foreground">
        Manage coordination teams and assign members to coordinators
      </p>
    </div>

    <!-- Create new team -->
    <Card class="mb-6">
      <CardHeader>
        <CardTitle>Create New Team</CardTitle>
      </CardHeader>
      <CardContent>
        <div class="flex flex-col sm:flex-row gap-3 items-end">
          <div class="flex-1 w-full">
            <label class="text-sm font-medium mb-1.5 block"
              >Select Coordinator</label
            >
            <MemberSelect
              v-model="newCoordinator"
              :event-id="selectedEventId"
              placeholder="Choose a coordinator..."
              role-filter="COORDINATOR"
            />
          </div>
          <Button
            class="w-full sm:w-auto"
            :disabled="creating || !newCoordinator"
            @click="createTeam"
          >
            <span v-if="creating">Creating...</span>
            <span v-else>Create Team</span>
          </Button>
        </div>
      </CardContent>
    </Card>

    <!-- Loading state -->
    <div v-if="isLoading" class="py-12 text-center">
      <div
        class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"
      ></div>
      <p class="mt-2 text-muted-foreground">Loading teams...</p>
    </div>

    <!-- Empty state -->
    <div
      v-else-if="teams.length === 0"
      class="py-12 text-center border-2 border-dashed rounded-lg"
    >
      <p class="text-muted-foreground text-lg">No coordination teams yet.</p>
      <p class="text-sm text-muted-foreground mt-1">
        Create your first team above to get started.
      </p>
    </div>

    <!-- Teams grid -->
    <div v-else class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <Card v-for="team in teams" :key="team.id" class="overflow-hidden">
        <CardHeader class="bg-gradient-to-r from-blue-50 to-indigo-50 border-b">
          <div class="flex items-start justify-between">
            <div class="flex items-center gap-3">
              <div
                class="w-12 h-12 rounded-full bg-white border-2 border-indigo-200 flex items-center justify-center"
              >
                <Image
                  v-if="team.coordinator && membersMap[team.coordinator.member]"
                  :src="membersMap[team.coordinator.member]?.img"
                  :alt="
                    membersMap[team.coordinator.member]?.name || 'Coordinator'
                  "
                  class="w-10 h-10 rounded-full object-cover"
                />
                <span v-else class="text-lg font-bold text-indigo-600">{{
                  team.name.charAt(0).toUpperCase()
                }}</span>
              </div>
              <div>
                <CardTitle class="text-xl">{{ team.name }}'s Team</CardTitle>
                <p
                  v-if="team.coordinator && membersMap[team.coordinator.member]"
                  class="text-sm text-muted-foreground"
                >
                  Coordinator:
                  {{ membersMap[team.coordinator.member]?.name }}
                </p>
              </div>
            </div>
            <div class="flex gap-2">
              <Button size="sm" variant="ghost" @click="openEdit(team)">
                Edit
              </Button>
              <Popover v-model:open="deleteConfirmOpen[team.id]">
                <PopoverTrigger as-child>
                  <Button
                    size="sm"
                    variant="ghost"
                    class="text-red-600 hover:text-red-700 hover:bg-red-50"
                  >
                    Delete
                  </Button>
                </PopoverTrigger>
                <PopoverContent class="w-80">
                  <ConfirmDelete
                    title="Delete coordination team"
                    message="Are you sure you want to delete this coordination team? This action cannot be undone."
                    :is-deleting="deleting[team.id]"
                    @cancel="deleteConfirmOpen[team.id] = false"
                    @confirm="deleteTeamConfirm(team)"
                  />
                </PopoverContent>
              </Popover>
            </div>
          </div>
        </CardHeader>

        <CardContent class="p-4">
          <!-- Members list -->
          <div class="mb-4">
            <h4 class="text-sm font-semibold text-muted-foreground mb-3">
              Team Members ({{ team.coordinatedMembers?.length || 0 }})
            </h4>
            <div
              v-if="team.coordinatedMembers?.length"
              class="space-y-2 max-h-64 overflow-y-auto"
            >
              <div
                v-for="memberId in team.coordinatedMembers"
                :key="memberId"
                class="flex items-center justify-between p-2 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div class="flex items-center gap-2 flex-1 min-w-0">
                  <Image
                    v-if="membersMap[memberId]"
                    :src="membersMap[memberId]?.img"
                    :alt="membersMap[memberId]?.name || 'Member'"
                    class="w-8 h-8 rounded-full object-cover border flex-shrink-0"
                  />
                  <span v-if="membersMap[memberId]" class="truncate text-sm">{{
                    membersMap[memberId]?.name
                  }}</span>
                  <span v-else class="text-sm text-muted-foreground truncate">{{
                    memberId
                  }}</span>
                </div>
                <Popover
                  v-model:open="removeConfirmOpen[team.id + '_' + memberId]"
                >
                  <PopoverTrigger as-child>
                    <Button
                      size="sm"
                      variant="ghost"
                      class="flex-shrink-0 text-red-600 hover:text-red-700 hover:bg-red-50"
                      :disabled="removing[team.id + '_' + memberId]"
                    >
                      {{
                        removing[team.id + "_" + memberId]
                          ? "Removing..."
                          : "Remove"
                      }}
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent class="w-80">
                    <ConfirmDelete
                      title="Remove member"
                      message="Remove this member from the coordination team?"
                      :is-deleting="removing[team.id + '_' + memberId]"
                      @cancel="
                        removeConfirmOpen[team.id + '_' + memberId] = false
                      "
                      @confirm="removeMemberConfirm(team, memberId)"
                    />
                  </PopoverContent>
                </Popover>
              </div>
            </div>
            <div
              v-else
              class="text-sm text-muted-foreground text-center py-4 border-2 border-dashed rounded-lg"
            >
              No members assigned yet
            </div>
          </div>

          <!-- Add member -->
          <div class="border-t pt-4">
            <h4 class="text-sm font-semibold text-muted-foreground mb-2">
              Add Member
            </h4>
            <div class="flex gap-2">
              <MemberSelect
                v-model="selectedTeamToAdd[team.id]"
                :event-id="selectedEventId"
                placeholder="Select a member..."
                class="flex-1"
              />
              <Button
                :disabled="adding[team.id] || !selectedTeamToAdd[team.id]"
                @click="addCoordinatedTeamFor(team)"
              >
                {{ adding[team.id] ? "Adding..." : "Add" }}
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>

    <!-- Edit modal -->
    <div
      v-if="editing"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
      @click.self="closeEdit"
    >
      <Card class="w-full max-w-md">
        <CardHeader>
          <CardTitle>Edit {{ editing.name }}'s Team</CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <div>
            <label class="text-sm font-medium mb-1.5 block">Team name</label>
            <Input v-model="editingName" placeholder="Enter team name" />
          </div>
          <div>
            <label class="text-sm font-medium mb-1.5 block">Coordinator</label>
            <MemberSelect
              v-model="editingCoordinator"
              :event-id="selectedEventId"
              placeholder="Select coordinator..."
              role-filter="COORDINATOR"
            />
          </div>
          <div class="flex gap-2 justify-end pt-4">
            <Button variant="outline" @click="closeEdit">Cancel</Button>
            <Button :disabled="saving || savingEdit" @click="saveEdit">
              {{ savingEdit ? "Saving..." : "Save Changes" }}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch } from "vue";
import { useEventStore } from "@/stores/event";
import { useQuery, useMutation, useQueryCache } from "@pinia/colada";
import type { CoordinationTeam } from "@/dto/coordinationTeams";
import {
  getAllCoordinationTeams,
  createCoordinationTeam,
  updateCoordinationTeamName,
  addCoordinatedTeam,
  setCoordinator,
  deleteCoordinationTeam,
  removeCoordinatedTeam,
} from "@/api/coordinationTeams";
import { getAllMembers, getMemberRole } from "@/api/members";

import Card from "@/components/ui/card/Card.vue";
import CardContent from "@/components/ui/card/CardContent.vue";
import CardHeader from "@/components/ui/card/CardHeader.vue";
import CardTitle from "@/components/ui/card/CardTitle.vue";
import Button from "@/components/ui/button/Button.vue";
import Input from "@/components/ui/input/Input.vue";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import ConfirmDelete from "@/components/ConfirmDelete.vue";
import Image from "@/components/Image.vue";
import MemberSelect from "@/components/members/MemberSelect.vue";
import { useToast } from "@/lib/toast";

const queryCache = useQueryCache();
const { toast } = useToast();
const eventStore = useEventStore();

const newCoordinator = ref<string | undefined>(undefined);
const editing = ref<CoordinationTeam | null>(null);
const editingName = ref("");
const editingCoordinator = ref<string | undefined>(undefined);
const editingOriginalCoordinator = ref<string | undefined>(undefined);
const savingEdit = ref(false);

const selectedEventId = ref<number | undefined>(
  eventStore.selectedEvent?.id ?? undefined,
);

watch(
  () => eventStore.selectedEvent,
  (newEvent) => {
    selectedEventId.value = newEvent?.id ?? undefined;
  },
  { immediate: true },
);

// Fetch all teams
const { data, isLoading } = useQuery({
  key: ["coordinationTeams"],
  query: () => getAllCoordinationTeams(),
});

const teams = computed(() => data.value?.data || []);

// Fetch all members once for the event
const { data: membersData } = useQuery({
  key: () => ["members", `${selectedEventId.value}`],
  query: () => getAllMembers({ event: selectedEventId.value }),
});

// Create a map of member ID -> member for quick lookups
const membersMap = computed(() => {
  if (!membersData.value?.data) return {};
  return membersData.value.data.reduce(
    (acc, member) => {
      acc[member.id] = member;
      return acc;
    },
    {} as Record<string, { id: string; name: string; img: string }>,
  );
});

// Mutations
const { mutate: createMutate, isLoading: creating } = useMutation({
  mutation: (variables: { coordinator: string }) =>
    createCoordinationTeam({ coordinator: variables.coordinator }),
  onSuccess: () => {
    queryCache.invalidateQueries({ key: ["coordinationTeams"] });
    newCoordinator.value = undefined;
    toast.success({
      title: "Team created",
      description: "Coordination team created successfully",
    });
  },
  onError: (error: Error | unknown) => {
    const errorMessage =
      error instanceof Error && "response" in error
        ? (error as { response?: { data?: { message?: string } } }).response
            ?.data?.message
        : "An error occurred";
    toast.error({
      title: "Failed to create team",
      description: errorMessage || "An error occurred",
    });
  },
});

const { mutate: updateMutate, isLoading: saving } = useMutation({
  mutation: (variables: { id: string; data: { name: string } }) =>
    updateCoordinationTeamName(variables.id, variables.data),
  onSuccess: () => {
    queryCache.invalidateQueries({ key: ["coordinationTeams"] });
    toast.success({
      title: "Team updated",
      description: "Team name updated successfully",
    });
  },
});

const createTeam = async () => {
  if (!newCoordinator.value) return;
  try {
    const roleRes = await getMemberRole(newCoordinator.value);
    if (roleRes.data?.role !== "COORDINATOR") {
      toast.error({
        title: "Invalid selection",
        description: "Selected member is not a coordinator",
      });
      return;
    }
  } catch {
    console.warn("Could not validate member role before creating team");
  }

  createMutate({ coordinator: newCoordinator.value });
};

const openEdit = (t: CoordinationTeam) => {
  editing.value = t;
  editingName.value = t.name;
  editingCoordinator.value = t.coordinator?.member;
  editingOriginalCoordinator.value = t.coordinator?.member;
};

const closeEdit = () => {
  editing.value = null;
  editingName.value = "";
  editingCoordinator.value = undefined;
  editingOriginalCoordinator.value = undefined;
};

// State management
const selectedTeamToAdd = reactive<Record<string, string | undefined>>({});
const adding = reactive<Record<string, boolean>>({});
const removing = reactive<Record<string, boolean>>({});
const deleting = reactive<Record<string, boolean>>({});
const removeConfirmOpen = reactive<Record<string, boolean>>({});
const deleteConfirmOpen = reactive<Record<string, boolean>>({});

const { mutate: addCoordinatedMutate } = useMutation({
  mutation: (vars: { id: string; memberId: string }) =>
    addCoordinatedTeam(vars.id, { member: vars.memberId }),
  onSuccess: () => {
    queryCache.invalidateQueries({ key: ["coordinationTeams"] });
    toast.success({
      title: "Member added",
      description: "Member added to team successfully",
    });
  },
});

const { mutate: setCoordinatorMutate } = useMutation({
  mutation: (vars: { id: string; memberId: string }) =>
    setCoordinator(vars.id, { member: vars.memberId }),
  onSuccess: () => {
    queryCache.invalidateQueries({ key: ["coordinationTeams"] });
    toast.success({
      title: "Coordinator updated",
      description: "Team coordinator updated successfully",
    });
  },
});

const addCoordinatedTeamFor = async (t: CoordinationTeam) => {
  const memberId = selectedTeamToAdd[t.id];
  if (!memberId) return;
  adding[t.id] = true;
  try {
    addCoordinatedMutate({ id: t.id, memberId });
    selectedTeamToAdd[t.id] = undefined;
  } finally {
    adding[t.id] = false;
  }
};

const saveEdit = async () => {
  if (!editing.value) return;
  savingEdit.value = true;
  try {
    if (editingName.value !== editing.value.name) {
      updateMutate({ id: editing.value.id, data: { name: editingName.value } });
    }

    if (
      editingCoordinator.value !== editingOriginalCoordinator.value &&
      editingCoordinator.value
    ) {
      try {
        const roleRes = await getMemberRole(editingCoordinator.value);
        if (roleRes.data?.role !== "COORDINATOR") {
          toast.error({
            title: "Invalid selection",
            description: "Selected member is not a coordinator",
          });
          savingEdit.value = false;
          return;
        }
      } catch {
        console.warn("Could not validate member role");
      }

      setCoordinatorMutate({
        id: editing.value.id,
        memberId: editingCoordinator.value,
      });
    }
  } finally {
    savingEdit.value = false;
    closeEdit();
  }
};

const { mutate: removeCoordinatedMutate } = useMutation({
  mutation: (vars: { id: string; memberId: string }) =>
    removeCoordinatedTeam(vars.id, vars.memberId),
  onSuccess: () => {
    queryCache.invalidateQueries({ key: ["coordinationTeams"] });
    toast.success({
      title: "Member removed",
      description: "Member removed from team successfully",
    });
  },
});

const removeMemberConfirm = async (t: CoordinationTeam, memberId: string) => {
  const key = `${t.id}_${memberId}`;
  try {
    removing[key] = true;
    removeCoordinatedMutate({ id: t.id, memberId });
  } finally {
    removing[key] = false;
    removeConfirmOpen[key] = false;
  }
};

const { mutate: deleteMutate } = useMutation({
  mutation: (id: string) => deleteCoordinationTeam(id),
  onSuccess: () => {
    queryCache.invalidateQueries({ key: ["coordinationTeams"] });
    toast.success({
      title: "Team deleted",
      description: "Coordination team deleted successfully",
    });
  },
});

const deleteTeamConfirm = async (t: CoordinationTeam) => {
  try {
    deleting[t.id] = true;
    deleteMutate(t.id);
  } finally {
    deleting[t.id] = false;
    deleteConfirmOpen[t.id] = false;
  }
};
</script>
