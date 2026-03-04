import { computed } from "vue";
import { useAuthStore } from "@/stores/auth";

export function usePermissions() {
  const authStore = useAuthStore();

  /**
   * The user's role, or undefined if not authenticated.
   */
  const role = computed<string | undefined>(() => authStore.decoded?.role);

  const isAdmin = computed(() => role.value === "ADMIN");
  const isCoordinator = computed(() => role.value === "COORDINATOR");
  const isTeamLeader = computed(() => role.value === "TEAMLEADER");
  const isMember = computed(() => role.value === "MEMBER");

  // Composite permissions
  const isCoordinatorOrAdmin = computed(
    () => isCoordinator.value || isAdmin.value,
  );

  const isTeamLeaderOrHigher = computed(
    () => isTeamLeader.value || isCoordinatorOrAdmin.value,
  );

  return {
    role,
    isAdmin,
    isCoordinator,
    isTeamLeader,
    isMember,
    isCoordinatorOrAdmin,
    isTeamLeaderOrHigher,
  };
}
