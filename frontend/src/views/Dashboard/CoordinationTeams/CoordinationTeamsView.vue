<template>
  <div class="max-w-7xl mx-auto p-4 sm:p-6">
    <div class="mb-6 sm:mb-8">
      <h1 class="text-2xl sm:text-3xl font-bold mb-2">Coordination Teams</h1>
      <p class="text-sm sm:text-base text-muted-foreground">
        Manage coordination teams and assign members to coordinators
      </p>
    </div>

    <!-- Create new team -->
    <Card
      class="mb-6 sm:mb-8 border-2 shadow-sm hover:shadow-md transition-shadow"
    >
      <CardHeader class="pb-3 sm:pb-4">
        <CardTitle class="text-lg sm:text-xl">Create New Team</CardTitle>
        <p class="text-xs sm:text-sm text-muted-foreground mt-1">
          Select a coordinator to create their team
        </p>
      </CardHeader>
      <CardContent>
        <div class="flex flex-col sm:flex-row gap-4 items-end">
          <div class="flex-1 w-full">
            <label class="text-sm font-semibold mb-2 block text-foreground"
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
            class="w-full sm:w-auto px-6 h-10"
            :disabled="creating || !newCoordinator"
            @click="createTeam"
          >
            <span v-if="creating" class="flex items-center gap-2">
              <div
                class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"
              ></div>
              Creating...
            </span>
            <span v-else>Create Team</span>
          </Button>
        </div>
      </CardContent>
    </Card>

    <!-- Loading state -->
    <div
      v-if="isLoading"
      class="flex flex-col items-center justify-center py-20"
    >
      <div
        class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-gray-200 border-t-primary"
      ></div>
      <p class="mt-4 text-muted-foreground font-medium">Loading teams...</p>
    </div>

    <!-- Empty state -->
    <div
      v-else-if="teams.length === 0"
      class="flex flex-col items-center justify-center py-20 px-4 border-2 border-dashed rounded-xl bg-muted/30"
    >
      <div
        class="w-16 h-16 rounded-full bg-muted flex items-center justify-center mb-4"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-8 w-8 text-muted-foreground"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
          />
        </svg>
      </div>
      <p class="text-muted-foreground text-lg font-medium">
        No coordination teams yet
      </p>
      <p class="text-sm text-muted-foreground mt-2">
        Create your first team above to get started
      </p>
    </div>

    <!-- Teams grid -->
    <div v-else class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <Card
        v-for="team in teams"
        :key="team.id"
        class="overflow-hidden hover:shadow-lg transition-shadow border-2"
      >
        <CardHeader
          class="bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 border-b-2 pb-4"
        >
          <div class="flex items-start justify-between gap-2 sm:gap-4">
            <div class="flex items-center gap-3 sm:gap-4 flex-1 min-w-0">
              <div
                class="w-12 h-12 sm:w-14 sm:h-14 rounded-full bg-white shadow-md flex items-center justify-center flex-shrink-0 ring-2 ring-indigo-100"
              >
                <Image
                  v-if="team.coordinator && membersMap[team.coordinator.member]"
                  :src="membersMap[team.coordinator.member]?.img"
                  :alt="
                    membersMap[team.coordinator.member]?.name || 'Coordinator'
                  "
                  class="w-10 h-10 sm:w-12 sm:h-12 rounded-full object-cover"
                />
                <span
                  v-else
                  class="text-xl sm:text-2xl font-bold text-indigo-600 select-none"
                  >{{ team.name.charAt(0).toUpperCase() }}</span
                >
              </div>
              <div class="min-w-0 flex-1">
                <CardTitle class="text-lg sm:text-xl font-bold truncate"
                  >{{ team.name }}'s Team</CardTitle
                >
                <p
                  v-if="team.coordinator && membersMap[team.coordinator.member]"
                  class="text-xs sm:text-sm text-muted-foreground font-medium truncate mt-1"
                >
                  {{ membersMap[team.coordinator.member]?.name }}
                </p>
                <p
                  v-else
                  class="text-xs sm:text-sm text-muted-foreground italic mt-1"
                >
                  No coordinator
                </p>
              </div>
            </div>
            <div class="flex gap-1 flex-shrink-0">
              <Button
                size="sm"
                variant="ghost"
                class="hover:bg-white/80 hidden sm:flex"
                @click="openEdit(team)"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
                <span class="ml-1.5">Edit</span>
              </Button>
              <Button
                size="sm"
                variant="ghost"
                class="hover:bg-white/80 sm:hidden p-2"
                @click="openEdit(team)"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
              </Button>
              <Popover v-model:open="deleteConfirmOpen[team.id]">
                <PopoverTrigger as-child>
                  <Button
                    size="sm"
                    variant="ghost"
                    class="text-red-600 hover:text-red-700 hover:bg-red-50 p-2"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4 w-4"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                      />
                    </svg>
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

        <CardContent class="p-4 sm:p-6">
          <!-- Members list -->
          <div class="mb-5">
            <div class="flex items-center justify-between mb-4">
              <h4
                class="text-sm font-bold text-foreground flex items-center gap-2"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                  />
                </svg>
                Team Members
              </h4>
              <span
                class="px-3 py-1 bg-indigo-100 text-indigo-700 text-xs font-bold rounded-full"
                >{{ team.coordinatedMembers?.length || 0 }}</span
              >
            </div>
            <div
              v-if="team.coordinatedMembers?.length"
              class="space-y-2 max-h-72 overflow-y-auto pr-2 custom-scrollbar"
            >
              <div
                v-for="memberId in team.coordinatedMembers"
                :key="memberId"
                class="flex items-center justify-between p-2 sm:p-3 rounded-lg hover:bg-gradient-to-r hover:from-blue-50 hover:to-indigo-50 transition-all border border-transparent hover:border-indigo-100 group"
              >
                <div class="flex items-center gap-2 sm:gap-3 flex-1 min-w-0">
                  <Image
                    v-if="membersMap[memberId]"
                    :src="membersMap[memberId]?.img"
                    :alt="membersMap[memberId]?.name || 'Member'"
                    class="w-8 h-8 sm:w-10 sm:h-10 rounded-full object-cover border-2 border-gray-200 group-hover:border-indigo-300 transition-colors flex-shrink-0"
                  />
                  <span
                    v-if="membersMap[memberId]"
                    class="truncate text-sm sm:text-base font-medium text-foreground"
                    >{{ membersMap[memberId]?.name }}</span
                  >
                  <span
                    v-else
                    class="text-sm text-muted-foreground italic truncate"
                    >{{ memberId }}</span
                  >
                </div>
                <Popover
                  v-model:open="removeConfirmOpen[team.id + '_' + memberId]"
                >
                  <PopoverTrigger as-child>
                    <Button
                      size="sm"
                      variant="ghost"
                      class="flex-shrink-0 text-red-600 hover:text-red-700 hover:bg-red-50 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity"
                      :disabled="removing[team.id + '_' + memberId]"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M6 18L18 6M6 6l12 12"
                        />
                      </svg>
                      <span class="ml-1 hidden sm:inline">{{
                        removing[team.id + "_" + memberId]
                          ? "Removing..."
                          : "Remove"
                      }}</span>
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
              class="flex flex-col items-center justify-center py-8 px-4 border-2 border-dashed rounded-lg bg-blue-50/30"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-10 w-10 text-indigo-300 mb-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                />
              </svg>
              <p class="text-sm text-muted-foreground font-medium">
                No members assigned yet
              </p>
              <p class="text-xs text-muted-foreground mt-1">
                Add members below
              </p>
            </div>
          </div>

          <!-- Add member -->
          <div class="border-t-2 pt-4 sm:pt-5 mt-4 sm:mt-5">
            <h4
              class="text-sm font-bold text-foreground mb-3 flex items-center gap-2"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                />
              </svg>
              Add Member
            </h4>
            <div class="flex flex-col sm:flex-row gap-3">
              <MemberSelect
                v-model="selectedTeamToAdd[team.id]"
                :event-id="selectedEventId"
                placeholder="Select a member..."
                class="flex-1"
              />
              <Button
                class="px-6 w-full sm:w-auto"
                :disabled="adding[team.id] || !selectedTeamToAdd[team.id]"
                @click="addCoordinatedTeamFor(team)"
              >
                <span v-if="adding[team.id]" class="flex items-center gap-2">
                  <div
                    class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"
                  ></div>
                  Adding...
                </span>
                <span v-else class="flex items-center gap-1.5">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                    />
                  </svg>
                  Add
                </span>
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>

    <!-- Edit modal -->
    <div
      v-if="editing"
      class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-in fade-in duration-200"
      @click.self="closeEdit"
    >
      <Card
        class="w-full max-w-md shadow-2xl animate-in zoom-in-95 duration-200"
      >
        <CardHeader class="border-b bg-gradient-to-r from-blue-50 to-indigo-50">
          <CardTitle class="text-2xl">Edit Team</CardTitle>
          <p class="text-sm text-muted-foreground mt-1">
            Update {{ editing.name }}'s team information
          </p>
        </CardHeader>
        <CardContent class="space-y-5 pt-6">
          <div>
            <label class="text-sm font-semibold mb-2 block text-foreground"
              >Team Name</label
            >
            <Input
              v-model="editingName"
              placeholder="Enter team name"
              class="h-11"
            />
          </div>
          <div>
            <label class="text-sm font-semibold mb-2 block text-foreground"
              >Coordinator</label
            >
            <MemberSelect
              v-model="editingCoordinator"
              :event-id="selectedEventId"
              placeholder="Select coordinator..."
              role-filter="COORDINATOR"
            />
          </div>
          <div class="flex gap-3 justify-end pt-4 border-t">
            <Button variant="outline" class="px-6" @click="closeEdit"
              >Cancel</Button
            >
            <Button
              class="px-6"
              :disabled="saving || savingEdit"
              @click="saveEdit"
            >
              <span v-if="savingEdit" class="flex items-center gap-2">
                <div
                  class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"
                ></div>
                Saving...
              </span>
              <span v-else>Save Changes</span>
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

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 8px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 10px;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 10px;
}

.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

.animate-in {
  animation-duration: 200ms;
  animation-fill-mode: both;
}

.fade-in {
  animation-name: fadeIn;
}

.zoom-in-95 {
  animation-name: zoomIn95;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes zoomIn95 {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}
</style>
