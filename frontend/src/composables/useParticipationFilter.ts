import { computed } from "vue";
import type { Ref } from "vue";
import type { ObjectID, ParticipationStatus } from "@/dto";

// Generic composable to filter a Map<string, T[]> by participation.status and optionally by package
export function useParticipationFilter<
  T extends {
    participation?: { status?: ParticipationStatus; package?: ObjectID };
  },
>(
  participations: Ref<Map<string, T[]> | undefined>,
  selectedStatus: Ref<ParticipationStatus | null>,
  selectedPackage?: Ref<ObjectID | null>,
) {
  return computed(() => {
    if (!participations.value) return new Map<string, T[]>();

    const hasStatusFilter = !!selectedStatus.value;
    const hasPackageFilter = !!selectedPackage?.value;

    if (!hasStatusFilter && !hasPackageFilter) return participations.value;

    const map = new Map<string, T[]>();
    for (const [memberId, items] of participations.value.entries()) {
      const filtered = items.filter((it) => {
        const matchesStatus =
          !hasStatusFilter || it.participation?.status === selectedStatus.value;
        const matchesPackage =
          !hasPackageFilter ||
          it.participation?.package === selectedPackage?.value;
        return matchesStatus && matchesPackage;
      });
      if (filtered.length) map.set(memberId, filtered);
    }

    return map;
  });
}
