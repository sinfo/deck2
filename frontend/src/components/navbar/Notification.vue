<script setup lang="ts">
import { computed } from "vue";
import { useRouter } from "vue-router";
import { useQuery } from "@pinia/colada";
import { getMyNotifications } from "@/api/notifications";
import {
  useDeleteNotificationMutation,
  useDeleteAllNotificationsMutation,
} from "@/mutations/notifications";
import type { Notification } from "@/dto/notifications";
import type { Speaker } from "@/dto/speakers";
import type { Company } from "@/dto/companies";
import { Bell, Trash } from "lucide-vue-next";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import Badge from "../ui/badge/Badge.vue";
import Image from "../Image.vue";

const getActor = (notification: Notification) => {
  if (notification.speaker && typeof notification.speaker === "object") {
    const speaker = notification.speaker as Speaker;
    return {
      id: speaker.id,
      name: speaker.name,
      avatar: speaker.imgs.internal || speaker.imgs.speaker,
    };
  }
  if (notification.company && typeof notification.company === "object") {
    const company = notification.company as Company;
    return {
      id: company.id,
      name: company.name,
      avatar: company.imgs?.internal || company.imgs?.public,
    };
  }
  return null;
};

const makeMessage = (
  notification: Notification,
  actorArg?: { id?: string; name?: string; avatar?: string } | null,
) => {
  const thread = notification.thread;
  const kind = notification.kind;
  // Actor is the entity (company/speaker) related to the notification. Prefer the precomputed actor when provided.
  const actor = actorArg ?? getActor(notification);
  const actorName = actor && actor.name ? actor.name : "";
  const isActorPresent = actorName.length > 0;

  switch (kind) {
    case "UPDATED_PARTICIPATION":
      return "Participation updated";
    case "UPDATED_PARTICIPATION_STATUS":
      return "Participation status changed";
    case "CREATED_PARTICIPATION":
      return "New participation";
    case "DELETED_PARTICIPATION":
      return "Participation removed";
    case "UPLOADED_MEETING_MINUTE":
      return "Meeting minute uploaded";
    case "DELETED_MEETING_MINUTE":
      return "Meeting minute deleted";
    case "UPDATED_PRIVATE_IMAGE":
      return "Private image updated";
    case "CREATED_PARTICIPATION_PACKAGE":
      return "Participation package created";
    case "UPDATED_PARTICIPATION_PACKAGE":
      return "Participation package updated";
    case "DELETED_PARTICIPATION_PACKAGE":
      return "Participation package deleted";
    case "UPDATED":
      if (thread) {
        if (isActorPresent) {
          return "Communication updated";
        }
        return "Thread updated";
      }

      return "Updated details";
    case "CREATED":
      if (thread) {
        if (isActorPresent) {
          return "New communication created";
        }
        return "Thread created";
      }

      return "Created";
    case "DELETED":
      if (thread) {
        if (isActorPresent) {
          return "Communication deleted";
        }
        return "Thread deleted";
      } else if (notification.name) {
        return `${notification.name} was deleted`;
      }
      return "Deleted";
    case "TAGGED":
      return "You were tagged in a post";
    default:
      return kind;
  }
};

const { data: notifications } = useQuery({
  key: ["notifications"],
  query: getMyNotifications,
});

type NotificationEntry = {
  n: Notification;
  actor: { id?: string; name?: string; avatar?: string } | null;
};

const notificationItems = computed<NotificationEntry[]>(() => {
  const items = (notifications.value?.data as Notification[]) || [];
  // sort newest first — try common timestamp fields (date, createdAt, created_at)
  const sorted = items
    .slice()
    .sort((a, b) => b.date?.localeCompare(a.date ?? "") || 0);
  return sorted.map((n) => ({ n, actor: getActor(n) }));
});

const _deleteNotificationMutation = useDeleteNotificationMutation();
const _deleteAllNotificationsMutation = useDeleteAllNotificationsMutation();

const removeNotification = async (id: string) => {
  await _deleteNotificationMutation.mutate(id);
};

const removeAllNotifications = async () => {
  const ids = notificationItems.value.map((i) => i.n.id);
  if (!ids.length) return;
  await _deleteAllNotificationsMutation.mutate();
};

const router = useRouter();
const navigateNotification = (n: Notification) => {
  // ensure speaker is an object (not a string) before accessing .id
  if (n.speaker && typeof n.speaker === "object" && (n.speaker as Speaker).id) {
    router.push({
      name: "speaker",
      params: { speakerId: (n.speaker as Speaker).id },
    });
    return;
  }
  // ensure company is an object (not a string) before accessing .id
  if (n.company && typeof n.company === "object" && (n.company as Company).id) {
    router.push({
      name: "company",
      params: { companyId: (n.company as Company).id },
    });
    return;
  }
};

const onNotificationClick = async (n: Notification) => {
  if (!n || !n.id) return;
  try {
    await removeNotification(n.id);
  } catch {
    // ignore
  }
  navigateNotification(n);
};
</script>

<template>
  <Popover>
    <PopoverTrigger>
      <button
        class="p-2 rounded hover:bg-gray-100 relative"
        :title="'Notifications'"
      >
        <Bell class="h-5 w-5 text-gray-600" />
        <Badge
          v-if="notificationItems.length"
          variant="destructive"
          class="absolute -top-2 -right-1 text-xs"
        >
          {{ notificationItems.length }}
        </Badge>
      </button>
    </PopoverTrigger>

    <PopoverContent class="w-80 p-0">
      <div class="p-2 flex items-center justify-between border-b">
        <h4 class="font-semibold">Notifications</h4>
        <button
          v-if="notificationItems.length"
          class="text-sm text-blue-600"
          @click="removeAllNotifications()"
        >
          Read all
        </button>
      </div>

      <div class="max-h-60 overflow-auto">
        <div v-if="!notificationItems.length" class="p-4 text-sm text-gray-500">
          No notifications
        </div>

        <ul>
          <li
            v-for="entry in notificationItems"
            :key="entry.n.id"
            class="flex items-center justify-between px-3 py-2 hover:bg-gray-50 cursor-pointer"
            @click="onNotificationClick(entry.n)"
          >
            <div class="flex items-center gap-3">
              <Image
                v-if="entry.actor?.avatar"
                :src="entry.actor?.avatar"
                alt="actor"
                class="h-8 w-8 rounded-full object-cover"
              />
              <div class="text-sm">
                <div class="font-medium">
                  {{ makeMessage(entry.n, entry.actor) }}
                </div>
                <div class="text-xs text-gray-500">
                  {{ entry.actor?.name || entry.n.date }}
                </div>
              </div>
            </div>
            <div>
              <button
                class="text-red-500 text-sm"
                @click.stop.prevent="removeNotification(entry.n.id)"
              >
                <Trash :size="16" />
              </button>
            </div>
          </li>
        </ul>
      </div>
    </PopoverContent>
  </Popover>
</template>
